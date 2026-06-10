# Microsoft Foundry — Secure Baseline behind Azure API Management (Terraform)

A reference Azure architecture, expressed as Terraform, that deploys **Microsoft Foundry
secured with Private Endpoints** and **exposed / scaled out through an Azure API Management
tier**. It is modeled on two Azure-Samples references:

- [`microsoft-foundry-baseline`](https://github.com/Azure-Samples/microsoft-foundry-baseline) — network isolation, bring-your-own Foundry Agent Service dependencies (Storage, AI Search, Cosmos DB), delegated agent egress subnet, and Azure Firewall egress control.
- [`azure-openai-apim-load-balancing`](https://github.com/Azure-Samples/azure-openai-apim-load-balancing) — round-robin load balancing across inference backends in API Management using a policy and the gateway's managed identity.

> This is a **reference / illustrative** deployment. Some Microsoft Foundry resources use the
> `azapi` provider against preview API versions; review and pin API versions before using in
> production. SKUs default to cost-conscious tiers (e.g. APIM `Developer_1`) — move to zonal,
> production SKUs (APIM `Premium`) for real workloads.

## Architecture layers

| Layer | Resources | Module |
|-------|-----------|--------|
| **Network** | VNet `192.168.0.0/16`, subnets (Container Apps, APIM, agent egress, private endpoints, data, Bastion, jumpbox, build agents, Azure Firewall), NSGs, egress route table, Azure Firewall + policy, Private DNS zones | `modules/network` |
| **Exposure** | API Management (Internal VNet), round-robin load-balancing policy, managed-identity auth to Foundry, App Insights logger | `modules/apim` |
| **Application** | Azure Container Apps environment (VNet injected, internal LB) + chat container app with system-assigned identity | `modules/application` |
| **AI** | Microsoft Foundry account + project, Foundry Agent Service network injection, GPT model deployment, Azure AI Search, BYO connections + capability host | `modules/ai` |
| **Management** | Log Analytics, Application Insights, Key Vault (private endpoint, RBAC) | `modules/management` |
| **Storage & Data** | Azure Storage (blob) and Cosmos DB — the Foundry Agent Service BYO dependencies, both private-endpoint only | `modules/data` |

See [`diagrams/architecture.mmd`](./diagrams/architecture.mmd) for the Mermaid diagram.

## How the pieces connect

1. A user calls the **API Management** gateway (Internal VNet).
2. APIM authenticates to **Microsoft Foundry** with its **managed identity** (`Cognitive Services OpenAI User`) and **round-robin** load balances across backend instances, retrying on `429`/`5xx`.
3. The **Container Apps** chat tier calls inference through the APIM gateway and emits telemetry to **Application Insights**.
4. **Foundry** reaches all of its dependencies privately: **AI Search** (grounding/vectors), **Storage** (files), and **Cosmos DB** (agent thread / chat memory) — each via a **Private Endpoint** resolved through **Private DNS zones**.
5. **Foundry Agent Service** egress is bound to the delegated `snet-agentsEgress` subnet and forced through **Azure Firewall** for FQDN filtering.
6. Public network access is **disabled** on Foundry, Search, Storage, Cosmos, and Key Vault.

## Subnet plan (`192.168.0.0/16`)

| Subnet | Prefix | Purpose |
|--------|--------|---------|
| `snet-containerapps` | `192.168.0.0/23` | Container Apps env (delegated `Microsoft.App/environments`) |
| `snet-apim` | `192.168.2.0/24` | API Management (Internal) |
| `snet-agentsEgress` | `192.168.3.0/24` | Foundry agent egress (delegated `Microsoft.App/environments`) |
| `snet-privateEndpoints` | `192.168.4.0/24` | All private endpoints (deny-all egress NSG) |
| `snet-data` | `192.168.5.0/24` | Database tier expansion |
| `AzureFirewallSubnet` | `192.168.6.0/26` | Azure Firewall |
| `AzureBastionSubnet` | `192.168.6.128/26` | Bastion |
| `snet-jumpbox` | `192.168.6.192/27` | Management jump box |
| `snet-buildAgents` | `192.168.6.224/27` | CI/CD build agents |

> `192.168.0.0/16` is used because the Foundry Agent Service delegated subnet historically
> rejected the `10.0.0.0/8` range.

## Usage

```bash
cd ai-architecture
cp terraform.tfvars.example terraform.tfvars   # edit values
terraform init
terraform plan
terraform apply
```

### One-command app deploy (build/push/apply)

For the chat app under `app/`, you can run a staged deployment that:
1. Creates prerequisite infra (including ACR),
2. Builds and pushes the app image,
3. Applies the full Terraform stack.

```powershell
cd ai-architecture
./deploy-app.ps1 -ImageName foundry-chat -ImageTag latest
```

Optional flags:
- `-SubscriptionId <subscription-guid-or-name>`
- `-AutoApprove`

Example:

```powershell
./deploy-app.ps1 -ImageName foundry-chat -ImageTag v1 -AutoApprove
```

### Requirements

- Terraform >= 1.6
- Providers: `hashicorp/azurerm` ~> 4.20, `Azure/azapi` ~> 2.2, `hashicorp/random`
- An authenticated Azure context (`az login`) with rights to create the resources and role assignments.

### Key variables

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | `eastus2` | Region (must support Foundry Agent Service + Container Apps) |
| `workload_name` | `foundryref` | 3–12 lowercase alphanumeric name seed |
| `environment` | `prod` | Environment short name |
| `vnet_address_space` | `192.168.0.0/16` | Workload VNet CIDR |
| `gpt_model` | `gpt-4o` / `GlobalStandard` / 50 | Model deployed to Foundry and exposed via APIM |
| `publisher_name` / `publisher_email` | Contoso placeholders | APIM publisher details |

## Outputs

`resource_group_name`, `vnet_id`, `apim_gateway_url`, `foundry_account_name`,
`foundry_project_endpoint`, `container_app_fqdn`, `key_vault_uri`.

## Notes & production hardening

- **APIM SKU**: `Developer_1` has no SLA. Use `Premium` with availability zones for production.
- **Azure Firewall** (`Standard`) and **DDoS** add cost; firewall is included to demonstrate the agent egress story.
- **Foundry `azapi` resources** (`accounts`, `projects`, `connections`, `capabilityHosts`) target `2025-06-01`; schema validation is disabled on the capability host because it is a preview shape. Verify against the latest API version.
- Add **Application Gateway + WAF** in front of APIM/Container Apps for internet-facing exposure.
- The container image is pulled from ACR and defaults to `foundry-chat:latest` (override with `app_image_name` / `app_image_tag`).

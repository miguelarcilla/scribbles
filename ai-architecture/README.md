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
2. APIM **imports the Azure OpenAI API** from **Foundry** and exposes defined operations (chat completions, embeddings, model listing).
3. APIM authenticates to **Microsoft Foundry** with its **managed identity** (`Cognitive Services OpenAI User`) and **round-robin** load balances across backend instances, retrying on `429`/`5xx`.
4. The **Container Apps** chat tier calls inference through the APIM gateway and emits telemetry to **Application Insights**.
5. **Foundry** reaches all of its dependencies privately: **AI Search** (grounding/vectors), **Storage** (files), and **Cosmos DB** (agent thread / chat memory) — each via a **Private Endpoint** resolved through **Private DNS zones**.
6. **Foundry Agent Service** egress is bound to the delegated `snet-agentsEgress` subnet and forced through **Azure Firewall** for FQDN filtering.
7. Public network access is **disabled** on Foundry, Search, Storage, Cosmos, and Key Vault.

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

## Requirements

**Local tools:**
- **PowerShell** 5.0+ (Windows) or **PowerShell Core** 7.0+ (cross-platform)
- **Terraform** >= 1.6
- **Docker** (for building container images; required for `deploy-app.ps1`)
- **Python** 3.11+ (for running or developing the chat app locally)
- **Azure CLI** (`az` command, with login: `az login`)

**Terraform providers:**
- `hashicorp/azurerm` ~> 4.20
- `Azure/azapi` ~> 2.2
- `hashicorp/random`

**Azure permissions:**
- Authenticated Azure context with rights to create resources and role assignments (Foundry, ACR, Container Apps, Key Vault, RBAC).

## Usage

### Quick start: One-command deployment

**Recommended:** Use the `deploy-app.ps1` script for a full build-and-deploy in one step:

```powershell
cd ai-architecture
./deploy-app.ps1 -ImageName foundry-chat -ImageTag latest -AutoApprove
```

This script:
1. Creates prerequisite infrastructure (including Azure Container Registry)
2. Builds and pushes the chat app Docker image
3. Applies the full Terraform stack

**Optional flags:**
- `-SubscriptionId <guid-or-name>` — target a specific subscription
- `-AutoApprove` — skip Terraform confirmation prompts

**Example with all options:**
```powershell
./deploy-app.ps1 -ImageName foundry-chat -ImageTag v1 -SubscriptionId mysubscription -AutoApprove
```

### Manual step-by-step deployment

If you prefer fine-grained control:

```powershell
cd ai-architecture
cp terraform.tfvars.example terraform.tfvars   # edit values
terraform init
terraform plan
terraform apply
```

Then build and push the app image separately using Docker and Azure Container Registry commands.

### Configuring the chat app

**Direct Foundry vs. API Management:**
The deployed chat app can route through API Management or directly to Foundry. After deployment, set these environment variables on the Container App:

- **Option 1: Direct Foundry** (default)
  - `AZURE_OPENAI_ENDPOINT` — your Foundry instance endpoint
  - `AZURE_OPENAI_DEPLOYMENT` — model deployment name
  - `AZURE_OPENAI_API_VERSION` — API version

- **Option 2: Via API Management** (recommended for production)
  - `AZURE_APIM_ENDPOINT` — APIM gateway URL (e.g., `https://apim-instance.azure-api.net/foundry`)
  - `AZURE_APIM_SUBSCRIPTION_KEY` — subscription key (or leave empty to use Container App managed identity)
  - `AZURE_OPENAI_DEPLOYMENT` — model deployment name
  - `AZURE_OPENAI_API_VERSION` — API version

**Managed identity setup:**
- The Container App's managed identity is automatically granted the `Cognitive Services OpenAI User` role on both **Foundry** and **API Management** during infrastructure deployment
- To use managed identity with APIM, leave `AZURE_APIM_SUBSCRIPTION_KEY` empty and the app will use `DefaultAzureCredential` with the management token scope
- For APIM + subscription key, store the key securely in Key Vault and inject it into the Container App environment

See [app/README.md](./app/README.md) for technical details.

### Key variables

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | `eastus2` | Region (must support Foundry Agent Service + Container Apps) |
| `workload_name` | `foundryref` | 3–12 lowercase alphanumeric name seed |
| `environment` | `prod` | Environment short name |
| `vnet_address_space` | `192.168.0.0/16` | Workload VNet CIDR |
| `gpt_model` | `gpt-4o` / `GlobalStandard` / 50 | Model deployed to Foundry and exposed via APIM |
| `publisher_name` / `publisher_email` | Contoso placeholders | APIM publisher details |

## Azure OpenAI API Operations

APIM imports and exposes the following Azure OpenAI operations from Foundry:

| Operation | Method | Endpoint | Description |
|-----------|--------|----------|-------------|
| **Create Chat Completion** | POST | `/openai/deployments/{deployment-id}/chat/completions` | Generate chat responses from a model deployment |
| **Create Embeddings** | POST | `/openai/deployments/{deployment-id}/embeddings` | Generate embedding vectors for text |
| **List Models** | GET | `/openai/models` | Retrieve available models and details |

**Example: Call chat completions through APIM**
```bash
curl -X POST \
  "${APIM_GATEWAY_URL}/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview" \
  -H "Ocp-Apim-Subscription-Key: ${APIM_SUBSCRIPTION_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

**APIM Gateway URL:** Available in Terraform outputs as `apim_gateway_url` and `azure_openai_api_endpoint`.

**Authentication:**
- **Subscription Key** (for testing): Include `Ocp-Apim-Subscription-Key` header
- **Managed Identity** (production): Use `DefaultAzureCredential` with management token scope (`https://management.azure.com/.default`)

All requests are load-balanced across Foundry backends with automatic retry on throttle (429) or server errors (5xx).

## Outputs

Root-level Terraform outputs include:
- `resource_group_name` — Resource group name
- `vnet_id` — Virtual network ID
- `apim_gateway_url` — APIM gateway base URL
- `azure_openai_api_endpoint` — Full Azure OpenAI API base path through APIM
- `azure_openai_chat_completions_endpoint` — Chat completions endpoint URL
- `foundry_account_name` — Foundry account name
- `foundry_project_endpoint` — Foundry project endpoint
- `container_app_fqdn` — Chat application ingress FQDN
- `container_registry_login_server` — ACR server for image pulls

## Notes & production hardening

- **APIM SKU**: `Developer_1` has no SLA. Use `Premium` with availability zones for production.
- **Azure Firewall** (`Standard`) and **DDoS** add cost; firewall is included to demonstrate the agent egress story.
- **Foundry `azapi` resources** (`accounts`, `projects`, `connections`, `capabilityHosts`) target `2025-06-01`; schema validation is disabled on the capability host because it is a preview shape. Verify against the latest API version.
- Add **Application Gateway + WAF** in front of APIM/Container Apps for internet-facing exposure.
- The container image is pulled from ACR and defaults to `foundry-chat:latest` (override with `app_image_name` / `app_image_tag`).

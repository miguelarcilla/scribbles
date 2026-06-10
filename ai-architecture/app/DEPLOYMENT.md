# Deploying Chat Vision App to Azure Container Apps via Terraform

This guide explains how to deploy the chat vision application to your Azure Container Apps infrastructure using the existing Terraform configuration.

## Prerequisites

- Azure subscription with appropriate permissions
- Terraform configured with Azure provider
- Azure CLI authenticated: `az login`
- Docker Desktop for local testing
- Python 3.10+ (for local development)

## Quick Start Deployment

### 1. Build the Container Image

From the app directory:

```bash
cd ai-architecture/app
docker build -t chat-vision:latest .
```

### 2. Push to Azure Container Registry

```bash
# Login to ACR (configured in your Terraform)
az acr login --name <your-acr-name>

# Tag the image
docker tag chat-vision:latest <your-acr-name>.azurecr.io/chat-vision:latest

# Push to registry
docker push <your-acr-name>.azurecr.io/chat-vision:latest
```

### 3. Update Terraform Configuration

In your `modules/application/main.tf` (or similar), ensure the Container App is configured with:

```hcl
variable "container_image" {
  description = "Container image URI"
  default     = "<your-acr-name>.azurecr.io/chat-vision:latest"
}

variable "container_port" {
  description = "Container port (must be 50505 for chat vision app)"
  default     = 50505
}
```

### 4. Configure Environment Variables

Update your Terraform variables to include OpenAI configuration:

```hcl
variable "azure_openai_endpoint" {
  description = "Azure OpenAI service endpoint"
  type        = string
}

variable "azure_openai_model" {
  description = "OpenAI model name (e.g., gpt-4o)"
  type        = string
  default     = "gpt-4o"
}

variable "azure_tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}
```

### 5. Update Container App Configuration

In your Container App module, set environment variables:

```hcl
env = [
  {
    name  = "OPENAI_HOST"
    value = "azure"
  },
  {
    name  = "AZURE_OPENAI_ENDPOINT"
    value = var.azure_openai_endpoint
  },
  {
    name  = "OPENAI_MODEL"
    value = var.azure_openai_model
  },
  {
    name  = "AZURE_TENANT_ID"
    value = var.azure_tenant_id
  },
  {
    name  = "RUNNING_IN_PRODUCTION"
    value = "1"
  }
]
```

### 6. Deploy with Terraform

```bash
cd ai-architecture

# Initialize Terraform (if not done)
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the configuration
terraform apply tfplan
```

## Architecture Integration

### Network Module Integration

The application will use:
- **ContainerAppsSubnet**: For application workload (delegated to Azure Container Apps)
- **PrivateEndpointsSubnet**: For secure Azure OpenAI connection
- **Azure Firewall**: For egress traffic control
- **Private DNS Zones**: For service name resolution

### Managed Identity Configuration

The Container App should have a managed identity with:
- **Role**: `Cognitive Services OpenAI User`
- **Scope**: The Azure OpenAI resource

Example Terraform:

```hcl
resource "azurerm_role_assignment" "container_app_openai_user" {
  scope              = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id       = azurerm_user_assigned_identity.container_app.principal_id
}
```

### Port Configuration

⚠️ **Important**: The application runs on port **50505**. Ensure your Container App ingress is configured for this port:

```hcl
ingress {
  external_enabled = true
  target_port      = 50505
  transport        = "auto"
  
  traffic_weight {
    latest_revision = true
    percentage      = 100
  }
}
```

## Monitoring and Diagnostics

### View Application Logs

```bash
az containerapp logs show \
  --name <container-app-name> \
  --resource-group <resource-group-name>
```

### Check Application Health

```bash
# Get the FQDN
az containerapp show \
  --name <container-app-name> \
  --resource-group <resource-group-name> \
  --query properties.configuration.ingress.fqdn

# Test the endpoint
curl https://<fqdn>
```

### Monitor in Azure Portal

1. Go to Azure Container Apps resource
2. Check "Metrics" for:
   - HTTP request count
   - Response time
   - Error rate
3. Check "Logs" in "Diagnostics settings"

## Scaling Configuration

Configure Container App scaling in Terraform:

```hcl
scale {
  min_replicas = 1
  max_replicas = 10
}
```

Automatic scaling is based on HTTP request metrics.

## Troubleshooting

### Application Not Starting

**Check logs**:
```bash
az containerapp logs show --name <app-name>
```

**Common issues**:
- Missing environment variables
- Invalid Azure OpenAI endpoint
- Network connectivity issues

### Slow Responses

**Possible causes**:
- Azure OpenAI token limits exceeded
- Insufficient Container App CPU/memory
- Network latency to OpenAI service

**Solution**:
- Increase min/max replicas in Terraform
- Monitor Azure OpenAI quotas
- Check network performance

### Authentication Errors

**Verify managed identity**:
```bash
az identity show --ids <identity-resource-id>
```

**Check RBAC assignment**:
```bash
az role assignment list \
  --assignee <principal-id> \
  --scope <openai-resource-id>
```

## Production Best Practices

1. **Use Azure Key Vault** for sensitive configuration
2. **Enable Container App Workload Profiles** for dedicated compute
3. **Configure Application Insights** for detailed monitoring
4. **Set up Azure Firewall rules** for additional security
5. **Use Private Endpoints** for all backend services
6. **Implement rate limiting** via API Management if needed
7. **Regular backup** of configuration
8. **Test failure scenarios** before production

## Local Testing

Before deploying to Azure, test locally:

```bash
# Set environment variables
export OPENAI_HOST=azure
export AZURE_OPENAI_ENDPOINT=https://<your-resource>.openai.azure.com/
export AZURE_OPENAI_KEY_FOR_CHATVISION=<your-api-key>
export OPENAI_MODEL=gpt-4o
export AZURE_TENANT_ID=<your-tenant-id>

# Run locally
python -m quart --app src.quartapp run --port 50505

# Test endpoint
curl http://localhost:50505
```

## Cleanup

To remove the application from Azure:

```bash
# Destroy all resources
terraform destroy

# Or, selectively destroy Container App
terraform destroy -target=azurerm_container_app.main
```

## Support

For issues related to:
- **Terraform**: Refer to `../README.md` in the main ai-architecture folder
- **Application**: Check the original repository at https://github.com/Azure-Samples/openai-chat-vision-quickstart
- **Azure Services**: Consult Microsoft Azure documentation

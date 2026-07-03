# Deploy containerized application to Azure using Terraform and Docker
# This script builds a Docker image, pushes it to Azure Container Registry,
# and deploys infrastructure using Terraform.

param(
    # Name of the container image to build and deploy
    [string]$ImageName = "foundry-chat",
    # Tag for the container image
    [string]$ImageTag = "latest",
    # Azure subscription ID (optional; uses current subscription if not specified)
    [string]$SubscriptionId = "",
    # Automatically approve Terraform changes without prompting
    [switch]$AutoApprove
)

# Exit on any error
$ErrorActionPreference = "Stop"

# Helper function to display status messages with consistent formatting
function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

# Wrapper function to execute terraform apply with optional auto-approval
function Invoke-TerraformApply {
    param(
        # Additional arguments to pass to terraform apply (e.g., -target flags)
        [string[]]$ExtraArgs = @()
    )

    $args = @("apply") + $ExtraArgs
    if ($AutoApprove) {
        $args += "-auto-approve"
    }

    & terraform @args
}

# Get the repository root and app directory paths
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Join-Path $repoRoot "app"

# Validate that the Dockerfile exists in the expected location
if (-not (Test-Path (Join-Path $appDir "Dockerfile"))) {
    throw "Expected app Dockerfile at '$appDir'."
}

# Change to repository root for subsequent operations
Push-Location $repoRoot
try {
    # Set Azure subscription if specified
    if ($SubscriptionId) {
        Write-Step "Setting Azure subscription"
        az account set --subscription $SubscriptionId
    }

    # Configure Terraform environment variables with container image details
    # Keep Terraform variables and built image coordinates aligned.
    $env:TF_VAR_app_image_name = $ImageName
    $env:TF_VAR_app_image_tag = $ImageTag

    # Initialize Terraform working directory
    Write-Step "Initializing Terraform"
    terraform init

    # Create prerequisite Azure resources (resource group, container registry, etc.)
    Write-Step "Creating prerequisite infrastructure (including ACR)"
    Invoke-TerraformApply -ExtraArgs @(
        "-target=module.network", 
        "-target=module.management", 
        "-target=module.data", 
        "-target=module.ai")

    # Retrieve Azure Container Registry details from Terraform outputs
    Write-Step "Reading ACR outputs"
    $acrName = (terraform output -raw container_registry_name).Trim()
    $acrLoginServer = (terraform output -raw container_registry_login_server).Trim()
    $imageRef = "$acrLoginServer/$ImageName`:$ImageTag"

    # Authenticate Docker with Azure Container Registry
    Write-Step "Logging into Azure Container Registry"
    az acr login --name $acrName

    # Build the Docker image from the app directory
    Write-Step "Building container image"
    docker build --platform linux/amd64 -t $imageRef $appDir

    # Push the built image to Azure Container Registry
    Write-Step "Pushing container image"
    docker push $imageRef

    # Deploy all application infrastructure using Terraform
    Write-Step "Applying full Terraform configuration"
    Invoke-TerraformApply

    # Display completion message with deployed image reference
    Write-Host "`nDeployment completed. Image: $imageRef" -ForegroundColor Green
}
finally {
    # Return to original directory
    Pop-Location
}

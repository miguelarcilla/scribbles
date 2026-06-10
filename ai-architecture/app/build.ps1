# Build and deploy script for Chat Vision Container App
# Usage: .\build.ps1

param(
    [string]$Action = "build",
    [string]$Registry = "",
    [string]$ImageName = "chat-vision"
)

$ErrorActionPreference = "Stop"

function Write-Header {
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host $args[0] -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
}

function Write-Success {
    Write-Host "✓ $($args[0])" -ForegroundColor Green
}

function Write-Error {
    Write-Host "❌ Error: $($args[0])" -ForegroundColor Red
    exit 1
}

function Write-Info {
    Write-Host "ℹ $($args[0])" -ForegroundColor Yellow
}

function Build-Image {
    Write-Header "Building Container Image"
    
    # Check Docker
    try {
        docker ps | Out-Null
    } catch {
        Write-Error "Docker daemon is not running. Please start Docker Desktop."
    }
    
    Write-Info "Building image: ${ImageName}:latest"
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    
    if (docker build -f "$scriptPath\Dockerfile" -t "${ImageName}:latest" $scriptPath) {
        Write-Success "Container image built successfully: ${ImageName}:latest"
        Write-Host ""
        docker images | grep $ImageName | Select-Object -First 1 | Format-Table -AutoSize
    } else {
        Write-Error "Failed to build container image"
    }
}

function Push-Image {
    param([string]$Registry)
    
    if ([string]::IsNullOrEmpty($Registry)) {
        Write-Error "Registry name is required. Usage: .\build.ps1 -Action push -Registry <acr-name>"
    }
    
    Write-Header "Pushing to Azure Container Registry"
    
    $taggedName = "${Registry}.azurecr.io/${ImageName}:latest"
    
    Write-Info "Tagging image as: $taggedName"
    docker tag "${ImageName}:latest" "$taggedName"
    Write-Success "Image tagged"
    
    Write-Info "Logging into Azure Container Registry..."
    az acr login --name $Registry
    Write-Success "Logged into registry"
    
    Write-Info "Pushing to registry..."
    if (docker push "$taggedName") {
        Write-Success "Image pushed to $taggedName"
    } else {
        Write-Error "Failed to push image"
    }
}

function Show-NextSteps {
    Write-Header "Next Steps"
    Write-Host @"

1. Tag the image for your registry:
   docker tag ${ImageName}:latest <your-acr-name>.azurecr.io/${ImageName}:latest

2. Login to Azure Container Registry:
   az acr login --name <your-acr-name>

3. Push to registry:
   docker push <your-acr-name>.azurecr.io/${ImageName}:latest

4. Deploy via Terraform:
   cd ..
   terraform plan -out=tfplan
   terraform apply tfplan

5. Test the deployment:
   curl https://<your-container-app-fqdn>/

For more details, see DEPLOYMENT.md

"@ -ForegroundColor Yellow
}

# Main
Write-Header "Chat Vision Container Build & Deploy"

switch ($Action.ToLower()) {
    "build" {
        Build-Image
        Show-NextSteps
    }
    "push" {
        if ([string]::IsNullOrEmpty($Registry)) {
            Write-Error "Registry parameter required for push action"
        }
        Build-Image
        Push-Image -Registry $Registry
    }
    default {
        Write-Error "Unknown action: $Action. Use 'build' or 'push'"
    }
}

Write-Host ""
Write-Success "Done!"

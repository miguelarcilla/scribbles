param(
    [string]$ImageName = "foundry-chat",
    [string]$ImageTag = "latest",
    [string]$SubscriptionId = "",
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Invoke-TerraformApply {
    param(
        [string[]]$ExtraArgs = @()
    )

    $args = @("apply") + $ExtraArgs
    if ($AutoApprove) {
        $args += "-auto-approve"
    }

    & terraform @args
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Join-Path $repoRoot "app"

if (-not (Test-Path (Join-Path $appDir "Dockerfile"))) {
    throw "Expected app Dockerfile at '$appDir'."
}

Push-Location $repoRoot
try {
    if ($SubscriptionId) {
        Write-Step "Setting Azure subscription"
        az account set --subscription $SubscriptionId
    }

    # Keep Terraform variables and built image coordinates aligned.
    $env:TF_VAR_app_image_name = $ImageName
    $env:TF_VAR_app_image_tag = $ImageTag

    Write-Step "Initializing Terraform"
    terraform init

    Write-Step "Creating prerequisite infrastructure (including ACR)"
    Invoke-TerraformApply -ExtraArgs @("-target=module.management")

    Write-Step "Reading ACR outputs"
    $acrName = (terraform output -raw container_registry_name).Trim()
    $acrLoginServer = (terraform output -raw container_registry_login_server).Trim()
    $imageRef = "$acrLoginServer/$ImageName`:$ImageTag"

    Write-Step "Logging into Azure Container Registry"
    az acr login --name $acrName

    Write-Step "Building container image"
    docker build -t $imageRef $appDir

    Write-Step "Pushing container image"
    docker push $imageRef

    Write-Step "Applying full Terraform configuration"
    Invoke-TerraformApply

    Write-Host "`nDeployment completed. Image: $imageRef" -ForegroundColor Green
}
finally {
    Pop-Location
}

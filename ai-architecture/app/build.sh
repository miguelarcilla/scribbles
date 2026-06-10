#!/usr/bin/env bash
# Build and deploy script for Chat Vision Container App

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="chat-vision"
DOCKERFILE="Dockerfile"
WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions
print_header() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================${NC}"
}

print_error() {
    echo -e "${RED}❌ Error: $1${NC}"
    exit 1
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Main script
main() {
    print_header "Chat Vision Container Build & Deploy"

    # Check if Docker is running
    if ! docker ps &>/dev/null; then
        print_error "Docker daemon is not running. Please start Docker Desktop."
    fi
    print_success "Docker is running"

    # Build the image
    print_header "Building Container Image"
    cd "$WORKING_DIR"
    
    if docker build -f "$DOCKERFILE" -t "$IMAGE_NAME:latest" .; then
        print_success "Container image built successfully: $IMAGE_NAME:latest"
    else
        print_error "Failed to build container image"
    fi

    # Display next steps
    print_header "Next Steps"
    echo -e "
1. ${YELLOW}Tag the image for your registry:${NC}
   docker tag $IMAGE_NAME:latest <your-acr-name>.azurecr.io/$IMAGE_NAME:latest

2. ${YELLOW}Login to Azure Container Registry:${NC}
   az acr login --name <your-acr-name>

3. ${YELLOW}Push to registry:${NC}
   docker push <your-acr-name>.azurecr.io/$IMAGE_NAME:latest

4. ${YELLOW}Deploy via Terraform:${NC}
   cd ../
   terraform plan -out=tfplan
   terraform apply tfplan

5. ${YELLOW}Test the deployment:${NC}
   curl https://<your-container-app-fqdn>/

${YELLOW}For more details, see DEPLOYMENT.md${NC}
"
}

# Run main if sourced from command line
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

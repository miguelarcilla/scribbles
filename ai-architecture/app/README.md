# Simple Foundry Chat App

A minimal single-page chat app that talks to an OpenAI model hosted on Microsoft Foundry.

## What's included

- **Frontend**: Single-page app in `templates/index.html` + `static/app.js`
- **Backend**: Flask server in `server.py` (lightweight REST API)
- **Security**: Azure AD authentication via `DefaultAzureCredential` (backend only; browser never sees credentials)
- **Containerization**: `Dockerfile` for Azure Container Apps deployment

## Local development

### Prerequisites
- Python 3.11+
- Azure CLI (`az login`)
- Access to a Foundry model deployment

### Setup and run

```powershell
cd app
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
cp .env.sample .env           # edit with your Foundry endpoint/deployment
python server.py
```

Open `http://localhost:50505` in your browser.

### Environment variables

The app supports two routing modes. Choose one:

#### Option 1: Direct Foundry endpoint (default)
```
AZURE_OPENAI_ENDPOINT=https://epsasia-newsletter-agent-foundry.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-5.4
AZURE_OPENAI_API_VERSION=2025-01-01-preview
```

#### Option 2: API Management gateway
If you have APIM deployed (recommended for production), set:
```
AZURE_APIM_ENDPOINT=https://apim-instance.azure-api.net/foundry
AZURE_APIM_SUBSCRIPTION_KEY=your-subscription-key-here   # optional; uses managed identity if empty
AZURE_OPENAI_DEPLOYMENT=gpt-5.4
AZURE_OPENAI_API_VERSION=2025-01-01-preview
```

When `AZURE_APIM_ENDPOINT` is set, it takes precedence and routes through API Management. Choose authentication:
- **Subscription key** (simple, for testing): set `AZURE_APIM_SUBSCRIPTION_KEY`
- **Managed identity** (production): leave `AZURE_APIM_SUBSCRIPTION_KEY` empty; uses `DefaultAzureCredential`

See [.env.sample](.env.sample) for a template with both options.

## Deployment to Azure

**See the [main README](../README.md) for full deployment instructions.**

For a one-command build-and-deploy:
```powershell
cd ..
./deploy-app.ps1 -ImageName foundry-chat -ImageTag latest -AutoApprove
```

To deploy manually:
1. Build the Docker image: `docker build -t foundry-chat:latest .`
2. Push to Azure Container Registry
3. Create a Container App with the image
4. Set the environment variables above on the Container App
5. Assign the Container App's managed identity the role `Cognitive Services OpenAI User`

## How it works

**Routing logic:**
- If `AZURE_APIM_ENDPOINT` is configured, requests route through **API Management** (with either subscription key or managed identity auth)
- Otherwise, requests go directly to **Foundry** (with managed identity via `DefaultAzureCredential`)

**Authentication:**
- **Direct Foundry**: Flask uses `DefaultAzureCredential` to get a Cognitive Services token with scope `https://cognitiveservices.azure.com/.default`
- **APIM + Subscription Key**: Flask includes the subscription key in request headers; no managed identity required
- **APIM + Managed Identity** (recommended): Flask uses `DefaultAzureCredential` to get a management token with scope `https://management.azure.com/.default`; Container App identity is automatically granted `Cognitive Services OpenAI User` role on APIM during infrastructure deployment

**Frontend:**
- Browser calls Flask endpoints (no credentials exposed to browser)
- Flask proxies all auth headers—browser never sees credentials
- In Azure Container Apps with managed identity, authentication is fully automatic
- The infrastructure automatically configures all necessary RBAC role assignments

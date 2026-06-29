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

Update `.env` with:
- `AZURE_OPENAI_ENDPOINT` — your Foundry instance endpoint
- `AZURE_OPENAI_DEPLOYMENT` — model deployment name
- `AZURE_OPENAI_API_VERSION` — API version (e.g., `2024-08-01-preview`)

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

- Browser calls Flask endpoints (no credentials exposed)
- Flask uses `DefaultAzureCredential` to authenticate to Foundry
- In Azure Container Apps with managed identity, authentication is automatic
- For local dev, `DefaultAzureCredential` uses your `az login` context

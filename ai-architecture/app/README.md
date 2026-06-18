# Simple Foundry Chat App

A minimal single-page chat app that talks to an OpenAI model hosted on Microsoft Foundry.

## What this includes

- Single-page frontend: `templates/index.html` + `static/app.js`
- Small Flask backend: `server.py`
- Secure auth pattern: backend uses Azure AD token via `DefaultAzureCredential`
- Dockerfile for Azure Container Apps deployment

## Prerequisites

1. Python 3.11+
2. Azure CLI login (`az login`)
3. Access to your Foundry/OpenAI deployment

## Configure

1. Copy `.env.sample` to `.env`
2. Update values as needed:
   - `AZURE_OPENAI_ENDPOINT`
   - `AZURE_OPENAI_DEPLOYMENT`
   - `AZURE_OPENAI_API_VERSION`

## Run locally

```powershell
cd c:\Code\scribbles\ai-architecture\app
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Get-Content .env.sample | Set-Content .env
python server.py
```

Open http://localhost:50505

## Build container

```powershell
cd c:\Code\scribbles\ai-architecture\app
docker build -t foundry-chat:latest .
```

## Deploy to Azure Container Apps

1. Push the image to your ACR.
2. Set these environment variables on the container app:
   - `AZURE_OPENAI_ENDPOINT`
   - `AZURE_OPENAI_DEPLOYMENT`
   - `AZURE_OPENAI_API_VERSION`
3. Assign the Container App managed identity the role:
   - `Cognitive Services OpenAI User`

## Notes

- The browser never receives credentials.
- If running in Azure Container Apps with managed identity, this app will use it automatically.
- For local development, `DefaultAzureCredential` uses your signed-in Azure CLI context.

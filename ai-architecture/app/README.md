# Azure OpenAI Chat + Vision Application

This is a Python Quart-based web application that demonstrates chat capabilities with Azure OpenAI vision models (GPT-4o). Users can upload images and ask questions about them, with support for speech input/output.

## Overview

The application is designed to deploy to **Azure Container Apps** via the Terraform infrastructure defined in the parent `ai-architecture` module.

### Features

- **Chat Interface**: Interactive web-based chat UI with streaming responses
- **Vision Capabilities**: Upload images and analyze them with GPT-4o
- **Speech I/O**: Browser-native speech input and output buttons
- **Azure OpenAI Integration**: Uses managed identity for secure authentication
- **Responsive Design**: Bootstrap-based UI with mobile support

## Architecture

```
Container App (Azure Container Apps)
    ↓
  [Quart Python Application]
    ├─ Chat Blueprint (/chat/stream endpoint)
    ├─ Static Files (JS, CSS, Images)
    └─ HTML Templates
    ↓
  [Azure OpenAI (via Managed Identity)]
```

## Project Structure

```
app/
├── src/
│   ├── quartapp/          # Main application package
│   │   ├── __init__.py    # App factory (create_app)
│   │   ├── chat.py        # Chat blueprint with OpenAI integration
│   │   ├── templates/
│   │   │   └── index.html # Main UI
│   │   └── static/
│   │       ├── speech-input.js      # Speech recognition
│   │       ├── speech-output.js     # Speech synthesis
│   │       └── styles.css           # Styling
│   ├── Dockerfile         # Multi-stage container build
│   ├── gunicorn.conf.py   # ASGI server configuration
│   ├── pyproject.toml     # Project metadata
│   └── __init__.py
├── .env.sample            # Example environment variables
├── requirements.txt       # Python dependencies
└── README.md             # This file
```

## Environment Variables

The application requires the following environment variables for Azure OpenAI:

### For Local Development
```bash
# Copy .env.sample to .env and fill in your values
OPENAI_HOST=azure
AZURE_OPENAI_ENDPOINT=https://<your-resource>.openai.azure.com/
AZURE_OPENAI_KEY_FOR_CHATVISION=<your-api-key>  # Only for local dev
AZURE_TENANT_ID=<your-tenant-id>
OPENAI_MODEL=gpt-4o
```

### For Production (Container App with Managed Identity)
```bash
OPENAI_HOST=azure
AZURE_OPENAI_ENDPOINT=https://<your-resource>.openai.azure.com/
AZURE_TENANT_ID=<your-tenant-id>
OPENAI_MODEL=gpt-4o
RUNNING_IN_PRODUCTION=1
AZURE_CLIENT_ID=<managed-identity-client-id>  # Optional, for specific identity
```

## Local Development

### Prerequisites

- Python 3.10+
- pip or poetry
- Azure OpenAI deployment

### Setup

1. **Create virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment**:
   ```bash
   cp .env.sample .env
   # Edit .env with your Azure OpenAI details
   ```

4. **Run development server**:
   ```bash
   python -m quart --app src.quartapp run --port 50505 --reload
   ```

   Access at: `http://localhost:50505`

## Container Deployment

### Building the Docker Image

The application includes a multi-stage Dockerfile optimized for production:

```bash
# From the app directory
docker build -t <registry>.azurecr.io/chat-vision:latest .
```

### Environment Variables for Container

When deploying via Container Apps (Terraform), these variables should be set in the `aca.bicep` module:

- `OPENAI_HOST`: Set to `azure`
- `AZURE_OPENAI_ENDPOINT`: Azure OpenAI resource endpoint
- `OPENAI_MODEL`: Model name (e.g., `gpt-4o`)
- `AZURE_TENANT_ID`: Your Azure tenant ID
- `RUNNING_IN_PRODUCTION`: Set to `1`

The managed identity for the Container App will handle Azure OpenAI authentication.

## Integration with Terraform

This application is configured to work with the Azure infrastructure defined in the Terraform modules:

### Key Integration Points

1. **Container Apps Module** (`modules/application/`)
   - Hosts the containerized application
   - Manages the Quart server on port 50505

2. **Network Module** (`modules/network/`)
   - Provides network isolation and security groups
   - Private endpoints for Azure services

3. **AI Module** (`modules/ai/`)
   - Azure OpenAI resource deployment
   - Model deployment (GPT-4o)

4. **APIM Module** (`modules/apim/`)
   - Optional API Management layer
   - Rate limiting and monitoring

### Terraform Deployment

The parent Terraform configuration will:

1. Build and push this image to Azure Container Registry
2. Deploy to Azure Container Apps with:
   - Managed identity for Azure OpenAI authentication
   - Appropriate network configuration
   - Environment variables configuration
   - Ingress enabled on port 50505

## API Endpoints

### `GET /`
Returns the main HTML chat interface.

### `POST /chat/stream`
Handles chat requests with optional image uploads.

**Request Body**:
```json
{
  "messages": [
    {
      "role": "user",
      "content": [
        {"type": "input_text", "text": "What's in this image?"}
      ]
    }
  ],
  "context": {
    "file": "<base64-encoded-image-data>",
    "file_name": "image.jpg"
  }
}
```

**Response**: Streaming NDJSON format with chat response chunks

## Testing

Run unit tests:
```bash
pytest tests/
```

Run end-to-end tests:
```bash
python scripts/e2e_chat_playwright.py https://your-deployed-app-url
```

## Security Considerations

- ✅ Uses **Managed Identity** for Azure OpenAI authentication (no keys in container)
- ✅ Network isolation via private endpoints
- ✅ HTTPS-only communication
- ✅ Input validation and sanitization
- ⚠️ HTML content from chat responses should be sanitized before display in production

## Performance & Scaling

- **Min Replicas**: 1
- **Max Replicas**: 10 (configurable via Terraform)
- **CPU**: 0.5 cores per replica
- **Memory**: 1GB per replica
- **Scaling**: Automatic based on HTTP request volume

## Troubleshooting

### Common Issues

**Connection refused to Azure OpenAI**
- Verify `AZURE_OPENAI_ENDPOINT` is correct
- Check managed identity has `Cognitive Services OpenAI User` role
- Ensure network allows outbound HTTPS to OpenAI service

**Empty chat responses**
- Check OpenAI model is deployed and available
- Verify token limits not exceeded
- Check logs: `az containerapp logs show --name <app-name>`

**Slow responses**
- Check Container App CPU/memory allocation
- Monitor Azure OpenAI token usage
- Consider increasing replicas via Terraform

## References

- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
- [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Quart Framework](https://quart.palletsprojects.com/)
- [Original Sample Repository](https://github.com/Azure-Samples/openai-chat-vision-quickstart)

## License

MIT License - See LICENSE file in parent repository

import os

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from flask import Flask, jsonify, render_template, request
from openai import AzureOpenAI


load_dotenv()


app = Flask(__name__)


def create_client() -> AzureOpenAI:
    """
    Create an AzureOpenAI client configured for either direct Foundry access or API Management routing.
    
    Priority:
    1. If AZURE_APIM_ENDPOINT is set, use APIM with managed identity or subscription key
    2. Otherwise, use direct Foundry endpoint
    """
    deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT")
    api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2025-01-01-preview")
    
    if not deployment:
        raise RuntimeError("AZURE_OPENAI_DEPLOYMENT is required")

    apim_endpoint = os.getenv("AZURE_APIM_ENDPOINT", "").strip()
    apim_key = os.getenv("AZURE_APIM_SUBSCRIPTION_KEY", "").strip()

    if apim_endpoint:
        # Use API Management
        if apim_key:
            # Subscription key-based authentication
            return AzureOpenAI(
                azure_endpoint=apim_endpoint,
                api_key=apim_key,
                api_version=api_version,
            )
        else:
            # Managed identity authentication via DefaultAzureCredential
            credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
            # APIM requires the "https://management.azure.com/.default" scope for managed identity
            token_provider = get_bearer_token_provider(credential, "https://management.azure.com/.default")
            return AzureOpenAI(
                azure_endpoint=apim_endpoint,
                azure_ad_token_provider=token_provider,
                api_version=api_version,
            )
    else:
        # Use direct Foundry endpoint
        endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
        if not endpoint:
            raise RuntimeError("AZURE_OPENAI_ENDPOINT or AZURE_APIM_ENDPOINT is required")

        credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
        token_provider = get_bearer_token_provider(credential, "https://cognitiveservices.azure.com/.default")

        return AzureOpenAI(
            azure_endpoint=endpoint,
            azure_ad_token_provider=token_provider,
            api_version=api_version,
        )


client = create_client()


@app.get("/")
def index():
    return render_template("index.html")


@app.post("/api/chat")
def chat():
    payload = request.get_json(silent=True) or {}
    message = (payload.get("message") or "").strip()

    if not message:
        return jsonify({"error": "Message is required."}), 400

    try:
        deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT")
        system_prompt = os.getenv(
            "SYSTEM_PROMPT",
            "You are a helpful assistant. Keep answers concise unless the user asks for detail.",
        )

        response = client.chat.completions.create(
            model=deployment,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": message},
            ],
            temperature=0.2,
        )

        reply = response.choices[0].message.content or ""
        return jsonify({"reply": reply})
    except Exception as exc:
        return jsonify({"error": f"OpenAI request failed: {exc}"}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "50505")), debug=True)

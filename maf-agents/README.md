---
title: Japan trip-planning harness
description: Run a local .NET agent with Microsoft Agent Framework and an Azure OpenAI model.
---

## What this runs

A .NET 10 console app using Microsoft Agent Framework's `HarnessAgent`.
The harness supplies the function-invocation loop, in-memory conversation history,
todo tracking, and plan/execute modes. The default task plans seven days in Japan
for two travelers, including Tokyo and Kyoto, with a JPY 300,000 budget excluding
international flights.

This is a local harness, not a Foundry-managed GitHub Copilot harness or a hosted
Foundry Agent Service deployment. No Azure resources are created.

## Configure credentials

You need the .NET 10 SDK and an existing Azure OpenAI or Microsoft Foundry model
deployment that supports chat completions and function calling.

Edit the included local [.env](.env):

```dotenv
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_DEPLOYMENT_NAME=your-deployment-name
```

Use the resource root, not a project endpoint, deployment URL, or URL ending in
`/openai/v1`. The app appends `/openai/v1/` and uses Azure's OpenAI-compatible
Chat Completions API. A Foundry resource root such as
`https://your-resource.services.ai.azure.com` is also supported for deployments
exposed through that API. The deployment name can differ from the model name.

Authentication uses Microsoft Entra ID through `DefaultAzureCredential`, with
automatically refreshed tokens for `https://cognitiveservices.azure.com/.default`.
No API key is required or read. For local development, sign in with Azure CLI:

```powershell
az login
```

The OpenAI SDK currently marks its token-authentication constructor as experimental.
[Program.cs](Program.cs) suppresses `OPENAI001` only around that client construction.

Sign in to the tenant that owns the resource (use `az login --tenant <tenant-id>`
if needed). Your identity needs the `Cognitive Services OpenAI User` role on the
Azure OpenAI/Foundry resource. A subscription `Contributor` role alone does not
grant model inference access. Role assignments can take several minutes to propagate.
In Azure, enable a managed identity for the host and grant it the same role.
For a user-assigned managed identity, set `AZURE_CLIENT_ID` to its client ID.

The local [.env](.env) is gitignored and is not copied into build or publish output.
After cloning, create it from [.env.example](.env.example):

```powershell
Copy-Item .\maf-agents\.env.example .\maf-agents\.env
```

Existing environment variables take precedence over values in the file.
The app looks for `.env` in the working directory, then `maf-agents\.env`,
so you can run from the repository root or this project folder.
When running published binaries elsewhere, supply environment variables or a
`.env` in the working directory. Never commit credentials.

## Run the sample

From the repository root:

```powershell
dotnet run --project .\maf-agents
```

Supply your own request:

```powershell
dotnet run --project .\maf-agents -- "Plan a five-day Tokyo food trip for one adult with a JPY 150,000 budget."
```

Use `-- --help` for usage without credentials. Each invocation creates a new
in-memory session. The agent prints its response after the planning run finishes.
Press Ctrl+C to cancel; runs also have a three-minute timeout and a maximum of
12 function-invocation iterations per model request.

Model requests incur charges on your Azure deployment. The sample has no live
search or booking tools, so prices, opening hours, and transport details are
unverified estimates. File memory, local skill discovery, web search, file access,
shell execution, and background agents are not enabled.

## Extend the scaffold

* Change `DefaultTask` or the instructions in [JapanTripAgent.cs](JapanTripAgent.cs)
* Register additional function tools through `HarnessAgentOptions.ChatOptions.Tools`
* Reuse an `AgentSession` across calls when adding a conversational interface
* Enable additional harness capabilities deliberately when your application needs them

[Program.cs](Program.cs) handles configuration, client creation, cancellation, and
console output. [ModelSettings.cs](ModelSettings.cs) validates settings without
printing credentials. The unnecessary Foundry Agent Service dependency is replaced
with the local harness and OpenAI client integration packages.

## Validate

```powershell
dotnet build .\maf-agents\maf-agents.csproj
dotnet test .\maf-agents.Tests\maf-agents.Tests.csproj
```

Tests use a substitute chat client and do not require credentials, incur charges,
or contact Azure. A real itinerary run requires your configured model deployment.

See the [Microsoft Agent Framework documentation](https://learn.microsoft.com/agent-framework/)
and [Azure OpenAI provider documentation](https://learn.microsoft.com/agent-framework/integrations/by-component/model-providers/azure-openai).

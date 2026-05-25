# Taskboard

Multi-tenant shared to-do list web service built with Blazor WebAssembly, ASP.NET Core Web API, Azure Cosmos DB, and Microsoft Entra ID.

## Architecture

- **Frontend**: Blazor WebAssembly → Azure Static Web App
- **Backend**: ASP.NET Core 9 Web API → Azure App Service (Linux)
- **Database**: Azure Cosmos DB (NoSQL, partitioned by `tenantId`)
- **Identity**: Microsoft Entra ID (multi-tenant)
- **IaC**: Azure Bicep

See [CONSTITUTION.md](./CONSTITUTION.md) for the full architectural spec.

## Prerequisites

- [.NET 9 SDK](https://dot.net)
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) + [Bicep CLI](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install)
- [Azure Cosmos DB Emulator](https://docs.microsoft.com/azure/cosmos-db/local-emulator) (for local dev)
- Two Entra ID app registrations (see Constitution §7)

## Quick Start

```bash
# Clone and restore
git clone ...
cd taskboard-saas
dotnet restore

# Run the API
cd src/Taskboard.Api
dotnet run

# Run the Blazor frontend (separate terminal)
cd src/Taskboard.Web
dotnet run
```

## Configuration

Copy the placeholder values in `src/Taskboard.Api/appsettings.json` and `src/Taskboard.Web/wwwroot/appsettings.json` — fill in your Entra ID client IDs and CosmosDB connection string.

## Deployment

```bash
# Create a resource group
az group create --name rg-taskboard-dev --location eastus2

# Deploy infrastructure
az deployment group create \
  --resource-group rg-taskboard-dev \
  --template-file infra/main.bicep \
  --parameters infra/parameters/dev.bicepparam \
               apiClientId=<YOUR_API_CLIENT_ID> \
               webClientId=<YOUR_WEB_CLIENT_ID>
```

The Static Web App deployment is handled automatically by GitHub Actions after the first `az deployment` wires up the SWA with your repository.

## Project Structure

```
taskboard-saas/
├── CONSTITUTION.md          ← Authoritative architectural spec
├── Taskboard.sln
├── src/
│   ├── Taskboard.Api/       ← ASP.NET Core Web API
│   ├── Taskboard.Web/       ← Blazor WebAssembly SPA
│   └── Taskboard.Shared/    ← Shared DTOs and constants
├── infra/
│   ├── main.bicep
│   └── modules/
│       ├── appService.bicep
│       ├── cosmosDb.bicep
│       └── staticWebApp.bicep
├── docs/specs/              ← Feature specs
└── tests/
```

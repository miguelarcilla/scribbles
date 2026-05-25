@description('Deployment environment (dev, staging, prod)')
param environment string = 'dev'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Entra ID Client ID for the API app registration')
param apiClientId string

@description('Entra ID Client ID for the Web app registration')
param webClientId string

@description('CosmosDB throughput mode')
@allowed(['serverless', 'provisioned'])
param cosmosThroughputMode string = 'serverless'

@description('App Service plan SKU')
param appServiceSkuName string = 'B2'

@description('Allowed CORS origin for the API (set to the Static Web App URL after first deploy)')
param webAppCorsOrigin string = '*'

// ── Modules ──────────────────────────────────────────────────────────────────

module cosmos 'modules/cosmosDb.bicep' = {
  name: 'cosmos-${environment}'
  params: {
    accountName: 'cosmos-taskboard-${environment}'
    location: location
    throughputMode: cosmosThroughputMode
  }
}

module api 'modules/appService.bicep' = {
  name: 'api-${environment}'
  params: {
    appName: 'app-taskboard-api-${environment}'
    location: location
    skuName: appServiceSkuName
    appSettings: [
      { name: 'AzureAd__TenantId', value: 'common' }
      { name: 'AzureAd__ClientId', value: apiClientId }
      { name: 'AzureAd__Audience', value: 'api://${apiClientId}' }
      { name: 'CosmosDb__ConnectionString', value: cosmos.outputs.connectionString }
      { name: 'CosmosDb__DatabaseName', value: 'taskboard' }
      { name: 'AllowedOrigins__0', value: webAppCorsOrigin }
      { name: 'ASPNETCORE_ENVIRONMENT', value: environment == 'prod' ? 'Production' : 'Development' }
    ]
  }
}

module web 'modules/staticWebApp.bicep' = {
  name: 'web-${environment}'
  params: {
    appName: 'stapp-taskboard-${environment}'
    location: location
    apiUrl: 'https://${api.outputs.defaultHostname}'
    azureAdClientId: webClientId
    apiScopes: 'api://${apiClientId}/access_as_user'
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output webUrl string = 'https://${web.outputs.defaultHostname}'
output apiUrl string = 'https://${api.outputs.defaultHostname}'
output cosmosAccountName string = cosmos.outputs.accountName

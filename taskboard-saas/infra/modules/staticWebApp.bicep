@description('Static Web App name')
param appName string

@description('Azure region (Static Web Apps have limited region support)')
param location string = 'eastus2'

@description('API backend URL')
param apiUrl string

@description('Entra ID client ID for the SPA')
param azureAdClientId string

@description('Entra ID API scope for token acquisition')
param apiScopes string

// ── Static Web App ────────────────────────────────────────────────────────────

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: appName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    enterpriseGradeCdnStatus: 'Disabled'
  }
}

// ── App Settings injected at deploy time ─────────────────────────────────────

resource staticWebAppSettings 'Microsoft.Web/staticSites/config@2023-12-01' = {
  parent: staticWebApp
  name: 'appsettings'
  properties: {
    ApiBaseUrl: apiUrl
    AzureAdClientId: azureAdClientId
    AzureAdAuthority: '${environment().authentication.loginEndpoint}common'
    ApiScopes: apiScopes
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output defaultHostname string = staticWebApp.properties.defaultHostname
output appId string = staticWebApp.id

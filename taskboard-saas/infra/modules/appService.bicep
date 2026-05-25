@description('App Service name')
param appName string

@description('Azure region')
param location string

@description('App Service Plan SKU')
param skuName string = 'B2'

@description('App settings to configure on the web app')
param appSettings array = []

// ── App Service Plan ──────────────────────────────────────────────────────────

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'plan-${appName}'
  location: location
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true
  }
}

// ── App Service ───────────────────────────────────────────────────────────────

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|9.0'
      alwaysOn: true
      minTlsVersion: '1.2'
      appSettings: appSettings
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output defaultHostname string = appService.properties.defaultHostName
output principalId string = appService.identity.principalId

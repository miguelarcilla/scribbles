using './main.bicep'

param environment = 'prod'
param location = 'eastus2'
param apiClientId = '<API_CLIENT_ID>'
param webClientId = '<WEB_CLIENT_ID>'
param cosmosThroughputMode = 'provisioned'
param appServiceSkuName = 'P2v3'

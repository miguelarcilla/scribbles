using './main.bicep'

param environment = 'dev'
param location = 'eastus2'
param apiClientId = '<API_CLIENT_ID>'
param webClientId = '<WEB_CLIENT_ID>'
param cosmosThroughputMode = 'serverless'
param appServiceSkuName = 'B2'

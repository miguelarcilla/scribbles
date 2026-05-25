@description('Name of the CosmosDB account')
param accountName string

@description('Azure region')
param location string

@description('Throughput mode: serverless or provisioned')
@allowed(['serverless', 'provisioned'])
param throughputMode string = 'serverless'

@description('RU/s when using provisioned throughput')
param provisionedThroughput int = 400

// ── CosmosDB Account ─────────────────────────────────────────────────────────

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-02-15-preview' = {
  name: accountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: throughputMode == 'serverless' ? [
      { name: 'EnableServerless' }
    ] : []
  }
}

// ── Database ──────────────────────────────────────────────────────────────────

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-02-15-preview' = {
  parent: cosmosAccount
  name: 'taskboard'
  properties: {
    resource: {
      id: 'taskboard'
    }
  }
}

// ── Containers ────────────────────────────────────────────────────────────────

var containers = [
  { name: 'tenants', partitionKey: '/tenantId' }
  { name: 'users', partitionKey: '/tenantId' }
  { name: 'boards', partitionKey: '/tenantId' }
  { name: 'tasks', partitionKey: '/tenantId' }
]

resource cosmosContainers 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-02-15-preview' = [for container in containers: {
  parent: database
  name: container.name
  properties: {
    resource: {
      id: container.name
      partitionKey: {
        paths: [container.partitionKey]
        kind: 'Hash'
        version: 2
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [{ path: '/*' }]
        excludedPaths: [{ path: '/"_etag"/?' }]
      }
    }
    options: throughputMode == 'provisioned' ? {
      throughput: provisionedThroughput
    } : {}
  }
}]

// ── Outputs ───────────────────────────────────────────────────────────────────

output accountName string = cosmosAccount.name
@secure()
output connectionString string = cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString

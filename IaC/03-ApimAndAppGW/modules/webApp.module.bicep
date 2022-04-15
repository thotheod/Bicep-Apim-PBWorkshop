param name string
param location string = resourceGroup().location
param tags object = {}
param appSettings array = []
param appInsightsInstrumentationKey string
param planName string

@description('Whether to create a managed identity for the web app -defaults to \'false\'')
param managedIdentity bool = false

@allowed([
  'S1'
  'S2'
  'S3'
  'P1v3'
  'P2v3'
  'P3v3'
])
param skuName string = 'P1v3'

@description('The subnet Id to integrate the web app with')
param subnetIdForIntegration string 

@description('The Git repository url to deploy the application from -optional')
param appDeployRepoUrl string = ''

@description('The Git repository branch to deploy the application from -optional')
param appDeployBranch string = ''


var skuTier =  substring(skuName, 0, 1) == 'S' ? 'Standard' : 'PremiumV3'


var createSourceControl = !empty(appDeployRepoUrl)
var createNetworkConfig = !empty(subnetIdForIntegration)

var networkConfigAppSettings = createNetworkConfig ? [
  {
    name: 'WEBSITE_VNET_ROUTE_ALL'
    value: '1'
  }
  { 
    name: 'WEBSITE_DNS_SERVER'
    value: '168.63.129.16'
  }
] : []

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: planName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
}

resource webApp 'Microsoft.Web/sites@2020-06-01' = {
  name: name
  location: location  
  identity: {
    type: managedIdentity ? 'SystemAssigned' : 'None'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: concat([
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~10'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsightsInstrumentationKey}'
        }
      ], networkConfigAppSettings, appSettings)
    }
    httpsOnly: true
  }
  tags: union({
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlan.name}': 'Resource'
  }, tags)
}

resource networkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = if (createNetworkConfig) {
  name: '${webApp.name}/VirtualNetwork'
  properties: {
    subnetResourceId: subnetIdForIntegration
  }
}

resource appSourceControl 'Microsoft.Web/sites/sourcecontrols@2020-06-01' = if (createSourceControl) {
  name: '${webApp.name}/web'
  properties: {
    branch: appDeployBranch
    repoUrl: appDeployRepoUrl
    isManualIntegration: true
  }
}

output id string = webApp.id
output name string = webApp.name
output appServicePlanId string = appServicePlan.id
output identity object = managedIdentity ? {
  tenantId: webApp.identity.tenantId
  principalId: webApp.identity.principalId
  type: webApp.identity.type
} : {}
output siteHostName string = webApp.properties.defaultHostName

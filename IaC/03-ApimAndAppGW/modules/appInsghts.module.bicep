param name string
param workspaceName string
param location string
param tags object


resource workspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: name
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

output instrumentationKey string = applicationInsights.properties.InstrumentationKey
output id string = applicationInsights.id
output logAnalyticsWsId string = workspace.id

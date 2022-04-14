param name string
param location string = resourceGroup().location
param tags object 

@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Array of access policy configurations, schema ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/accesspolicies?tabs=json#microsoftkeyvaultvaultsaccesspolicies-object')
param accessPolicies array = []


resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: name
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    accessPolicies: accessPolicies
  }
  tags: tags
}


output id string = keyVault.id
output name string = keyVault.name

@description('Mame of the resource Virtual Network (The name must begin with a letter or number, end with a letter, number or underscore, and may contain only letters, numbers, underscores, periods, or hyphens)')
@minLength(2)
@maxLength(64)
param name string

@description('Azure Region where the resource will be deployed in')
param location string

@description('key-value pairs as tags, to identify the resource')
param tags object

@description('CIDR to be allocated to the new vnet i.e. 192.168.1.0/24')
param vnetAddressSpace string 

@description('An array of the desired subnets for the given vnet. Subnets follow a simpler format as descibed in the comments/HowToUse')
param subnetsInfo array
/*
EXAMPLE OF USE 
var subnetsInfo = [
  {
    name: 'snet1'
    addressPrefix: '192.168.0.0/24'
    privateEndpointNetworkPolicies: 'Enabled' //any value will be translated to Enabled
    nsgId: null         // or ID of the resource
    routeTableId: null  // or ID of the resource
    natGatewayId: null  // or ID of the resource
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.Sql'
      }
    ]    
  }
  {
    name: 'snet2'
    addressPrefix: '192.168.1.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    nsgId: nsgId        // or ID of the resource
    routeTableId: null  // or ID of the resource
    natGatewayId: null  // or ID of the resource
    serviceEndpoints: []    
  }
]
*/

//INFO: based on pattern 'Logical Parameter': https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-logical-parameter
var subnetsToCreate = [for item in subnetsInfo: {
  name: item.name
  properties: {
    addressPrefix: item.addressPrefix
    privateEndpointNetworkPolicies: item.privateEndpointNetworkPolicies =~ 'Disabled' ? 'Disabled' : 'Enabled'
    networkSecurityGroup: item.nsgId != null ? {
       id: item.nsgId
    } : null
    routeTable: item.routeTableId != null ? {
      id: item.routeTableId
    } : null 
    natGateway: item.natGatewayId != null ? {
      id: item.natGatewayId
    } : null
    serviceEndpoints: item.serviceEndpoints
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {   
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }    
    subnets: subnetsToCreate 
  }  
}

output vnetID string = vnet.id
output vnetName string = vnet.name

// INFO: based on second example of https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/loops#array-and-index
output subnetsOutput array = [ for (item, i) in subnetsInfo: {
  subnetIndex: i
  id: vnet.properties.subnets[i].id
  name: vnet.properties.subnets[i].name  
}]

@description('Optional. The Name of the subnet resource.')
param name string

@description('Required. The name of the parent virtual network')
param virtualNetworkName string

@description('Required. The address prefix for the subnet.')
param addressPrefix string

@description('Optional. The resource ID of the network security group to assign to the subnet')
param networkSecurityGroupId string = ''

@description('Optional. The resource ID of the route table to assign to the subnet')
param routeTableId string = ''

@description('Optional. The service endpoints to enable on the subnet')
param serviceEndpoints array = []

@description('Optional. The delegations to enable on the subnet')
param delegations array = []

@description('Optional. The resource ID of the NAT Gateway to use for the subnet')
param natGatewayId string = ''

@description('Optional. enable or disable apply network policies on private endpoint in the subnet.')
@allowed([
  'Disabled'
  'Enabled'
  ''
])
param privateEndpointNetworkPolicies string = ''

@description('Optional. enable or disable apply network policies on private link service in the subnet.')
@allowed([
  'Disabled'
  'Enabled'
  ''
])
param privateLinkServiceNetworkPolicies string = ''

@description('Optional. List of address prefixes for the subnet.')
param addressPrefixes array = []

@description('Optional. Application gateway IP configurations of virtual network resource.')
param applicationGatewayIpConfigurations array = []

@description('Optional. Array of IpAllocation which reference this subnet')
param ipAllocations array = []

@description('Optional. An array of service endpoint policies.')
param serviceEndpointPolicies array = []

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  name: name
  parent: virtualNetwork
  properties: {
    addressPrefix: addressPrefix
    networkSecurityGroup: !empty(networkSecurityGroupId) ? {
      id: networkSecurityGroupId
    } : null
    routeTable: !empty(routeTableId) ? {
      id: routeTableId
    } : null
    natGateway: !empty(natGatewayId) ? {
      id: natGatewayId
    } : null
    serviceEndpoints: serviceEndpoints
    delegations: delegations
    privateEndpointNetworkPolicies: !empty(privateEndpointNetworkPolicies) ? any(privateEndpointNetworkPolicies) : null
    privateLinkServiceNetworkPolicies: !empty(privateLinkServiceNetworkPolicies) ? any(privateLinkServiceNetworkPolicies) : null
    addressPrefixes: addressPrefixes
    applicationGatewayIpConfigurations: applicationGatewayIpConfigurations
    ipAllocations: ipAllocations
    serviceEndpointPolicies: serviceEndpointPolicies
  }
}

@description('The resource group the virtual network subnet was deployed into')
output resourceGroupName string = resourceGroup().name

@description('The name of the virtual network subnet')
output name string = subnet.name

@description('The resource ID of the virtual network subnet')
output resourceId string = subnet.id

@description('The address prefix for the subnet')
output subnetAddressPrefix string = subnet.properties.addressPrefix

@description('List of address prefixes for the subnet')
output subnetAddressPrefixes array = !empty(addressPrefixes) ? subnet.properties.addressPrefixes : []

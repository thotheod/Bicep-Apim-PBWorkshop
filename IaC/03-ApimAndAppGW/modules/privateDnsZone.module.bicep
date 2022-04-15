param name string
param tags object = {}
param registrationEnabled bool = false
param vnetIds array

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'Global'
  tags: tags  
}


resource privateDnsZoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (vnetId, i) in vnetIds: {
  name: '${privateDnsZone.name}/${privateDnsZone.name}-link-${i}'
  location: 'Global'
  properties: {
    registrationEnabled: registrationEnabled
    virtualNetwork: {
      id: vnetId
    }
  }
}]

output id string = privateDnsZone.id
output ids array = [for i in range(0, length(vnetIds)): privateDnsZoneLinks[i].id]

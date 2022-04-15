// Parameters
@description('Azure location to which the resources are to be deployed')
param location string

@description('Id of the subnet within which the VM must be created')
param subnetId string

@description('Name of the Network Interface to be created')
param nicName string

// Resources
resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

// Outputs
output nicId string = nic.id

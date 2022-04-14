// that's the default, but put it here for completeness
targetScope = 'resourceGroup'

// PARAMS
param resourceTags object = {
  'environment': 'dev'
  'project': 'apim-poc'
}

@description('The name of the vnet where we will deploy the subnets')
param vnetName string = 'vnet-apim-poc-dev-001'

@description('CIDR of the subnet for WAF. required')
param snetWAFCIDR string = '172.16.10.0/28'

@description('CIDR of the APIM subnet. required')
param snetApimCIDR string = '172.16.10.16/28'

@description('CIDR of the Bastion subnet. Leave blank if no bastion subnet is required.')
param snetBastionCIDR string = ''//'172.16.10.32/28'

@description('CIDR of the ApimPortal subnet. Leave blank if no ApimPortal subnet is required.')
param snetApimPortalCIDR string = '172.16.10.48/28'

@description('CIDR of the Private Endoint subnet. Leave blank if no Private Endoint subnet is required.')
param snetPEsCIDR string = '172.16.10.64/27'

@description('CIDR of the App Service Plan subnet for the backend PoC services. Leave blank if no workloads subnet is required.')
param snetWorkloadsCIDR string = '172.16.10.96/28'

@description('CIDR of the VMs subnet (Jump box, DevOps agents etc). Leave blank if no VMs subnet is required.')
param snetVMsCIDR string = '172.16.10.112/28'

param location string = resourceGroup().location

// fixed vars
var appName = 'apimPoc'
var region = 'NE'


//dynamic vars
var snetWAFName = 'snet-${appName}-${region}-${vnetName}-WAF'
var snetApimName = 'snet-${appName}-${region}-${vnetName}-Apim'
var snetBastionName = 'AzureBastionSubnet'
var snetApimPortalName = 'snet-${appName}-${region}-${vnetName}-ApimPortal'
var snetPEName = 'snet-${appName}-${region}-${vnetName}-PE'
var snetWorkloadsName = 'snet-${appName}-${region}-${vnetName}-Workloads'
var snetVMsName = 'snet-${appName}-${region}-${vnetName}-Vms'

var nsgSnetVMsName = 'nsg-${snetVMsName}'
var nsgWafName = 'nsg-${snetWAFName}'
var nsgApimName = 'nsg-${snetApimName}'
var nsgBastionName = 'nsg-Bastion-${vnetName}'


module snetWAF 'modules/subnet.module.bicep' = {
  name: 'snetWafDeployment'
  params: {
    addressPrefix: snetWAFCIDR
    name: snetWAFName
    virtualNetworkName: vnetName
    networkSecurityGroupId: nsgWaf.id 
  }
}

module snetApim 'modules/subnet.module.bicep' = {
  name: 'snetApimDeployment'
  params: {
    addressPrefix: snetApimCIDR
    name: snetApimName
    virtualNetworkName: vnetName
    networkSecurityGroupId: nsgApim.id 
  }
}

module snetBastion  'modules/subnet.module.bicep' = if (!empty(snetBastionCIDR)) {
  name: 'BastionSubnetDeployment'
  params: {
    addressPrefix: snetBastionCIDR
    name: snetBastionName
    virtualNetworkName: vnetName
    networkSecurityGroupId: nsgBastion.id
  }
}

module snetApimPortal 'modules/subnet.module.bicep' = if (!empty(snetApimPortalCIDR)) {
  name: 'snetApimPortalDeployment'
  params: {
    addressPrefix: snetApimPortalCIDR
    name: snetApimPortalName
    virtualNetworkName: vnetName
  }
}

module snetPE 'modules/subnet.module.bicep' = if (!empty(snetPEsCIDR)) {
  name: 'snetPEDeployment'
  params: {
    addressPrefix: snetPEsCIDR
    name: snetPEName
    virtualNetworkName: vnetName
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

module snetWorkloads 'modules/subnet.module.bicep' = if (!empty(snetWorkloadsCIDR)) {
  name: 'snetWorkloadsDeployment'
  params: {
    addressPrefix: snetWorkloadsCIDR
    name: snetWorkloadsName
    virtualNetworkName: vnetName
  }
}

module snetVMs 'modules/subnet.module.bicep' = if (!empty(snetVMsCIDR)) {
  name: 'snetVMsDeployment'
  params: {
    addressPrefix: snetVMsCIDR
    name: snetVMsName
    virtualNetworkName: vnetName
    networkSecurityGroupId: nsgSnetVMs.id
  }
}

resource nsgSnetVMs 'Microsoft.Network/networkSecurityGroups@2020-06-01' = if (!empty(snetVMsCIDR)) {
  name: nsgSnetVMsName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
 
resource nsgWaf 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgWafName
  location: location
  properties: {
    securityRules: [     
      {
        name: 'HealthProbes'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_TLS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 111
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_AzureLoadBalancer'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAll'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 130
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nsgApim 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgApimName
  location: location
  tags: resourceTags
  properties: {
    securityRules: [
      {
        name: 'Client_communication_to_API_Management'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Secure_Client_communication_to_API_Management'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Management_endpoint_for_Azure_portal_and_Powershell'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'Dependency_on_Redis_Cache'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6381-6383'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'Dependency_to_sync_Rate_Limit_Inbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '4290'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 135
          direction: 'Inbound'
        }
      }
      {
        name: 'Dependency_on_Azure_SQL'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
      {
        name: 'Dependency_for_Log_to_event_Hub_policy'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '5671'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'EventHub'
          access: 'Allow'
          priority: 150
          direction: 'Outbound'
        }
      }
      {
        name: 'Dependency_on_Redis_Cache_outbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6381-6383'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 160
          direction: 'Outbound'
        }
      }
      {
        name: 'Depenedency_To_sync_RateLimit_Outbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '4290'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 165
          direction: 'Outbound'
        }
      }
      {
        name: 'Dependency_on_Azure_File_Share_for_GIT'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 170
          direction: 'Outbound'
        }
      }
      {
        name: 'Azure_Infrastructure_Load_Balancer'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6390'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 180
          direction: 'Inbound'
        }
      }
      {
        name: 'Publish_DiagnosticLogs_And_Metrics'
        properties: {
          description: 'APIM Logs and Metrics for consumption by admins and your IT team are all part of the management plane'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 185
          direction: 'Outbound'
          destinationPortRanges: [
            '443'
            '12000'
            '1886'
          ]
        }
      }
      {
        name: 'Connect_To_SMTP_Relay_For_SendingEmails'
        properties: {
          description: 'APIM features the ability to generate email traffic as part of the data plane and the management plane'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 190
          direction: 'Outbound'
          destinationPortRanges: [
            '25'
            '587'
            '25028'
          ]
        }
      }
      {
        name: 'Authenticate_To_Azure_Active_Directory'
        properties: {
          description: 'Connect to Azure Active Directory for Developer Portal Authentication or for Oauth2 flow during any Proxy Authentication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'Dependency_on_Azure_Storage'
        properties: {
          description: 'APIM service dependency on Azure Blob and Azure Table Storage'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Publish_Monitoring_Logs'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 300
          direction: 'Outbound'
        }
      }
      {
        name: 'Access_KeyVault'
        properties: {
          description: 'Allow APIM service control plane access to KeyVault to refresh secrets'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault'
          access: 'Allow'
          priority: 350
          direction: 'Outbound'
          destinationPortRanges: [
            '443'
          ]
        }
      }
      {
        name: 'Deny_All_Internet_Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 999
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource nsgBastion 'Microsoft.Network/networkSecurityGroups@2020-06-01' = if (!empty(snetBastionCIDR)) {
  name: nsgBastionName
  location: location
  properties: {
    securityRules: [

        {
          name: 'AllowHttpsInbound'
          properties: {
            priority: 120
            protocol: 'Tcp'
            destinationPortRange: '443'
            access: 'Allow'
            direction: 'Inbound'
            sourcePortRange: '*'
            sourceAddressPrefix: 'Internet'
            destinationAddressPrefix: '*'
          }              
        }
        {
          name: 'AllowGatewayManagerInbound'
          properties: {
            priority: 130
            protocol: 'Tcp'
            destinationPortRange: '443'
            access: 'Allow'
            direction: 'Inbound'
            sourcePortRange: '*'
            sourceAddressPrefix: 'GatewayManager'
            destinationAddressPrefix: '*'
          }              
        }
        {
            name: 'AllowAzureLoadBalancerInbound'
            properties: {
              priority: 140
              protocol: 'Tcp'
              destinationPortRange: '443'
              access: 'Allow'
              direction: 'Inbound'
              sourcePortRange: '*'
              sourceAddressPrefix: 'AzureLoadBalancer'
              destinationAddressPrefix: '*'
            }         
          }     
          {
              name: 'AllowBastionHostCommunicationInbound'
              properties: {
                priority: 150
                protocol: '*'
                destinationPortRanges:[
                  '8080'
                  '5701'                
                ] 
                access: 'Allow'
                direction: 'Inbound'
                sourcePortRange: '*'
                sourceAddressPrefix: 'VirtualNetwork'
                destinationAddressPrefix: 'VirtualNetwork'
              }              
          }                    
          {
            name: 'DenyAllInbound'
            properties: {
              priority: 4096
              protocol: '*'
              destinationPortRange:'*'
              access: 'Deny'
              direction: 'Inbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: '*'
            }             
          } 
          {
            name: 'AllowSshRdpOutbound'
            properties: {
              priority: 100
              protocol: '*'
              destinationPortRanges:[
                '22'
                '3389'
              ]
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: 'VirtualNetwork'
            }              
          }       
          {
            name: 'AllowAzureCloudOutbound'
            properties: {
              priority: 110
              protocol: 'Tcp'
              destinationPortRange:'443'              
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: 'AzureCloud'
            }              
          }                                                         
          {
            name: 'AllowBastionCommunication'
            properties: {
              priority: 120
              protocol: '*'
              destinationPortRanges: [  
                '8080'
                '5701'
              ]
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: 'VirtualNetwork'
              destinationAddressPrefix: 'VirtualNetwork'
            }              
          }                     
          {
            name: 'AllowGetSessionInformation'
            properties: {
              priority: 130
              protocol: '*'
              destinationPortRange: '80'
              access: 'Allow'
              direction: 'Outbound'
              sourcePortRange: '*'
              sourceAddressPrefix: '*'
              destinationAddressPrefix: 'Internet'
            }              
          }                                                                   
    ]
  }
}

@description('The resource group the virtual network subnet was deployed into')
output resourceGroupName string = resourceGroup().name

@description('The name of the virtual network subnet snetWAF')
output snetWAFname string = snetWAF.name
@description('The resource ID of the virtual network subnet snetWAF')
output snetWAFResourceId string = snetWAF.outputs.resourceId
@description('The address prefix for the subnet snetWAF')
output snetWAFAddressPrefix string = snetWAF.outputs.subnetAddressPrefix

@description('The name of the virtual network subnet snetApim')
output snetApimName string = snetApim.name
@description('The resource ID of the virtual network subnet snetApim')
output snetApimResourceId string = snetApim.outputs.resourceId
@description('The naddress prefix for the subnet snetApim')
output snetApimAddressPrefix string = snetApim.outputs.subnetAddressPrefix

@description('The name of the virtual network subnet snetBastion')
output snetBastionName string =   !empty(snetBastionCIDR) ? snetBastion.name : ''
@description('The resource ID of the virtual network subnet snetBastion')
output snetBastionResourceId string = !empty(snetBastionCIDR) ? snetBastion.outputs.resourceId : ''
@description('The address prefix for the subnet snetBastion')
output snetBastionAddressPrefix string = !empty(snetBastionCIDR) ? snetBastion.outputs.subnetAddressPrefix : ''

@description('The name of the virtual network subnet snetApimPortal')
output snetApimPortalName string =   !empty(snetApimPortalCIDR) ? snetApimPortal.name : ''
@description('The resource ID of the virtual network subnet snetApimPortal')
output snetApimPortalResourceId string = !empty(snetApimPortalCIDR) ? snetApimPortal.outputs.resourceId : ''
@description('The address prefix for the subnet snetApimPortal')
output snetApimPortalAddressPrefix string = !empty(snetApimPortalCIDR) ? snetApimPortal.outputs.subnetAddressPrefix : ''


@description('The name of the virtual network subnet snetPE')
output snetPEName string =   !empty(snetPEsCIDR) ? snetPE.name : ''
@description('The resource ID of the virtual network subnet snetPE')
output snetPEResourceId string = !empty(snetPEsCIDR) ? snetPE.outputs.resourceId : ''
@description('The address prefix for the subnet snetPE')
output snetPEAddressPrefix string = !empty(snetPEsCIDR) ? snetPE.outputs.subnetAddressPrefix : ''



@description('The name of the virtual network subnet snetWorkloads')
output snetWorkloadsName string =   !empty(snetWorkloadsCIDR) ? snetWorkloads.name : ''
@description('The resource ID of the virtual network subnet snetWorkloads')
output snetWorkloadsResourceId string = !empty(snetWorkloadsCIDR) ? snetWorkloads.outputs.resourceId : ''
@description('The address prefix for the subnet snetWorkloads')
output snetWorkloadsAddressPrefix string = !empty(snetWorkloadsCIDR) ? snetWorkloads.outputs.subnetAddressPrefix : ''


@description('The name of the virtual network subnet snetVMs')
output snetVMsName string =   !empty(snetVMsCIDR) ? snetVMs.name : ''
@description('The resource ID of the virtual network subnet snetVMs')
output snetVMsResourceId string = !empty(snetVMsCIDR) ? snetVMs.outputs.resourceId : ''
@description('The address prefix for the subnet snetVMs')
output snetVMsAddressPrefix string = !empty(snetVMsCIDR) ? snetVMs.outputs.subnetAddressPrefix : ''

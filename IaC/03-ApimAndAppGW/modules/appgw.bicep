param location string
param tags object

@description('The name of the Application Gateawy to be created.')
param appGatewayName string

@description('The FQDN of the Application Gateawy.Must match the TLS Certificate.')
param appGatewayFQDN string

@description('The subnet resource id to use for Application Gateway.')
param appGatewaySubnetId string

@description('The backend URL of the APIM.')
param primaryBackendEndFQDN string

@description('The Url for the Application Gateway Apim Health Probe.')
param probeUrl string = '/status-0123456789abcdef'

@description('the name of the self signed certificate in key vault (i.e. appgw-theolabs-gr)')
param secretName string

param keyvaultAppGWCertName string
param keyvaultAppGWCertRG string

var appGatewayPrimaryPip = 'pip-${appGatewayName}'
var appGatewayIdentityId = 'identity-${appGatewayName}'

resource appGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name:     appGatewayIdentityId
  location: location
}


resource keyvaultAppGw 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyvaultAppGWCertName
  scope: resourceGroup(keyvaultAppGWCertRG) 
}


resource accessPolicyGrant 'Microsoft.KeyVault/vaults/accessPolicies@2021-10-01' = {
  name: '${keyvaultAppGw.name}/add'
  properties: {
    accessPolicies: [
      {
        objectId: appGatewayIdentity.properties.principalId
        tenantId: appGatewayIdentity.properties.tenantId
        permissions: {
          secrets: [ 
            'get' 
            'list'
          ]
          certificates: [
            'import'
            'get'
            'list'
            'update'
            'create'
          ]
        }                  
      }
    ]
  }
}

resource keyVaultCertificate 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' existing = {
  name: '${keyvaultAppGw.name}/${secretName}'
}

resource appGatewayPublicIPAddress 'Microsoft.Network/publicIPAddresses@2019-09-01' = {
  name: appGatewayPrimaryPip
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource appGatewayName_resource 'Microsoft.Network/applicationGateways@2019-09-01' = {
  name: appGatewayName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGatewayIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnetId
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: appGatewayFQDN
        properties: {
          keyVaultSecretId:  keyVaultCertificate.properties.secretUriWithVersion
        }
      }
    ]
    trustedRootCertificates: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGatewayPublicIPAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apim'
        properties: {
          backendAddresses: [
            {
              fqdn: primaryBackendEndFQDN
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'default'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 20
        }
      }
      {
        name: 'https'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          hostName: primaryBackendEndFQDN
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/probes/APIM'
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'default'
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/frontendIPConfigurations/appGwPublicFrontendIp'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/frontendPorts/port_80'
          }
          protocol: 'Http'
          hostnames: []
          requireServerNameIndication: false
        }
      }
      {
        name: 'https'
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/frontendIPConfigurations/appGwPublicFrontendIp'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/frontendPorts/port_443'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/sslCertificates/${appGatewayFQDN}'
          }
          hostnames: []
          requireServerNameIndication: false
        }
      }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'apim'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/httpListeners/https'
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/backendAddressPools/apim'
          }
          backendHttpSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/backendHttpSettingsCollection/https'
          }
        }
      }
    ]
    probes: [
      {
        name: 'APIM'
        properties: {
          protocol: 'Https'
          host: primaryBackendEndFQDN
          path: probeUrl
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: []
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.0'
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 3
    }
  }
}

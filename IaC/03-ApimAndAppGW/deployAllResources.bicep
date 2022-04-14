// that's the default, but put it here for completeness
targetScope = 'resourceGroup'

// PARAMS
param resourceTags object
param location string = resourceGroup().location
param appName string
param region string
param snetApimId string
param snetAppGwId string
param keyvaultAppGWCertName string
param keyvaultAppGWCertRG string

@description('the name of the self signed certificate in key vault (i.e. appgw-theolabs-gr MUST be the same as the one created in AddSelfSignedCertificate.ps1)')
param certificateName string

@description('The name of the owner of the service')
@minLength(1)
param organizationName string

@description('The email address of the owner of the service')
@minLength(1)
param organizationEmail string

@description('the name of the VNet where Apim is deployed on')
param vnetName string

@description('the name of the Resource Group holding VNet where Apim is deployed on')
param vnetRGName string

@description('The FQDN of the appGW')
param appGatewayFQDN string




//VARS
var env = resourceTags.Environment

//var resource names
var apimName = 'apim-${appName}-${region}-${env}'
var appInsightsApimName = 'appi-${apimName}'
var logAnalyticsApimWsName = 'log-${apimName}'
//var keyVaultName = 'kv-${appName}-${region}-${env}'
var pipApimName = 'pip-${appName}-${region}-${env}'
var appGwName = 'agw-${appName}-${region}-${env}'


//Create Resources
module appInsightsApim 'modules/appInsghts.module.bicep' = {
  name: 'appInsghtsDeployment'
  params: {
    name: appInsightsApimName
    location: location
    tags: resourceTags
    workspaceName: logAnalyticsApimWsName
  }
}

module apimPip 'modules/pip.module.bicep' = {
  name: 'apimPipDeployment'
  params: {
    location: location
    name: pipApimName
    tags: resourceTags
  }
}

module apim 'modules/apim.module.bicep' = {
  name: 'apim-deployment'
  params: {
    name: apimName
    pipStandardId: apimPip.outputs.id
    location: location
    virtualNetworkType: 'Internal'
    tags: resourceTags
    organizationEmail: organizationEmail
    organizationName: organizationName
    snetAPIMId: snetApimId     
    appInsightsId: appInsightsApim.outputs.id
    appInsightsInstrumentationKey: appInsightsApim.outputs.instrumentationKey
    logAnalyticsWsId: appInsightsApim.outputs.logAnalyticsWsId
  }
}

module apimDnsZones 'modules/apimdnszones.bicep' = {
  name: 'apimDnsZoneDeployment'
  dependsOn: [
    apim
  ]
  params: {
    apimName: apimName
    apimRG: resourceGroup().name
    vnetName: vnetName
    vnetRG: vnetRGName
  }
}

module appGw 'modules/appgw.bicep' = {
  name: 'appGWDeployment'
  dependsOn: [
    apim
    apimDnsZones
  ]
  params: {
    appGatewayFQDN: appGatewayFQDN
    appGatewayName: appGwName
    appGatewaySubnetId: snetAppGwId
    keyvaultAppGWCertName: keyvaultAppGWCertName
    keyvaultAppGWCertRG: keyvaultAppGWCertRG
    location: location
    primaryBackendEndFQDN: '${apimName}.azure-api.net'
    secretName: certificateName
    tags: resourceTags
  }
}

// module keyVault 'modules/keyvault.module.bicep' = {
//   name: 'keyvaultDeployment'
//   params: {
//     name: keyVaultName
//     tags: resourceTags
//     location: location
//   }
// }


output appName string = appName

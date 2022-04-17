// that's the default, but put it here for completeness
targetScope = 'resourceGroup'

// PARAMS
param resourceTags object
param location string = resourceGroup().location
param appName string
param region string
param snetApimId string
param snetAppGwId string
param snetPEId string
param snetApimPortalId string
param keyvaultAppGWCertName string
param keyvaultAppGWCertRG string
param jumpBoxUserName string
param jumpBoxUserSnetId string
param sqlServerUserName string


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

@description('Password of the admin user for the vmJumpbox')
@secure()
param vmJumpBoxPassword string

@description('Password of the dbadmin user for the Azure SQL')
@secure()
param sqlServerPassword string




//VARS
var env = resourceTags.Environment

//var resource names
var apimName = 'apim-${appName}-${region}-${env}'
var appInsightsApimName = 'appi-${apimName}'

var logAnalyticsApimWsName = 'log-${apimName}'
//var keyVaultName = 'kv-${appName}-${region}-${env}'
var pipApimName = 'pip-${appName}-${region}-${env}'
var appGwName = 'agw-${appName}-${region}-${env}'
var vmname = 'vmJumpBoxApim'
var sqlServerName = 'sql-${appName}-${region}-${env}'
var sqlDBName = 'sqldb-apim-portal-${region}-${env}'
var apimPortalWebAppName = 'app-apim-portal-${region}-${env}'
var apimPortalPlanName = 'plan-apim-portal-${region}-${env}'
var appInsightsApimPortalName = 'appi-${apimPortalPlanName}'
var evtHubNamespace = 'evhns-${appName}-${region}-${env}'
var eventHubName = 'evh-${appName}-${region}-${env}'
var evtHubconsumerGroupName = 'cg-${eventHubName}'
var streamAnalyticsJobName = 'asa-${appName}-${region}-${env}'



resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetRGName)
}

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

// this is only needed for premium sku. if you force public IP to developer SKU, then developer APIM is suppored to be stv2 (vs stv1) and this seems not to work correclty (API Echo api calls get 500 error)
// "A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond 138.91.191.195:80"
// module apimPip 'modules/pip.module.bicep' = {
//   name: 'apimPipDeployment'
//   params: {
//     location: location
//     name: pipApimName
//     tags: resourceTags
//   }
// }

module apim 'modules/apim.module.bicep' = {
  name: 'apim-deployment'
  params: {
    name: apimName
    // pipStandardId: apimPip.outputs.id
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

module jumpBoxVM 'modules/vmWin.module.bicep' = if (!empty(jumpBoxUserSnetId)) {
  name: 'jumpBoxVMDeployment'
  params: {
    location: location
    password: vmJumpBoxPassword
    subnetId: jumpBoxUserSnetId
    tags: resourceTags
    username: jumpBoxUserName
    vmName: vmname
  }
}

// module sqlServer 'modules/sqlServer.module.bicep' = {
//   name: 'sqlServerDeployment'
//   params: {
//     name: sqlServerName
//     tags: resourceTags
//     administratorLogin: sqlServerUserName
//     administratorLoginPassword: sqlServerPassword
//     databaseName: sqlDBName
//     location: location
//   }
// }

// module sqlServerPrivateDnsZone 'modules/privateDnsZone.module.bicep'={
//   name: 'sqlServerPrivateDnsZoneDeployment'
//   params: {
//     name: 'privatelink${environment().suffixes.sqlServerHostname}'
//     vnetIds: [
//       vnet.id
//     ] 
//   }
// }

// module sqlServerPrivateEndpoint 'modules/privateEndpoint.module.bicep' = {
//   name: 'sqlServerPrivateEndpointDeployment'
//   params: {
//     name: 'pe-${sqlServerName}'
//     location: location
//     tags: resourceTags
//     privateDnsZoneId: sqlServerPrivateDnsZone.outputs.id
//     privateLinkServiceId: sqlServer.outputs.id
//     subnetId: snetPEId
//     subResource: 'sqlServer'
//   }  
// }

module appInsightsApimPortal 'modules/appInsghts.module.bicep' = {
  name: 'appInsghtsApimPortalDeployment'
  params: {
    name: appInsightsApimPortalName
    location: location
    tags: resourceTags
    workspaceName: logAnalyticsApimWsName
  }
}

module apimPortalWebApp 'modules/webApp.module.bicep' = {
  name: 'backendWebAppDeployment'
  params: {
    name: apimPortalWebAppName
    planName: apimPortalPlanName
    location: location
    tags: resourceTags    
    subnetIdForIntegration: snetApimPortalId
    managedIdentity: true
    appInsightsInstrumentationKey: appInsightsApimPortal.outputs.instrumentationKey
    appSettings: [
      // {
      //   name: 'StorageConnection'
      //   value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.dataStorageConnectionString})'
      // }
      // {
      //   name: 'SqlDbConnection'
      //   value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.sqlConnectionString})'
      // }
      // {
      //   name: 'RedisConnection'
      //   value: '@Microsoft.KeyVault(VaultName=${resourceNames.keyVault};SecretName=${secretNames.redisConnectionString})'
      // }
    ]
  }
}

module websitesPrivateDnsZone 'modules/privateDnsZone.module.bicep'={
  name: 'websitesPrivateDnsZoneDeployment'
  params: {
    name: 'privatelink.azurewebsites.net'
    vnetIds: [
      vnet.id
    ] 
  }
}

module apimPortalPE 'modules/privateEndpoint.module.bicep' = {
  name: 'apimPortalPEDeployment'
  params: {
    name: 'pe-${apimPortalWebAppName}'
    location: location
    tags: resourceTags    
    privateDnsZoneId: websitesPrivateDnsZone.outputs.id
    privateLinkServiceId: apimPortalWebApp.outputs.id
    subnetId: snetPEId
    subResource: 'sites'
  }  
}


module eventHub 'modules/eventHub.module.bicep' = {
  name: 'eventHubDeployment'
  params: {
    consumerGroupName: evtHubconsumerGroupName
    eventHubName: eventHubName
    location: location
    namespaceName: evtHubNamespace
    tags: resourceTags
  }
}

module streamAnalyticsJob 'modules/streamAnalyticsJob.module.bicep' = {
  name: 'streamAnalyticsJob'
  params: {
    location: location
    name: streamAnalyticsJobName
    tags: resourceTags
    numberOfStreamingUnits: 1
  }
}


output appName string = appName

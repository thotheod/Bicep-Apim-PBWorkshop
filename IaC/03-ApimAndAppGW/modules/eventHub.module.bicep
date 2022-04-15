param namespaceName string
param location string
param tags object
param eventHubName string
param consumerGroupName string

@allowed([
  'Standard'
  'Basic'
])
param eventHubSku string = 'Standard'

@allowed([
  1
  2
  4
])
param skuCapacity int = 1

resource namespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: namespaceName
  tags: tags
  location: location
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: skuCapacity
  }
  properties: {}
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  name: '${namespace.name}/${eventHubName}'
  properties: {}
}

resource consumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-11-01' = {
  name: '${eventHub.name}/${consumerGroupName}'
  properties: {}
}

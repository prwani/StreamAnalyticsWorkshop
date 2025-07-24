// Azure Stream Analytics Workshop - Infrastructure Template
// This template deploys all required Azure resources for the workshop

@description('Location for all resources')
param location string = resourceGroup().location

@description('Unique suffix for resource names')
param uniqueSuffix string = uniqueString(resourceGroup().id)

@description('SQL Server administrator login')
param sqlAdminLogin string = 'sqladmin'

@description('SQL Server administrator password')
@secure()
param sqlAdminPassword string

@description('Event Hub namespace SKU')
@allowed(['Basic', 'Standard'])
param eventhubSku string = 'Standard'

@description('IoT Hub SKU')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3'])
param iotHubSku string = 'S1'

// Variables
var storageAccountName = 'sastore${uniqueSuffix}'
var eventhubNamespaceName = 'eventhub-sa-workshop-${uniqueSuffix}'
var iotHubName = 'iothub-sa-workshop-${uniqueSuffix}'
var sqlServerName = 'sqlserver-sa-workshop-${uniqueSuffix}'
var streamAnalyticsJobName = 'asa-telemetry-processing'
var sqlDatabaseName = 'StreamAnalyticsDB'

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    networkAcls: {
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
  }
}

// Storage Container for outputs
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource outputContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'output'
  properties: {
    publicAccess: 'None'
  }
}

// Event Hub Namespace
resource eventhubNamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' = {
  name: eventhubNamespaceName
  location: location
  sku: {
    name: eventhubSku
    tier: eventhubSku
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    kafkaEnabled: true
  }
}

// Event Hub
resource eventhub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  parent: eventhubNamespace
  name: 'telemetry-data'
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
    status: 'Active'
  }
}

// Event Hub Consumer Group for Stream Analytics
resource eventhubConsumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2023-01-01-preview' = {
  parent: eventhub
  name: 'streamanalytics'
  properties: {}
}

// IoT Hub
resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' = {
  name: iotHubName
  location: location
  sku: {
    name: iotHubSku
    capacity: 1
  }
  properties: {
    routing: {
      endpoints: {
        eventhubs: [
          {
            name: 'telemetry-endpoint'
            connectionString: 'Endpoint=${eventhubNamespace.listKeys().primaryConnectionString};EntityPath=telemetry-data'
            subscriptionId: subscription().subscriptionId
            resourceGroup: resourceGroup().name
          }
        ]
      }
      routes: [
        {
          name: 'telemetry-route'
          source: 'DeviceMessages'
          condition: 'true'
          endpointNames: [
            'telemetry-endpoint'
          ]
          isEnabled: true
        }
      ]
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    }
    messagingEndpoints: {
      fileNotifications: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    enableFileUploadNotifications: false
    cloudToDevice: {
      maxDeliveryCount: 10
      defaultTtlAsIso8601: 'PT1H'
      feedback: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    features: 'None'
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-02-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-02-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 104857600
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
    isLedgerOn: false
  }
}

// SQL Server Firewall Rule - Allow Azure Services
resource sqlFirewallRuleAzure 'Microsoft.Sql/servers/firewallRules@2023-02-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Stream Analytics Job
resource streamAnalyticsJob 'Microsoft.StreamAnalytics/streamingjobs@2021-10-01-preview' = {
  name: streamAnalyticsJobName
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
    outputErrorPolicy: 'Drop'
    eventsOutOfOrderPolicy: 'Adjust'
    eventsOutOfOrderMaxDelayInSeconds: 5
    eventsLateArrivalMaxDelayInSeconds: 5
    dataLocale: 'en-US'
    compatibilityLevel: '1.2'
    contentStoragePolicy: 'SystemAccount'
    jobType: 'Cloud'
  }
}

// Outputs for connection strings and important information
output resourceGroupName string = resourceGroup().name
output storageAccountName string = storageAccount.name
output storageAccountConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
output eventhubNamespaceName string = eventhubNamespace.name
output eventhubConnectionString string = eventhubNamespace.listKeys().primaryConnectionString
output iotHubName string = iotHub.name
output iotHubConnectionString string = 'HostName=${iotHub.properties.hostName};SharedAccessKeyName=iothubowner;SharedAccessKey=${iotHub.listKeys().value[0].primaryKey}'
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
output sqlConnectionString string = 'Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDatabase.name};User Id=${sqlAdminLogin};Password=${sqlAdminPassword};Encrypt=true;Connection Timeout=30;'
output streamAnalyticsJobName string = streamAnalyticsJob.name

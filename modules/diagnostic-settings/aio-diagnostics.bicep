// ──────────────────────────────────────────────────────────
// Diagnostic Settings — Azure IoT Operations Components
// Routes security logs → Sentinel, operational telemetry → ITOps
// ──────────────────────────────────────────────────────────

@description('Sentinel workspace resource ID (security-relevant logs).')
param sentinelWorkspaceId string

@description('ITOps workspace resource ID (operational telemetry).')
param opsWorkspaceId string

@description('Name of the AIO MQTT Broker resource. Leave empty to skip.')
param mqttBrokerName string = ''

@description('Name of the AIO Data Processor resource. Leave empty to skip.')
param dataProcessorName string = ''

@description('Name of the OPC UA Connector resource. Leave empty to skip.')
param opcUaConnectorName string = ''

@description('Resource group containing the AIO resources.')
param aioResourceGroup string = resourceGroup().name

// ──────────────────────────────────────────────────────────
// AIO MQTT Broker — Diagnostic Settings
// Security logs (auth failures, connection events) → Sentinel
// Operational metrics (message throughput, latency) → ITOps
// ──────────────────────────────────────────────────────────

resource mqttBroker 'Microsoft.IoTOperationsMQ/mq@2023-10-04-preview' existing = if (!empty(mqttBrokerName)) {
  name: mqttBrokerName
}

resource mqttBrokerSecurityDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(mqttBrokerName)) {
  name: 'mqtt-broker-security-to-sentinel'
  scope: mqttBroker
  properties: {
    workspaceId: sentinelWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: false // Metrics go to ITOps, not Sentinel
      }
    ]
  }
}

resource mqttBrokerOpsDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(mqttBrokerName)) {
  name: 'mqtt-broker-ops-to-itops'
  scope: mqttBroker
  properties: {
    workspaceId: opsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: false // Security logs already go to Sentinel
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ──────────────────────────────────────────────────────────
// AIO Data Processor — Diagnostic Settings
// ──────────────────────────────────────────────────────────

resource dataProcessor 'Microsoft.IoTOperationsDataProcessor/instances@2023-10-04-preview' existing = if (!empty(dataProcessorName)) {
  name: dataProcessorName
}

resource dataProcessorSecurityDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(dataProcessorName)) {
  name: 'data-processor-security-to-sentinel'
  scope: dataProcessor
  properties: {
    workspaceId: sentinelWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource dataProcessorOpsDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(dataProcessorName)) {
  name: 'data-processor-ops-to-itops'
  scope: dataProcessor
  properties: {
    workspaceId: opsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ──────────────────────────────────────────────────────────
// OPC UA Connector — Diagnostic Settings
// ──────────────────────────────────────────────────────────

resource opcUaConnector 'Microsoft.IoTOperationsOrchestratorConnector/instances@2023-10-04-preview' existing = if (!empty(opcUaConnectorName)) {
  name: opcUaConnectorName
}

resource opcUaSecurityDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(opcUaConnectorName)) {
  name: 'opcua-connector-security-to-sentinel'
  scope: opcUaConnector
  properties: {
    workspaceId: sentinelWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource opcUaOpsDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(opcUaConnectorName)) {
  name: 'opcua-connector-ops-to-itops'
  scope: opcUaConnector
  properties: {
    workspaceId: opsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

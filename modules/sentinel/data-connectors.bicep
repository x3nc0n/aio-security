// ──────────────────────────────────────────────────────────
// Sentinel Data Connectors
// Microsoft 365 Defender + Azure Activity
// ──────────────────────────────────────────────────────────

@description('Sentinel workspace resource ID.')
param sentinelWorkspaceId string

// Extract workspace name from the resource ID
var workspaceName = last(split(sentinelWorkspaceId, '/'))

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workspaceName
}

// ──────────────────────────────────────────────────────────
// Microsoft 365 Defender (MDE) Connector
// Brings in DeviceProcessEvents, DeviceNetworkEvents,
// DeviceFileEvents from MDE-onboarded edge nodes
// ──────────────────────────────────────────────────────────

resource m365DefenderConnector 'Microsoft.SecurityInsights/dataConnectors@2024-03-01' = {
  name: 'microsoft-365-defender-connector'
  scope: workspace
  kind: 'MicrosoftThreatProtection'
  properties: {
    tenantId: subscription().tenantId
    dataTypes: {
      incidents: {
        connectionState: 'Enabled'
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Azure Activity Connector
// Control-plane operations from Azure Resource Manager
// ──────────────────────────────────────────────────────────

resource azureActivityConnector 'Microsoft.SecurityInsights/dataConnectors@2024-03-01' = {
  name: 'azure-activity-connector'
  scope: workspace
  kind: 'AzureActivity'
  properties: {
    connectorDefinitionName: 'AzureActivity'
    dataTypes: {
      azureActivity: {
        state: 'Enabled'
      }
    }
  }
}

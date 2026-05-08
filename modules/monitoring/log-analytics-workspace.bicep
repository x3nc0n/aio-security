// ──────────────────────────────────────────────────────────
// Log Analytics Workspace (optional)
// Deploy only if a workspace doesn't already exist
// ──────────────────────────────────────────────────────────

@description('Azure region for the workspace.')
param location string

@description('Name of the Log Analytics workspace.')
param workspaceName string

@description('Retention period in days.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 90

@description('SKU for the workspace.')
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param sku string = 'PerGB2018'

@description('Daily ingestion cap in GB. Set to -1 for no cap.')
param dailyQuotaGb int = -1

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: dailyQuotaGb > 0 ? {
      dailyQuotaGb: dailyQuotaGb
    } : null
  }
}

// Enable Sentinel on the workspace
resource sentinel 'Microsoft.SecurityInsights/onboardingStates@2024-03-01' = {
  name: 'default'
  scope: workspace
  properties: {}
}

output workspaceId string = workspace.id
output workspaceName string = workspace.name

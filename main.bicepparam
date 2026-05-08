using './main.bicep'

// ── Chevron AIO Edge-to-Cloud Security ──
// Update these values before deployment.

param location = 'eastus2'

param sentinelWorkspaceId = '/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RG_NAME>/providers/Microsoft.OperationalInsights/workspaces/<SENTINEL_WORKSPACE>'

param opsWorkspaceId = '/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RG_NAME>/providers/Microsoft.OperationalInsights/workspaces/<OPS_WORKSPACE>'

param assignmentScope = '/subscriptions/<SUBSCRIPTION_ID>'

param deployDiagnostics = true
param deployPolicies = true
param deployDataCollectionRules = true
param deploySentinelConnectors = true

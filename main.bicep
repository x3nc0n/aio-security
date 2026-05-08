// ──────────────────────────────────────────────────────────
// Azure IoT Operations — Edge-to-Cloud Security
// Orchestration template (entry point for Deploy to Azure)
// ──────────────────────────────────────────────────────────
targetScope = 'subscription'

// ── Parameters ──────────────────────────────────────────

@description('Azure region for deployed resources.')
param location string = 'eastus2'

@description('Resource ID of the Log Analytics workspace used by Microsoft Sentinel (security logs).')
param sentinelWorkspaceId string

@description('Resource ID of the Log Analytics workspace for IT-Ops / non-security operational telemetry.')
param opsWorkspaceId string

@description('Scope for policy assignments (subscription or management group resource ID).')
param assignmentScope string = subscription().id

@description('Deploy diagnostic settings modules.')
param deployDiagnostics bool = true

@description('Deploy Azure Policy assignment modules.')
param deployPolicies bool = true

@description('Deploy Data Collection Rule modules.')
param deployDataCollectionRules bool = true

@description('Deploy Sentinel data connector modules.')
param deploySentinelConnectors bool = true

// ── Resource Group ─────────────────────────────────────

resource securityRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-aio-security'
  location: location
}

// ── Diagnostic Settings ────────────────────────────────

module aioDiagnostics 'modules/diagnostic-settings/aio-diagnostics.bicep' = if (deployDiagnostics) {
  name: 'aio-diagnostics'
  scope: securityRg
  params: {
    sentinelWorkspaceId: sentinelWorkspaceId
    opsWorkspaceId: opsWorkspaceId
  }
}

module arcK8sDiagnostics 'modules/diagnostic-settings/arc-k8s-diagnostics.bicep' = if (deployDiagnostics) {
  name: 'arc-k8s-diagnostics'
  scope: securityRg
  params: {
    sentinelWorkspaceId: sentinelWorkspaceId
    opsWorkspaceId: opsWorkspaceId
  }
}

// ── Policy Assignments ─────────────────────────────────

module cisAzureFoundations 'modules/policy-assignments/cis-azure-foundations.bicep' = if (deployPolicies) {
  name: 'cis-azure-foundations'
  params: {
    assignmentScope: assignmentScope
  }
}

module cisKubernetes 'modules/policy-assignments/cis-kubernetes.bicep' = if (deployPolicies) {
  name: 'cis-kubernetes'
  params: {
    assignmentScope: assignmentScope
    location: location
  }
}

module aioCustomPolicies 'modules/policy-assignments/aio-custom-policies.bicep' = if (deployPolicies) {
  name: 'aio-custom-policies'
  params: {
    assignmentScope: assignmentScope
    location: location
    sentinelWorkspaceId: sentinelWorkspaceId
  }
}

// ── Data Collection Rules ──────────────────────────────

module syslogDcr 'modules/data-collection-rules/syslog-dcr.bicep' = if (deployDataCollectionRules) {
  name: 'syslog-dcr'
  scope: securityRg
  params: {
    location: location
    sentinelWorkspaceId: sentinelWorkspaceId
  }
}

module k8sDcr 'modules/data-collection-rules/k8s-dcr.bicep' = if (deployDataCollectionRules) {
  name: 'k8s-dcr'
  scope: securityRg
  params: {
    location: location
    sentinelWorkspaceId: sentinelWorkspaceId
  }
}

// ── Sentinel Data Connectors ───────────────────────────

module sentinelConnectors 'modules/sentinel/data-connectors.bicep' = if (deploySentinelConnectors) {
  name: 'sentinel-data-connectors'
  scope: securityRg
  params: {
    sentinelWorkspaceId: sentinelWorkspaceId
  }
}

// ── Outputs ────────────────────────────────────────────

output resourceGroupName string = securityRg.name
output sentinelWorkspace string = sentinelWorkspaceId
output opsWorkspace string = opsWorkspaceId

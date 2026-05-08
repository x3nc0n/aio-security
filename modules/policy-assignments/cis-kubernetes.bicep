// ──────────────────────────────────────────────────────────
// Policy Assignment — CIS Kubernetes Benchmark
// Uses Defender for Containers + Azure Policy for K8s
// ──────────────────────────────────────────────────────────
targetScope = 'subscription'

@description('Scope for the policy assignment (subscription or management group ID).')
param assignmentScope string = subscription().id

@description('Azure region for the managed identity (required for DeployIfNotExists remediation).')
param location string

@description('Enforcement mode: Default (enforce) or DoNotEnforce (audit only).')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

// Kubernetes cluster pod security baseline standards for Linux-based workloads
var k8sBaselinePolicySetId = '/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d'

resource cisK8sAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'cis-kubernetes-benchmark'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Kubernetes Cluster Pod Security Baseline'
    description: 'Enforces pod security baseline standards on Kubernetes clusters including Arc-enabled K8s running Azure IoT Operations workloads.'
    policyDefinitionId: k8sBaselinePolicySetId
    enforcementMode: enforcementMode
    parameters: {
      effect: {
        value: 'Audit'
      }
    }
    nonComplianceMessages: [
      {
        message: 'This Kubernetes resource does not meet pod security baseline requirements. See CIS Kubernetes Benchmark controls.'
      }
    ]
  }
}

// Azure Policy Add-on for Arc-enabled Kubernetes
var azurePolicyAddonId = '/providers/Microsoft.Authorization/policyDefinitions/0adc5395-9169-4b9b-8687-af838d69410a'

resource k8sPolicyAddon 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'k8s-azure-policy-addon'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Azure Policy Add-on for Kubernetes'
    description: 'Ensures the Azure Policy add-on is deployed on Arc-enabled Kubernetes clusters to enable policy enforcement.'
    policyDefinitionId: azurePolicyAddonId
    enforcementMode: enforcementMode
    parameters: {
      effect: {
        value: 'DeployIfNotExists'
      }
    }
  }
}

output baselineAssignmentId string = cisK8sAssignment.id
output policyAddonAssignmentId string = k8sPolicyAddon.id

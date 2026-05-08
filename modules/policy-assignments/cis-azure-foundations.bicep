// ──────────────────────────────────────────────────────────
// Policy Assignment — CIS Microsoft Azure Foundations v2.0
// Built-in initiative for Azure infrastructure hardening
// ──────────────────────────────────────────────────────────
targetScope = 'subscription'

@description('Scope for the policy assignment (subscription or management group ID).')
param assignmentScope string = subscription().id

@description('Enforcement mode: Default (enforce) or DoNotEnforce (audit only).')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

// CIS Microsoft Azure Foundations Benchmark v2.0.0
var cisAzurePolicySetId = '/providers/Microsoft.Authorization/policySetDefinitions/06f19060-9e68-4070-92ca-f15cc126059e'

resource cisAzureAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'cis-azure-foundations-v2'
  properties: {
    displayName: 'CIS Microsoft Azure Foundations Benchmark v2.0.0'
    description: 'Assigns the CIS Microsoft Azure Foundations Benchmark v2.0.0 initiative to evaluate compliance of Azure resources against industry-standard security controls.'
    policyDefinitionId: cisAzurePolicySetId
    enforcementMode: enforcementMode
    parameters: {}
    nonComplianceMessages: [
      {
        message: 'This resource does not comply with CIS Microsoft Azure Foundations Benchmark v2.0. Review the recommendation in Microsoft Defender for Cloud.'
      }
    ]
  }
}

output assignmentId string = cisAzureAssignment.id
output assignmentName string = cisAzureAssignment.name

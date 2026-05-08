// ──────────────────────────────────────────────────────────
// Custom AIO Policies
// DeployIfNotExists: diagnostic settings on AIO resources
// Audit: TLS enforcement on MQTT Broker
// Audit: MQTT authentication enabled
// ──────────────────────────────────────────────────────────
targetScope = 'subscription'

@description('Scope for the policy assignment.')
param assignmentScope string = subscription().id

@description('Azure region for the managed identity.')
param location string

@description('Sentinel workspace ID for diagnostic settings enforcement.')
param sentinelWorkspaceId string

// ──────────────────────────────────────────────────────────
// Policy 1: DeployIfNotExists — Require diagnostic settings
// on AIO resources (MQTT Broker, Data Processor, OPC UA)
// ──────────────────────────────────────────────────────────

resource diagPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2024-05-01' = {
  name: 'aio-require-diagnostic-settings'
  properties: {
    displayName: 'AIO: Require diagnostic settings on IoT Operations resources'
    description: 'Deploys diagnostic settings to route all logs to a Log Analytics workspace when an AIO resource is created or updated without them.'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'IoT Operations'
      version: '1.0.0'
    }
    parameters: {
      workspaceId: {
        type: 'String'
        metadata: {
          displayName: 'Log Analytics Workspace ID'
          description: 'Resource ID of the Log Analytics workspace for diagnostic logs.'
        }
      }
      effect: {
        type: 'String'
        defaultValue: 'DeployIfNotExists'
        allowedValues: [
          'DeployIfNotExists'
          'Disabled'
        ]
        metadata: {
          displayName: 'Effect'
        }
      }
    }
    policyRule: {
      if: {
        field: 'type'
        in: [
          'Microsoft.IoTOperationsMQ/mq'
          'Microsoft.IoTOperationsDataProcessor/instances'
          'Microsoft.IoTOperationsOrchestratorConnector/instances'
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
        details: {
          type: 'Microsoft.Insights/diagnosticSettings'
          existenceCondition: {
            allOf: [
              {
                field: 'Microsoft.Insights/diagnosticSettings/logs.enabled'
                equals: 'true'
              }
              {
                field: 'Microsoft.Insights/diagnosticSettings/workspaceId'
                equals: '[parameters(\'workspaceId\')]'
              }
            ]
          }
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa' // Monitoring Contributor
            '/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293' // Log Analytics Contributor
          ]
          deployment: {
            properties: {
              mode: 'incremental'
              template: {
                '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
                contentVersion: '1.0.0.0'
                parameters: {
                  resourceName: { type: 'string' }
                  workspaceId: { type: 'string' }
                }
                resources: [
                  {
                    type: 'Microsoft.Insights/diagnosticSettings'
                    apiVersion: '2021-05-01-preview'
                    name: 'aio-security-diag'
                    scope: '[concat(\'Microsoft.IoTOperationsMQ/mq/\', parameters(\'resourceName\'))]'
                    properties: {
                      workspaceId: '[parameters(\'workspaceId\')]'
                      logs: [
                        {
                          categoryGroup: 'allLogs'
                          enabled: true
                        }
                      ]
                    }
                  }
                ]
              }
              parameters: {
                resourceName: { value: '[field(\'name\')]' }
                workspaceId: { value: '[parameters(\'workspaceId\')]' }
              }
            }
          }
        }
      }
    }
  }
}

resource diagPolicyAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'aio-enforce-diagnostics'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'AIO: Enforce diagnostic settings on IoT Operations resources'
    description: 'Automatically deploys diagnostic settings on AIO resources to ensure security log visibility.'
    policyDefinitionId: diagPolicyDefinition.id
    enforcementMode: 'Default'
    parameters: {
      workspaceId: {
        value: sentinelWorkspaceId
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Policy 2: Audit — TLS enforcement on MQTT Broker
// ──────────────────────────────────────────────────────────

resource tlsPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2024-05-01' = {
  name: 'aio-audit-mqtt-tls'
  properties: {
    displayName: 'AIO: Audit MQTT Broker TLS enforcement'
    description: 'Audits Azure IoT Operations MQTT Broker instances to ensure TLS is enabled for all listener ports.'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'IoT Operations'
      version: '1.0.0'
    }
    parameters: {
      effect: {
        type: 'String'
        defaultValue: 'Audit'
        allowedValues: [
          'Audit'
          'Disabled'
        ]
        metadata: {
          displayName: 'Effect'
        }
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.IoTOperationsMQ/mq/broker/listener'
          }
          {
            field: 'Microsoft.IoTOperationsMQ/mq/broker/listener/tls'
            exists: 'false'
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

resource tlsPolicyAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'aio-audit-mqtt-tls'
  properties: {
    displayName: 'AIO: Audit MQTT Broker TLS enforcement'
    description: 'Identifies MQTT Broker listeners that do not have TLS enabled.'
    policyDefinitionId: tlsPolicyDefinition.id
    enforcementMode: 'Default'
    parameters: {}
  }
}

// ──────────────────────────────────────────────────────────
// Policy 3: Audit — MQTT authentication enabled
// ──────────────────────────────────────────────────────────

resource authPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2024-05-01' = {
  name: 'aio-audit-mqtt-auth'
  properties: {
    displayName: 'AIO: Audit MQTT Broker authentication enabled'
    description: 'Audits Azure IoT Operations MQTT Broker instances to ensure authentication is configured and not set to anonymous.'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'IoT Operations'
      version: '1.0.0'
    }
    parameters: {
      effect: {
        type: 'String'
        defaultValue: 'Audit'
        allowedValues: [
          'Audit'
          'Disabled'
        ]
        metadata: {
          displayName: 'Effect'
        }
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.IoTOperationsMQ/mq/broker/authentication'
          }
          {
            anyOf: [
              {
                field: 'Microsoft.IoTOperationsMQ/mq/broker/authentication/authenticationMethods'
                exists: 'false'
              }
            ]
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

resource authPolicyAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'aio-audit-mqtt-auth'
  properties: {
    displayName: 'AIO: Audit MQTT Broker authentication enabled'
    description: 'Identifies MQTT Broker instances without authentication configured.'
    policyDefinitionId: authPolicyDefinition.id
    enforcementMode: 'Default'
    parameters: {}
  }
}

output diagPolicyId string = diagPolicyDefinition.id
output tlsPolicyId string = tlsPolicyDefinition.id
output authPolicyId string = authPolicyDefinition.id

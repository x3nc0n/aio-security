// ──────────────────────────────────────────────────────────
// Data Collection Rule — Kubernetes Container Insights
// Collects container logs and K8s events for Sentinel
// ──────────────────────────────────────────────────────────

@description('Azure region for the DCR.')
param location string

@description('Sentinel workspace resource ID.')
param sentinelWorkspaceId string

@description('Name of the Container Insights DCR.')
param dcrName string = 'dcr-aio-k8s-container-insights'

resource k8sDcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dcrName
  location: location
  properties: {
    description: 'Collects Container Insights data from Arc-enabled K8s clusters running AIO workloads. Routes container logs and Kubernetes events to Sentinel.'
    dataSources: {
      extensions: [
        {
          name: 'ContainerInsightsExtension'
          streams: [
            'Microsoft-ContainerLog'
            'Microsoft-ContainerLogV2'
            'Microsoft-KubeEvents'
            'Microsoft-KubePodInventory'
            'Microsoft-KubeNodeInventory'
            'Microsoft-KubeServices'
            'Microsoft-InsightsMetrics'
          ]
          extensionName: 'ContainerInsights'
          extensionSettings: {
            dataCollectionSettings: {
              interval: '1m'
              namespaceFilteringMode: 'Include'
              namespaces: [
                'azure-iot-operations'
                'kube-system'
                'default'
              ]
              enableContainerLogV2: true
            }
          }
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'sentinelWorkspace'
          workspaceResourceId: sentinelWorkspaceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-ContainerLog'
          'Microsoft-ContainerLogV2'
          'Microsoft-KubeEvents'
          'Microsoft-KubePodInventory'
        ]
        destinations: [
          'sentinelWorkspace'
        ]
      }
      {
        streams: [
          'Microsoft-KubeNodeInventory'
          'Microsoft-KubeServices'
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'sentinelWorkspace'
        ]
      }
    ]
  }
}

output dcrId string = k8sDcr.id
output dcrName string = k8sDcr.name

// ──────────────────────────────────────────────────────────
// Diagnostic Settings — Arc-enabled Kubernetes Clusters
// KubeAuditAdmin, KubeEvents → Sentinel
// ContainerLog, operational metrics → ITOps
// ──────────────────────────────────────────────────────────

@description('Sentinel workspace resource ID (security-relevant logs).')
param sentinelWorkspaceId string

@description('ITOps workspace resource ID (operational telemetry).')
param opsWorkspaceId string

@description('Name of the Arc-enabled Kubernetes cluster. Leave empty to skip.')
param arcClusterName string = ''

// ──────────────────────────────────────────────────────────
// Arc-enabled K8s — Security logs to Sentinel
// KubeAuditAdmin: API server audit (who did what)
// KubeEvents: pod lifecycle, scheduling, errors
// ──────────────────────────────────────────────────────────

resource arcCluster 'Microsoft.Kubernetes/connectedClusters@2024-01-01' existing = if (!empty(arcClusterName)) {
  name: arcClusterName
}

resource arcSecurityDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(arcClusterName)) {
  name: 'arc-k8s-security-to-sentinel'
  scope: arcCluster
  properties: {
    workspaceId: sentinelWorkspaceId
    logs: [
      {
        category: 'kube-audit-admin'
        enabled: true
      }
      {
        category: 'kube-audit'
        enabled: true
      }
      {
        category: 'guard'
        enabled: true
      }
    ]
  }
}

// ──────────────────────────────────────────────────────────
// Arc-enabled K8s — Operational logs to ITOps
// ContainerLog: stdout/stderr from containers
// Metrics: node/pod resource utilization
// ──────────────────────────────────────────────────────────

resource arcOpsDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(arcClusterName)) {
  name: 'arc-k8s-ops-to-itops'
  scope: arcCluster
  properties: {
    workspaceId: opsWorkspaceId
    logs: [
      {
        category: 'kube-controller-manager'
        enabled: true
      }
      {
        category: 'kube-scheduler'
        enabled: true
      }
      {
        category: 'cluster-autoscaler'
        enabled: true
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

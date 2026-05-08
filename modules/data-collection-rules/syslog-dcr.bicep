// ──────────────────────────────────────────────────────────
// Data Collection Rule — Syslog via Azure Monitor Agent
// Collects auth/security syslog from Ubuntu edge nodes
// ──────────────────────────────────────────────────────────

@description('Azure region for the DCR.')
param location string

@description('Sentinel workspace resource ID.')
param sentinelWorkspaceId string

@description('Name of the syslog data collection rule.')
param dcrName string = 'dcr-aio-syslog-sentinel'

resource syslogDcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dcrName
  location: location
  properties: {
    description: 'Collects security-relevant syslog data from AIO edge nodes via Azure Monitor Agent and routes to Sentinel.'
    dataSources: {
      syslog: [
        {
          name: 'syslogAuthSecurity'
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: [
            'auth'
            'authpriv'
          ]
          logLevels: [
            'Info'
            'Notice'
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
        }
        {
          name: 'syslogSystem'
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: [
            'syslog'
            'daemon'
            'kern'
          ]
          logLevels: [
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
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
          'Microsoft-Syslog'
        ]
        destinations: [
          'sentinelWorkspace'
        ]
      }
    ]
  }
}

output dcrId string = syslogDcr.id
output dcrName string = syslogDcr.name

# Log Table Reference

Source-to-Sentinel table mapping for Azure IoT Operations edge-to-cloud security monitoring.

## Log Sources and Destinations

| Source | Log Type | Sentinel Table(s) | Collection Method | Destination |
|--------|----------|-------------------|-------------------|-------------|
| **AIO MQTT Broker** | Authentication events, connection logs, message routing | `AzureDiagnostics` | Diagnostic Settings | Sentinel |
| **AIO MQTT Broker** | Message throughput, latency metrics | Metrics (not table) | Diagnostic Settings | ITOps |
| **AIO Data Processor** | Pipeline execution, transformation logs | `AzureDiagnostics` | Diagnostic Settings | Sentinel |
| **AIO Data Processor** | Processing metrics, throughput | Metrics (not table) | Diagnostic Settings | ITOps |
| **AIO OPC UA Connector** | Connection events, data point status | `AzureDiagnostics` | Diagnostic Settings | Sentinel |
| **Arc-enabled K8s** | API server audit (who did what, RBAC decisions) | `KubeAuditAdmin` | Diagnostic Settings | Sentinel |
| **Arc-enabled K8s** | Pod lifecycle, scheduling, errors | `KubeEvents` | Diagnostic Settings | Sentinel |
| **Arc-enabled K8s** | Container stdout/stderr | `ContainerLogV2` | Container Insights DCR | Sentinel |
| **Arc-enabled K8s** | Node/pod inventory | `KubePodInventory`, `KubeNodeInventory` | Container Insights DCR | Sentinel |
| **Arc-enabled K8s** | Controller manager, scheduler logs | Diagnostic Settings | Diagnostic Settings | ITOps |
| **Ubuntu OS** | SSH logins, sudo, PAM (`auth`, `authpriv`) | `Syslog` | AMA + Syslog DCR | Sentinel |
| **Ubuntu OS** | System services, kernel messages (`daemon`, `kern`, `syslog`) | `Syslog` | AMA + Syslog DCR | Sentinel |
| **MDE Sensor** | Process creation, command lines | `DeviceProcessEvents` | M365 Defender Connector | Sentinel |
| **MDE Sensor** | Network connections, DNS queries | `DeviceNetworkEvents` | M365 Defender Connector | Sentinel |
| **MDE Sensor** | File creation, modification, deletion | `DeviceFileEvents` | M365 Defender Connector | Sentinel |
| **MDE Sensor** | Logon events | `DeviceLogonEvents` | M365 Defender Connector | Sentinel |
| **Azure Control Plane** | Resource CRUD, RBAC changes, deployments | `AzureActivity` | Azure Activity Connector | Sentinel |
| **Defender for Cloud** | Security alerts from enabled plans | `SecurityAlert` | Continuous Export | Sentinel |
| **Defender for Cloud** | Compliance recommendations | `SecurityRecommendation` | Continuous Export | Sentinel |

## Syslog Severity Configuration

The syslog DCR is configured with different minimum severity levels per facility to balance security visibility with log volume:

| Facility | Minimum Severity | Rationale |
|----------|-----------------|-----------|
| `auth` | Info | Capture all authentication events including successes |
| `authpriv` | Info | Capture privilege escalation and PAM events |
| `syslog` | Warning | Reduce noise from routine system messages |
| `daemon` | Warning | Focus on service failures and errors |
| `kern` | Warning | Capture kernel warnings and above |

## MDE Tables (via M365 Defender Connector)

MDE data arrives via the Microsoft 365 Defender data connector. These tables are populated when edge nodes are onboarded to Defender for Endpoint via Microsoft Intune.

| Table | Content | Security Value |
|-------|---------|----------------|
| `DeviceProcessEvents` | Process creation with command lines | Detect suspicious commands, scripts, lateral movement |
| `DeviceNetworkEvents` | Network connections from endpoints | Detect C2 callbacks, unusual outbound connections |
| `DeviceFileEvents` | File system activity | Detect data staging, tool drops, config modifications |
| `DeviceLogonEvents` | Authentication events on endpoints | Detect brute force, unusual logon patterns |
| `DeviceRegistryEvents` | Registry changes (Windows only) | N/A for Ubuntu edge nodes |

> **Note:** MDE onboarding is managed via Microsoft Intune / Defender XDR portal, not by these Bicep templates.

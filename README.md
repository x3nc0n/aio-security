# Azure IoT Operations — Edge-to-Cloud Security

Bicep templates for securing Azure IoT Operations (AIO) edge-to-cloud deployments with Microsoft Sentinel, Azure Policy, and Azure Monitor.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fx3nc0n%2Faio-security%2Fmain%2Fazuredeploy.json)

> **Note:** The Deploy to Azure button requires the compiled ARM template (`azuredeploy.json`). A [GitHub Action](.github/workflows/build-arm.yml) automatically compiles `main.bicep` → `azuredeploy.json` on every push to `main`. To deploy manually, run `az bicep build -f main.bicep --outfile azuredeploy.json` first.

---

## What This Deploys

This solution implements a three-pillar security architecture for Azure IoT Operations:

| Pillar | What It Does | Modules |
|--------|-------------|---------|
| **Logging & Visibility** | Routes security logs to Sentinel, operational telemetry to ITOps | Diagnostic settings, Data Collection Rules, Sentinel connectors |
| **Compliance & Policy** | Assigns CIS benchmarks and custom AIO security policies | CIS Azure Foundations v2.0, CIS Kubernetes, custom AIO policies |
| **Monitoring** | Centralized workspace for log ingestion and analysis | Log Analytics workspace (optional) |

For the full architecture, see [docs/architecture.md](docs/architecture.md).

---

## Log Routing Summary

All security-relevant logs flow to the **Sentinel workspace**. Operational telemetry flows to the **ITOps workspace** to avoid duplication.

| Source | Sentinel Table(s) | Routing |
|--------|-------------------|---------|
| AIO components (MQTT Broker, Data Processor, OPC UA) | `AzureDiagnostics` | Security logs → Sentinel |
| Kubernetes audit & events | `KubeAuditAdmin`, `KubeEvents`, `ContainerLogV2` | Audit/events → Sentinel |
| Ubuntu OS (syslog, auth) | `Syslog` (via AMA) | auth/authpriv → Sentinel |
| MDE sensor data | `DeviceProcessEvents`, `DeviceNetworkEvents`, `DeviceFileEvents` | Via M365 Defender connector |
| Azure control plane | `AzureActivity`, `SecurityAlert`, `SecurityRecommendation` | Via Azure Activity connector |

Full details: [docs/log-table-reference.md](docs/log-table-reference.md)

---

## Policies Assigned

| Policy | Type | Effect |
|--------|------|--------|
| CIS Microsoft Azure Foundations v2.0 | Built-in initiative | Audit |
| Kubernetes Pod Security Baseline | Built-in initiative | Audit |
| Azure Policy Add-on for K8s | Built-in | DeployIfNotExists |
| AIO: Require diagnostic settings | Custom | DeployIfNotExists |
| AIO: MQTT Broker TLS enforcement | Custom | Audit |
| AIO: MQTT authentication enabled | Custom | Audit |

Full catalog: [docs/policy-catalog.md](docs/policy-catalog.md)

---

## Prerequisites

- **Azure subscription** with Owner or Contributor + User Access Administrator permissions
- **Microsoft Sentinel** workspace (existing) — provide the resource ID as `sentinelWorkspaceId`
- **Log Analytics workspace** for ITOps (existing) — provide the resource ID as `opsWorkspaceId`
- **Arc-enabled Kubernetes** clusters with AIO deployed
- **Azure Monitor Agent (AMA)** installed on edge nodes (for syslog collection)
- **Microsoft Defender for Endpoint (MDE)** onboarded via Microsoft Intune / Defender XDR (not managed by these templates)
- **Azure CLI** with Bicep extension (`az bicep install`)

> **Out of scope:** Defender for IoT is not included in this deployment. MDE onboarding is managed via Intune/XDR, not these templates.

> **Connectivity:** Each component supports proxy and private endpoint connectivity. Refer to the individual Azure service documentation for private endpoint configuration.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `location` | string | No | Azure region (default: `eastus2`) |
| `sentinelWorkspaceId` | string | **Yes** | Resource ID of the Sentinel Log Analytics workspace |
| `opsWorkspaceId` | string | **Yes** | Resource ID of the ITOps Log Analytics workspace |
| `assignmentScope` | string | No | Scope for policy assignments (default: current subscription) |
| `deployDiagnostics` | bool | No | Deploy diagnostic settings modules (default: `true`) |
| `deployPolicies` | bool | No | Deploy Azure Policy assignments (default: `true`) |
| `deployDataCollectionRules` | bool | No | Deploy DCR modules (default: `true`) |
| `deploySentinelConnectors` | bool | No | Deploy Sentinel data connectors (default: `true`) |

---

## Quick Start

### Option 1: Deploy via Azure CLI

```bash
# Clone the repo
git clone https://github.com/x3nc0n/aio-security.git
cd aio-security

# Edit parameters
cp main.bicepparam main.local.bicepparam
# Update the workspace IDs and subscription in main.local.bicepparam

# Deploy
az deployment sub create \
  --location eastus2 \
  --template-file main.bicep \
  --parameters main.local.bicepparam
```

### Option 2: Deploy to Azure Button

Click the button at the top of this README. You will be prompted to provide the required parameters in the Azure Portal.

### Option 3: Selective Deployment

Deploy only specific modules by setting the toggle parameters:

```bash
az deployment sub create \
  --location eastus2 \
  --template-file main.bicep \
  --parameters sentinelWorkspaceId='<ID>' opsWorkspaceId='<ID>' \
  --parameters deployPolicies=true deployDiagnostics=false
```

---

## Repository Structure

```
├── main.bicep                          # Orchestration entry point
├── main.bicepparam                     # Default parameters
├── azuredeploy.json                    # Compiled ARM (auto-generated)
├── modules/
│   ├── diagnostic-settings/
│   │   ├── aio-diagnostics.bicep       # AIO component diagnostic settings
│   │   └── arc-k8s-diagnostics.bicep   # Arc-enabled K8s diagnostic settings
│   ├── policy-assignments/
│   │   ├── cis-azure-foundations.bicep  # CIS Azure Foundations v2.0
│   │   ├── cis-kubernetes.bicep        # CIS Kubernetes benchmark
│   │   └── aio-custom-policies.bicep   # Custom AIO policies
│   ├── data-collection-rules/
│   │   ├── syslog-dcr.bicep            # Syslog collection via AMA
│   │   └── k8s-dcr.bicep              # Container Insights DCR
│   ├── sentinel/
│   │   └── data-connectors.bicep       # Sentinel data connectors
│   └── monitoring/
│       └── log-analytics-workspace.bicep
├── docs/
│   ├── architecture.md                 # Solution architecture
│   ├── log-table-reference.md          # Log source → Sentinel table mapping
│   └── policy-catalog.md              # Complete policy catalog
└── .github/workflows/
    └── build-arm.yml                   # Auto-compile Bicep → ARM JSON
```

---

## License

MIT

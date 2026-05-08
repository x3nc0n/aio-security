# Solution Architecture

Azure IoT Operations — Edge-to-Cloud Security Architecture

## Overview

This solution secures Azure IoT Operations (AIO) edge-to-cloud deployments using three pillars: **Logging & Visibility**, **Compliance & Policy**, and **Monitoring & Detection**. Each pillar operates independently and can be deployed selectively using the module toggle parameters in `main.bicep`.

## Architecture Pillars

### Pillar 1: Logging & Visibility

**Goal:** Ensure every security-relevant event from edge to cloud is captured in Microsoft Sentinel, while operational telemetry goes to a separate ITOps workspace.

```
┌─────────────────────────────────────────────────────────────┐
│                     Edge Nodes (Ubuntu)                      │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  MQTT Broker  │  │Data Processor│  │OPC UA Connec.│     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │              │
│  ┌──────┴──────────────────┴──────────────────┴──────┐     │
│  │         Azure Monitor Agent (AMA)                  │     │
│  │         + Syslog Collection                        │     │
│  └──────────────────────┬────────────────────────────┘     │
│                         │                                   │
│  ┌──────────────────────┴────────────────────────────┐     │
│  │         MDE Sensor (via Intune)                    │     │
│  └──────────────────────┬────────────────────────────┘     │
└─────────────────────────┼───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                        Azure                                 │
│                                                             │
│  ┌────────────────────────┐  ┌────────────────────────┐    │
│  │   Sentinel Workspace    │  │    ITOps Workspace      │    │
│  │   (Security Logs)       │  │   (Operational Logs)    │    │
│  │                        │  │                        │    │
│  │  • AzureDiagnostics    │  │  • Metrics             │    │
│  │  • KubeAuditAdmin      │  │  • Controller logs     │    │
│  │  • KubeEvents          │  │  • Scheduler logs      │    │
│  │  • ContainerLogV2      │  │                        │    │
│  │  • Syslog              │  │                        │    │
│  │  • Device*Events (MDE) │  │                        │    │
│  │  • AzureActivity       │  │                        │    │
│  │  • SecurityAlert       │  │                        │    │
│  └────────────────────────┘  └────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**Key design decision:** Security-relevant logs and operational telemetry are routed to separate workspaces to prevent duplication, manage costs, and enable clear ownership (SecOps vs. ITOps).

**Components:**
- **Diagnostic Settings** — Route AIO component logs to Sentinel, metrics to ITOps
- **Data Collection Rules** — Syslog (auth/authpriv at Info, system at Warning+) and Container Insights
- **Sentinel Data Connectors** — Microsoft 365 Defender (MDE data) and Azure Activity

### Pillar 2: Compliance & Policy

**Goal:** Continuously evaluate Azure and Kubernetes resources against security benchmarks and enforce AIO-specific security controls.

**Built-in Initiatives:**
- **CIS Azure Foundations v2.0** — 200+ controls covering identity, networking, logging, storage, database, and key vault
- **Kubernetes Pod Security Baseline** — Prevents privileged containers, host networking, and privilege escalation

**Custom AIO Policies:**
- **DeployIfNotExists:** Automatically deploy diagnostic settings on AIO resources
- **Audit:** TLS enforcement on MQTT Broker listeners
- **Audit:** Authentication enabled on MQTT Broker

**Enforcement model:** All policies start in `Audit` mode by default. The enforcement mode can be changed to `Default` (enforce) for production environments via the `enforcementMode` parameter.

### Pillar 3: Monitoring & Detection

**Goal:** Centralize all security telemetry in Sentinel for threat detection, investigation, and response.

This pillar is enabled by the first two pillars — once logs flow into Sentinel and compliance is evaluated, security teams can build:

- **Analytics rules** for AIO-specific threats (e.g., unauthorized MQTT connections, TLS downgrade attempts)
- **Workbooks** for compliance posture visualization
- **Hunting queries** using KQL across all data sources
- **Automated response** via Logic Apps triggered by Sentinel incidents

## Data Flow

```
Edge Node                    Azure
──────────                   ─────

AIO Components ──diag──────► Sentinel (AzureDiagnostics)
               ──metrics───► ITOps (Metrics)

K8s Cluster ────audit──────► Sentinel (KubeAuditAdmin)
            ────events─────► Sentinel (KubeEvents)
            ────containers─► Sentinel (ContainerLogV2)
            ────ops────────► ITOps (controller/scheduler)

Ubuntu OS ──────syslog─────► Sentinel (Syslog via AMA)

MDE Sensor ─────────────────► Sentinel (Device*Events via M365D)

Azure ARM ──────────────────► Sentinel (AzureActivity)
```

## Connectivity

Each layer supports proxy and private endpoint connectivity:

- **Azure Monitor Agent** — Supports proxy configuration and private link scope
- **Arc-enabled Kubernetes** — Supports proxy for Arc agent connectivity
- **MDE** — Supports proxy for cloud communication
- **Diagnostic Settings** — Private endpoints for Log Analytics workspace

Refer to the individual Azure service documentation for private endpoint and proxy configuration details. This solution does not provision private endpoints but is compatible with them.

## Out of Scope

- **Defender for IoT** — Not included; the solution uses MDE + Sentinel instead
- **MDE onboarding** — Managed via Microsoft Intune / Defender XDR portal
- **Private endpoint provisioning** — Compatible but not deployed by these templates
- **Sentinel analytics rules** — Log ingestion and data connectors only; detection rules are a separate concern

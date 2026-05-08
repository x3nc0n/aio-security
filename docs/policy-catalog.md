# Policy Catalog

Complete list of Azure Policy assignments deployed by this solution.

## Built-in Policy Initiatives

### CIS Microsoft Azure Foundations Benchmark v2.0.0

| Property | Value |
|----------|-------|
| **Assignment name** | `cis-azure-foundations-v2` |
| **Type** | Built-in Initiative (Policy Set) |
| **Definition ID** | `06f19060-9e68-4070-92ca-f15cc126059e` |
| **Effect** | Audit (configurable) |
| **Enforcement** | Default |
| **What it covers** | Identity, networking, logging, storage, database, key vault, App Service, and more |

This initiative evaluates Azure resources against the CIS Microsoft Azure Foundations Benchmark v2.0. It includes 200+ individual policy definitions covering:

- Identity and Access Management (MFA, conditional access)
- Security Center (Defender plans enabled)
- Storage Accounts (encryption, network rules)
- Database Services (auditing, TDE, firewall)
- Logging and Monitoring (diagnostic settings, activity log alerts)
- Networking (NSG flow logs, WAF, DDoS protection)
- Key Vault (soft delete, purge protection, expiration)

---

### Kubernetes Cluster Pod Security Baseline

| Property | Value |
|----------|-------|
| **Assignment name** | `cis-kubernetes-benchmark` |
| **Type** | Built-in Initiative (Policy Set) |
| **Definition ID** | `a8640138-9b0a-4a28-b8cb-1666c838647d` |
| **Effect** | Audit |
| **Enforcement** | Default |
| **What it covers** | Pod security standards for Linux-based Kubernetes workloads |

Enforces pod security baseline standards on Kubernetes clusters, including Arc-enabled K8s running AIO workloads:

- No privileged containers
- No host networking or host PID/IPC
- Restricted volume types
- No privilege escalation
- Required seccomp profiles
- Restricted capabilities

---

### Azure Policy Add-on for Kubernetes

| Property | Value |
|----------|-------|
| **Assignment name** | `k8s-azure-policy-addon` |
| **Type** | Built-in Policy |
| **Definition ID** | `0adc5395-9169-4b9b-8687-af838d69410a` |
| **Effect** | DeployIfNotExists |
| **Enforcement** | Default |
| **What it covers** | Ensures Azure Policy add-on is deployed on Arc-enabled clusters |

Required for Kubernetes policy enforcement. Automatically deploys the Azure Policy add-on when an Arc-enabled cluster is detected without it.

---

## Custom AIO Policies

### AIO: Require Diagnostic Settings

| Property | Value |
|----------|-------|
| **Assignment name** | `aio-enforce-diagnostics` |
| **Policy definition name** | `aio-require-diagnostic-settings` |
| **Type** | Custom Policy |
| **Effect** | DeployIfNotExists |
| **Enforcement** | Default |
| **What it covers** | AIO MQTT Broker, Data Processor, OPC UA Connector |

Automatically deploys diagnostic settings on AIO resources to route logs to the Sentinel workspace. Targets these resource types:

- `Microsoft.IoTOperationsMQ/mq`
- `Microsoft.IoTOperationsDataProcessor/instances`
- `Microsoft.IoTOperationsOrchestratorConnector/instances`

Managed identity roles required:
- `Monitoring Contributor` (749f88d5-cbae-40b8-bcfc-e573ddc772fa)
- `Log Analytics Contributor` (92aaf0da-9dab-42b6-94a3-d43ce8d16293)

---

### AIO: MQTT Broker TLS Enforcement

| Property | Value |
|----------|-------|
| **Assignment name** | `aio-audit-mqtt-tls` |
| **Policy definition name** | `aio-audit-mqtt-tls` |
| **Type** | Custom Policy |
| **Effect** | Audit |
| **Enforcement** | Default |
| **What it covers** | MQTT Broker listener ports |

Audits MQTT Broker listener resources to ensure TLS is configured. Non-compliant resources appear in the Azure Policy compliance dashboard when a listener is created without a TLS configuration block.

---

### AIO: MQTT Authentication Enabled

| Property | Value |
|----------|-------|
| **Assignment name** | `aio-audit-mqtt-auth` |
| **Policy definition name** | `aio-audit-mqtt-auth` |
| **Type** | Custom Policy |
| **Effect** | Audit |
| **Enforcement** | Default |
| **What it covers** | MQTT Broker authentication configuration |

Audits MQTT Broker authentication resources to verify that authentication methods are configured. Flags brokers that lack authentication configuration, which would allow anonymous connections.

---

## Summary Table

| Policy | Effect | Built-in / Custom | Target Resources |
|--------|--------|-------------------|------------------|
| CIS Azure Foundations v2.0 | Audit | Built-in initiative | All Azure resources |
| K8s Pod Security Baseline | Audit | Built-in initiative | Kubernetes clusters |
| Azure Policy Add-on for K8s | DeployIfNotExists | Built-in | Arc-enabled K8s |
| AIO: Require diagnostic settings | DeployIfNotExists | Custom | AIO resources |
| AIO: MQTT TLS enforcement | Audit | Custom | MQTT Broker listeners |
| AIO: MQTT authentication enabled | Audit | Custom | MQTT Broker auth |

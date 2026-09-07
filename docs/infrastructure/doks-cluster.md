# DigitalOcean Kubernetes Infrastructure

This document describes the DigitalOcean Kubernetes (DOKS) infrastructure used to host the Java and MySQL observability platform.

## Cluster Overview

The platform runs on a managed DigitalOcean Kubernetes cluster.

| Component | Configuration |
|---|---|
| Cloud Provider | DigitalOcean |
| Kubernetes Service | DigitalOcean Kubernetes (DOKS) |
| Cluster Name | `prometheus-observability` |
| Node Pool | `observability-workers` |
| Worker Nodes | 3 |
| vCPU per Node | 2 |
| Memory per Node | 4 GB |
| Autoscaling | Enabled |
| Minimum Nodes | 3 |
| Maximum Nodes | 5 |
| Ingress | NGINX Ingress Controller |
| External Traffic | DigitalOcean Load Balancer |
| Container Runtime | Kubernetes-managed |
| Monitoring | Prometheus / Grafana / Alertmanager |

---

## Infrastructure Architecture

```text
                         Internet
                            │
                            ▼
                DigitalOcean Load Balancer
                            │
                            ▼
                 NGINX Ingress Controller
                            │
                            ▼
                    Kubernetes Service
                            │
                ┌───────────┼───────────┐
                ▼           ▼           ▼
             Java Pod    Java Pod    Java Pod
                │           │           │
                └───────────┼───────────┘
                            │
                            ▼
                       MySQL Primary
                            │
                            ▼
                      MySQL Secondary


                  DOKS Worker Node Pool
              ┌─────────┬─────────┬─────────┐
              │ Node 1  │ Node 2  │ Node 3  │
              └─────────┴─────────┴─────────┘
                       Autoscaling
                         3 → 5
```

---

## Kubernetes Namespaces

The platform separates infrastructure components using Kubernetes namespaces.

```text
default
├── Java application
├── MySQL
├── MySQL Exporter
└── Application Ingress

ingress-nginx
└── NGINX Ingress Controller

monitoring
├── Prometheus
├── Grafana
├── Alertmanager
├── Prometheus Operator
├── kube-state-metrics
└── Prometheus monitoring resources
```

---

## Verify Cluster Access

Before deploying workloads, verify the active Kubernetes context:

```bash
kubectl config current-context
```

Expected context:

```text
do-tor1-prometheus-observability
```

Verify the cluster:

```bash
kubectl cluster-info
```

Verify worker nodes:

```bash
kubectl get nodes
```

All worker nodes should report:

```text
Ready
```

For additional information:

```bash
kubectl get nodes -o wide
```

---

## Cluster Workloads

Verify workloads across all namespaces:

```bash
kubectl get pods -A
```

The environment should contain workloads for:

- Java application
- MySQL primary
- MySQL secondary
- MySQL Exporter
- NGINX Ingress Controller
- Prometheus
- Grafana
- Alertmanager
- Prometheus Operator
- kube-state-metrics
- node-exporter

---

## Ingress and External Access

External application traffic enters the cluster through a DigitalOcean Load Balancer provisioned by the NGINX Ingress Controller Service.

```text
Internet
   │
   ▼
DigitalOcean Load Balancer
   │
   ▼
NGINX Ingress Controller
   │
   ▼
Application Ingress
   │
   ▼
Java Service
   │
   ▼
Java Pods
```

Verify the NGINX service:

```bash
kubectl get svc -n ingress-nginx
```

Verify the application Ingress:

```bash
kubectl get ingress
```

The external Load Balancer address should not be hard-coded into repository configuration.

---

## Monitoring Infrastructure

The monitoring stack is deployed with the `kube-prometheus-stack` Helm chart.

Verify the Helm release:

```bash
helm list -n monitoring
```

Verify monitoring workloads:

```bash
kubectl get pods -n monitoring
```

Verify Prometheus resources:

```bash
kubectl get servicemonitor -A
kubectl get prometheusrule -n monitoring
kubectl get alertmanagerconfig -n monitoring
```

Prometheus collects metrics from:

```text
Java Application
NGINX Ingress Controller
MySQL Exporter
kube-state-metrics
Prometheus Node Exporter
```

---

## High Availability

The infrastructure uses multiple replicas where appropriate.

### Java Application

The Java application runs with three replicas:

```bash
kubectl get deployment java-monitoring-app
```

### MySQL

MySQL uses a primary/secondary replication architecture:

```bash
kubectl get statefulset
```

Expected workloads:

```text
java-mysql-db-primary
java-mysql-db-secondary
```

### NGINX Ingress

The NGINX Ingress Controller runs multiple replicas to reduce dependency on a single controller pod.

### Worker Nodes

The DOKS node pool starts with three worker nodes and supports autoscaling up to five nodes.

---

## Security

Cluster credentials and sensitive configuration must not be committed to the repository.

Do not commit:

```text
DigitalOcean API tokens
kubeconfig files
database passwords
Slack webhook URLs
Gmail App Passwords
Docker registry credentials
SSH private keys
CI/CD tokens
```

Application and monitoring credentials are managed using Kubernetes Secrets.

Verify Secret resources without displaying their values:

```bash
kubectl get secrets -A
```

Do not use commands that decode Secret values when collecting screenshots or repository evidence.

---

## Infrastructure Validation

Use the following commands to verify the environment after deployment:

```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
kubectl get ingress
```

Verify Helm releases:

```bash
helm list -n default
helm list -n ingress-nginx
helm list -n monitoring
```

Verify monitoring resources:

```bash
kubectl get servicemonitor -A
kubectl get prometheusrule -n monitoring
kubectl get alertmanagerconfig -n monitoring
```

A healthy environment should have:

```text
Worker Nodes           Ready
Java Application       3 replicas Running
MySQL Primary          Running
MySQL Secondary        Running
MySQL Exporter         Running
NGINX Ingress          Running
Prometheus             Running
Grafana                Running
Alertmanager           Running
```

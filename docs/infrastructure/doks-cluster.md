# DigitalOcean Kubernetes Cluster

## Overview

This project uses DigitalOcean Kubernetes (DOKS) as the managed Kubernetes platform for deploying the Java, MySQL, ingress, monitoring, and alerting workloads.

The cluster is configured with a dedicated autoscaling worker pool and a pinned Kubernetes version to improve reproducibility.

## Cluster Configuration

| Setting              | Value                          |
| -------------------- | ------------------------------ |
| Cluster Name         | `prometheus-observability`     |
| Cloud Provider       | DigitalOcean                   |
| Kubernetes Platform  | DigitalOcean Kubernetes (DOKS) |
| Region               | `tor1`                         |
| Kubernetes Version   | `1.35.7-do.3`                  |
| Worker Pool          | `observability-workers`        |
| Worker Size          | `s-2vcpu-4gb`                  |
| Initial Worker Count | `3`                            |
| Minimum Workers      | `3`                            |
| Maximum Workers      | `5`                            |
| Autoscaling          | Enabled                        |
| Surge Upgrade        | Enabled                        |
| Maintenance Window   | Saturday at 03:00              |
| Container Runtime    | `containerd`                   |

## Cluster Creation

The cluster was created using the DigitalOcean CLI:

```bash
doctl kubernetes cluster create prometheus-observability \
  --region tor1 \
  --version 1.35.7-do.3 \
  --node-pool "name=observability-workers;size=s-2vcpu-4gb;count=3;auto-scale=true;min-nodes=3;max-nodes=5" \
  --maintenance-window saturday=03:00 \
  --surge-upgrade=true \
  --wait
```

The Kubernetes version is explicitly pinned rather than using `latest` to improve reproducibility and avoid unexpected compatibility changes when the cluster is recreated.

## Kubernetes Credentials

Cluster credentials were downloaded locally using:

```bash
doctl kubernetes cluster kubeconfig save prometheus-observability
```

The kubeconfig is stored locally in:

```text
~/.kube/config
```

The active context can be verified with:

```bash
kubectl config current-context
```

Expected context:

```text
do-tor1-prometheus-observability
```

## Cluster Validation

Verify that all worker nodes are available:

```bash
kubectl get nodes -o wide
```

Expected result:

```text
STATUS: Ready
Kubernetes: v1.35.7
Container Runtime: containerd
```

Because cluster autoscaling is enabled, the active worker count can vary between three and five nodes depending on scheduling and resource demand.

The cluster initially started with three workers and automatically increased to four workers during initial provisioning.

Verify the DigitalOcean node pool:

```bash
doctl kubernetes cluster node-pool list prometheus-observability
```

Verify Kubernetes system workloads:

```bash
kubectl get pods -A
```

Verify available storage classes:

```bash
kubectl get storageclass
```

Persistent storage availability must be confirmed before deploying MySQL.

## Security

DigitalOcean authentication uses a scoped Personal Access Token rather than a full-access token.

The token must never be:

* committed to Git
* stored in Kubernetes manifests
* stored in the README
* embedded in shell scripts
* exposed in screenshots
* uploaded to GitHub or GitLab

The local Kubernetes configuration file must also never be committed:

```text
~/.kube/config
```

Cluster credentials, API tokens, SSH keys, and other secrets remain outside the repository.

## Current Status

The DOKS cluster is running successfully and the worker nodes are in the `Ready` state.

This infrastructure is now ready for the next deployment stage:

```text
MySQL
→ Java application
→ ingress-nginx
→ Kubernetes Ingress
→ Prometheus monitoring
→ Grafana
→ Alertmanager
```

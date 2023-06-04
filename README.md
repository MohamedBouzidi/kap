# KAP: Kubernetes Application Platform

## Introduction
This project creates an application deployment platform with a development workflow on top of a Kubernetes cluster.

## How to (un)install
The Kubernetes environment is provided by [kind](https://kind.sigs.k8s.io/) at the moment.

To install the platform, make sure you have `kind` installed and run the following command:

```bash
$ bash scripts/launch.sh
```

To uninstall, use the following command:

```bash
$ bash scripts/destroy.sh
```

## How to use
You can begin by creating a new project, which is a grouping of applications, using the following command:

```bash
$ bash scripts/kapcli.sh create_project --project-name my-project
```

Once you have a project, you can add applications by running:

```bash
$ bash scripts/kapcli.sh create_app --project-name my-project --app-name my-app --type golang
```

## List of components

|   Component   |     Description    |
| ------------- | ------------------ |
| [Cert-Manager](https://cert-manager.io/) |   Certificate management   |
| [Prometheus Operator](https://prometheus-operator.dev/) | Metrics aggregation |
| [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/) | Ingress controller |
| [External DNS](https://github.com/kubernetes-sigs/external-dns) | DNS extension |
| [Vault](https://www.vaultproject.io/) | PKI and secrets management |
| [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) | GitOps CD |
| [Traefik Ingress Controller](https://traefik.io/traefik/) | Ingress Controller for clients |
| [Kubernetes Dashboard](https://github.com/kubernetes/dashboard) | k8s Dashboard |
| [Prometheus](https://prometheus.io/) | Metrics aggregation |
| [Grafana](https://grafana.com/) | Metrics dashboard |
| [GitLab](https://about.gitlab.com/) | Source and CI management |
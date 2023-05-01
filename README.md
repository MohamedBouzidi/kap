# KAP: Kubernetes Application Platform

## Introduction
This project creates an application deployment platform with a development workflow on top of a Kubernetes cluster.

## How to install
The Kubernetes environment is provided by [kind](https://kind.sigs.k8s.io/) at the moment.
To create a new cluster, make sure you have `kind` installed and run the following commands:

```bash
$ bash ./cluster/create_cluster.sh
$ bash ./cluster/update_kubeconfig.sh
$ bash ./add_dns_records.sh
```

Next, you need to install the following components in the given order:

|   Component   |     Command    |
| ------------- | -------------- |
| [Cert-Manager](https://cert-manager.io/) |   `$ kubectl create -k ./cert-manager`   |
| [Prometheus Operator](https://prometheus-operator.dev/) | `$ kubectl create -k ./monitoring/prometheus-operator` |
| [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/) | `$ kubectl create -k ./ingress-nginx` |
| [External DNS](https://github.com/kubernetes-sigs/external-dns) | `$ bash ./external-dns/install.sh` |
| [Vault](https://www.vaultproject.io/) | `$ bash ./vault/scripts/install_vault.sh` |
| [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) | `$ kubectl create -k ./argocd` |
| [Traefik Ingress Controller](https://traefik.io/traefik/) | `$ kubectl create -k ./traefik-ingress` |
| [Kubernetes Dashboard](https://github.com/kubernetes/dashboard) | `$ kubectl create -f ./dashboard/recommended.yaml` |
| [Prometheus](https://prometheus.io/) | `$ kubectl create -k ./monitoring/prometheus` |
| [Grafana](https://grafana.com/) | `$ kubectl create -k ./monitoring/grafana` |
| [GitLab](https://about.gitlab.com/) | `$ kubectl create -k ./gitlab`<br>`$ kubectl create -k ./gitlab/gitlab`<br>`$ kubectl create -k ./gitlab/registry`<br>`$ kubectl create -k ./gitlab/gitlab-runner` |

> **Note**
> The `launch.sh` script should install all necessary components

## How to use
Before starting, you should add entries to your `/etc/hosts` for each `Ingress` resource:

```bash
$ kubectl get ingress -A
```

After that, you should be able to create a new project as follows:

> **Note**<br>
> The ArgoCD project and app names should match the GitLab group and repo names respectively.

```bash
$ bash scripts/helpers/gitlab.sh create_group --gitlab-host "gitlab.dev.local" --group-name "test-group"
$ bash scripts/helpers/gitlab.sh create_repo --gitlab-host "gitlab.dev.local" --group-name "test-group" --repo-name "test-repo"
$ bash scripts/helpers/argocd.sh create_project --project-name "test-group"
$ bash scripts/helpers/argocd.sh create_app --project-name "test-group" --app-name "test-repo"
```
> **Warning**<br>
> Before creating the ArgoCD project/app, you should build an image using example code in the `application/service-1` directory.
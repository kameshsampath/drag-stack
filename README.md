# DroneArgoGitea(DAG) Stack

A small demo and setup to demonstrate on how to setup [Drone](https://drone.io) with [kind](https://kind.sigs.k8s.io/) as your local Kubernetes Cluster.

For complete walk through and explanation checkout my [blog](https://kubesimplify.com/yours-kindly-drone)

## Required tools

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [kind](https://kind.sigs.k8s.io/)
- [Helm](https://helm.sh/)
- [Kustomize](https://kustomize.io/)
- [envsusbst](https://www.man7.org/linux/man-pages/man1/envsubst.1.html)
- [Argo CD CLI](https://github.com/argoproj/argo-cd/releases/latest)

All linux distributions adds **envsubst** via [gettext](https://www.gnu.org/software/gettext/) package. On macOS it can be installed using [Homebrew](https://brew.sh/) like `brew install gettext`.

## Clone the Sources

```shell
git clone https://github.com/kameshsampath/dag && \
  cd "$(basename "$_" .git)"
export DAG_HOME="${PWD}"
```

## Create Kubernetes Cluster

```shell
$DAG_HOME/bin/kind.sh
```

## Gitea

### Deploy Gitea

```shell
helm repo add gitea-charts https://dl.gitea.io/charts/
helm repo update
helm upgrade \
  --install gitea gitea-charts/gitea \
  --values $DAG_HOME/helm_vars/gitea/values.yaml \
  --wait
```

### Configure Gitea

```shell
kubectl apply -k k8s/gitea-config
```

## Deploy ArgoCD

Deploy Argocd, create namespace to deploy argocd

```shell
kubectl create ns argocd
```

Add argocd helm repo,

```shell
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

```shell
export GITEA_HTTP_CLUSTER_IP=$(kubectl get svc gitea-http -ojsonpath='{.spec.clusterIP}'
)
```

Deploy argocd server,

```shell
envsubst < $DAG_HOME/helm_vars/argocd/values.yaml | helm upgrade --install argocd argo/argo-cd \
  --namespace=argocd \
  --wait \
  --values -
```

## Setup Environment

## Gitea URL

```shell
export GITEA_DOMAIN="gitea-127.0.0.1.sslip.io"
export GITEA_URL="http://${GITEA_DOMAIN}:30950"
```

You can access Gitea now in your browser using open `${GITEA_URL}`. Default credentials `demo/demo@123`.

## Drone URL

The URL where Drone Server will be deployed,

```shell
export DRONE_SERVER_HOST="drone-127.0.0.1.sslip.io:30980"
export DRONE_SERVER_URL="http://${DRONE_SERVER_HOST}"
```

## Login to ArgoCD via CLI

```shell
argocd login argocd-127.0.0.1.sslip.io:30080 --insecure --username admin --password='demo@123' 
```

## Cluster Bootstrapping

```shell
argocd app create apps \
  --dest-namespace argocd \
  --dest-server https://kubernetes.default.svc \
  --repo "${GITEA_URL}/demo/dag.git" \
  --path apps  
argocd app sync apps  
```

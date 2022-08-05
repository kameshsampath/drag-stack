# Drone Argo CD Gitea(DAG) Stack

A demo to demonstrate on how to setup [Drone](https://drone.io), [Argo CD](https://argo-cd.readthedocs.io/) and [Gitea](https://gitea.io/) with [kind](https://kind.sigs.k8s.io/) as your local Kubernetes Cluster.

This demo also shows how to use the Argo CD [declarative setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/) to setup [Drone](https://drone.io) with Drone Kubernetes runner.

## Required tools

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [kind](https://kind.sigs.k8s.io/)
- [Helm](https://helm.sh/)
- [Kustomize](https://kustomize.io/)
- [envsusbst](https://www.man7.org/linux/man-pages/man1/envsubst.1.html)
  
### Optional

- [Argo CD CLI](https://github.com/argoproj/argo-cd/releases/latest)
- [direnv](https://direnv.net/)

All linux distributions adds **envsubst** via [gettext](https://www.gnu.org/software/gettext/) package. On macOS it can be installed using [Homebrew](https://brew.sh/) like `brew install gettext`.

## Clone the Sources

```shell
git clone https://github.com/kameshsampath/dag && \
  cd "$(basename "$_" .git)"
export DAG_HOME="${PWD}"
```

## Create Kubernetes Cluster

```shell
$DAG_HOME/back/kind.sh
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

You can access Gitea now in your browser using open <http://gitea-127.0.0.1.sslip.io:30950>. Default credentials `demo/demo@123`.

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
export GITEA_HTTP_CLUSTER_IP=$(kubectl get -n default svc gitea-http -ojsonpath='{.spec.clusterIP}'
)
```

Deploy argocd server,

```shell
envsubst < $DAG_HOME/helm_vars/argocd/values.yaml | helm upgrade --install argocd argo/argo-cd \
  --namespace=argocd \
  --wait \
  --values -
```

## Cluster Bootstrapping

### Setup Environment

Set some variables for convenience,

```shell
export GITEA_DOMAIN="gitea-127.0.0.1.sslip.io"
export GITEA_INCLUSTER_URL="http://gitea-http.default.svc.cluster.local:30950"
export GITEA_URL="http://${GITEA_DOMAIN}:30950"
export GITEA_INTERNAL_URL="http://gitea-http.default.svc.cluster.local:30950"
export GITEA_USER=user-01
export GITEA_DAG_REPO="${GITEA_URL}/${GITEA_USER}/dag.git"
export GITEA_DAG_REPO_INTERNAL="${GITEA_INTERNAL_URL}/${GITEA_USER}/dag.git"
export DRONE_SERVER_HOST="drone-127.0.0.1.sslip.io:30980"
export DRONE_SERVER_URL="http://${DRONE_SERVER_HOST}"
```

Verify we have the `${GITEA_HTTP_CLUSTER_IP}` variable set,

```shell
export GITEA_HTTP_CLUSTER_IP=$(kubectl get -n default svc gitea-http -ojsonpath='{.spec.clusterIP}'
)
```

Update the DAG App `$DAG_HOME/helm_vars/dag/values.yaml` with values matching to the environment,

```shell
envsubst < $DAG_HOME/helm_vars/dag/values.tpl.yaml > $DAG_HOME/helm_vars/dag/values.yaml
```

Commit and push the code to `${GITEA_DAG_REPO}` so that values will be used by the DAG apps argo application that we will create in the next step,

Create DAG App on ArgoCD,

```shell
envsubst < $DAG_HOME/k8s/dag/app.yaml | kubectl apply -f -
```

Trigger app sync

```shell
argocd app sync dag-apps  
```

A successful ArgoCD Deployment of Drone should look as shown below,

![ArgoCD Apps](./docs/images/dag_apps.png)

## Patching Gitea

As we configured Drone to reach gitea using `hostAliases` we also need to configure gitea pods to reach to drone server using Kubernetes internal DNS,

```shell
export DRONE_SERVICE_IP="$(kubectl get svc -n drone drone -ojsonpath='{.spec.clusterIP}')"
kubectl patch statefulset gitea -n default --patch "$(envsubst<$DAG_HOME/k8s/gitea/patch.json)"
```

Wait for the gitea pods to be ready

```shell
kubectl rollout status -n default statefulset gitea --timeout=30s
```

Verify the `/etc/hosts` entries in the gitea pods,

```shell
kubectl exec -it gitea-0 -n default cat /etc/hosts
```

It should have entry like

```shell
# Entries added by HostAliases.
$DRONE_SERVICE_IP   drone-127.0.0.1.sslip.io
```

## Validate Drone Setup

What we have done until now,

- Setup Gitea
- Setup `dag-apps` Argo CD that in turn setup
  - Drone Server
  - Drone Kube Runner

### Add Drone Admin User

Copy the account settings named `Example CLI Usage` from the Drone Account Settings page, verify if its all good,

```shell
drone info
```

Update the DAG App `$DAG_HOME/helm_vars/dag/values.yaml` with values matching to the environment,

```shell
export ENABLE_DRONE_ADMIN=true
envsubst < $DAG_HOME/helm_vars/dag/values.tpl.yaml > $DAG_HOME/helm_vars/dag/values.yaml
```

### Deploy Quickstart App

Let us now login to the Drone Server <http://drone-127.0.0.1.sslip.io:30980/>, follow on screen wizard to login and authorize Drone via Gitea.

**NOTE**: The default Gitea credentials is like `<user-name>/<user-name@123>`

If all went well you should the Drone Dashboard like,

![Drone Dashboard](./docs/images/drone_dashboard)

To ensure our setup works let us click on the `drone-quickstart` project and activate it. You should not see any builds now.

Clone and edit the `drone-quickstart` project and 

- update the type of the pipeline to be `kubernetes`
- add [host_aliases](https://docs.drone.io/pipeline/kubernetes/syntax/hostaliases/) to the `.drone.yml` as shown below

```yaml
host_aliases:
 - ip: $GITEA_HTTP_CLUSTER_IP
   hostnames:
     - gitea-127.0.0.1.sslip.io
```

Commit and push the code to see the build trigger, you check the build status in the Drone Dashboard,

![Drone Dashboard](./docs/images/validation_success)

**Congratulations**!!! You are now a GitOpsian. Add other projects of yours and keep rocking with Drone CI and Argo CD.

## Gotchas

If you are doing local setup with Kind make sure to check the [setup gotchas](./gotchas.md)for some key details.

## Clean up

```shell
kind delete cluster --name=dag
```

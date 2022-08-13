# Drone Argo CD Gitea(DAG) Stack

A demo to demonstrate on how to setup [Drone](https://drone.io), [Argo CD](https://argo-cd.readthedocs.io/) and [Gitea](https://gitea.io/) with [k3d](k3d.io/) as your local **[k3s](https://k3s.io)** based Kubernetes Cluster.

This demo also shows how to use the Argo CD [declarative setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/) to setup [Drone](https://drone.io) with Drone Kubernetes runner.

The stack also deploys [Argo CD Image Updater](https://argocd-image-updater.readthedocs.io/en/stable) to enable updating the application images via GitOps.

## Required tools

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [k3d](https://k3d.io/)
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
$DAG_HOME/hack/cluster.sh
```

## Gitea

The following section details on how to deploy Gitea, which will be used as our git repository enabling GitOps.

### Deploy Gitea

```shell
$DAG_HOME/hack/install-gitea
```

#### Verify Gitea

```shell
$DAG_HOME/hack/check-gitea
```

You can access Gitea now in your browser using open <http://gitea-127.0.0.1.sslip.io:30950>. Default credentials `demo/demo@123`.

### Configure Gitea

```shell
kubectl apply -k k8s/gitea-config
```

Wait for few seconds for the job to complete,

```shell
kubectl wait --for=condition=complete --timeout=120s -n drone job/workshop-setup
```

## Deploy ArgoCD

```shell
$DAG_HOME/hack/install-argocd
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

You can access Argo CD now in your browser using open <http://localhost:30080>. Default credentials `admin/demo@123`.

## Cluster Bootstrapping

The cluster bootstrapping  that we did in earlier step installs the core DAG stack applications ([App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#app-of-apps)) and DAG stack has the following child applications,

- Argo CD Image Updater
- Drone Server
- Droner Runners
- Nexus3 Maven Repository Manager

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

![Drone Dashboard](./docs/images/drone_dashboard.png)

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

![Drone Build Success](./docs/images/validation_success.png)

**Congratulations**!!! You are now a GitOpsian. Add other projects of yours and keep rocking with Drone CI and Argo CD.

Few applications that you can try with this stack,

- <https://github.com/kameshsampath/quarkus-springboot-demo-gitops>
- MERNStack

## Gotchas

If you are doing local setup with Kind make sure to check the [setup gotchas](./gotchas.md)for some key details.

## Clean up

```shell
kind delete cluster --name=dag
```

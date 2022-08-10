#!/bin/sh
set -o errexit

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# create a cluster with the local registry enabled in containerd
# https://k3d.io/v5.4.4/usage/configfile/

envsubst < "$SCRIPT_DIR/k3s-cluster-config.yaml.tpl" > "$SCRIPT_DIR/k3s-cluster-config.yaml"

k3d cluster create -c "$SCRIPT_DIR/k3s-cluster-config.yaml"

## sanity checks

docker pull gcr.io/google-samples/hello-app:1.0
docker tag gcr.io/google-samples/hello-app:1.0 "${REGISTRY_NAME}:${REGISTRY_PORT}/hello-app:1.0"
docker push "${REGISTRY_NAME}:${REGISTRY_PORT}/hello-app:1.0"
kubectl create deployment hello-server --image="${REGISTRY_NAME}:${REGISTRY_PORT}/hello-app:1.0"
kubectl rollout status deployment.apps/hello-server --timeout=30s
kubectl delete deployment.apps/hello-server
#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# create_reg=$(k3d registry ls -o json  | jq -r 'any(.[]; .name == "k3d-docker-io-proxy")')
# # k3d registries are suffixed with k3d-
# if [ "$create_reg" == "false" ];
# then
#   k3d registry create docker-io-proxy \
#     --port 0.0.0.0:5100 \
#     --proxy-remote-url https://registry-1.docker.io \
#     --proxy-username "$DOCKERHUB_USERNAME" \
#     --proxy-password "$DOCKERHUB_PASSWORD" \
#     --volume "/Users/kameshs/MyLabs/.k3s/registry:/var/lib/registry"
# fi

# create_reg=$(k3d registry ls -o json  | jq -r 'any(.[]; .name == "k3d-quay-io-proxy")')
# if [ "$create_reg" == "false" ];
# then
#   k3d registry create quay-io-proxy \
#     --port 0.0.0.0:5200 \
#     --proxy-remote-url https://quay.io \
#     --proxy-username "$QUAYIO_USERNAME" \
#     --proxy-password "$QUAYIO_PASSWORD" \
#     --volume "/Users/kameshs/MyLabs/.k3s/registry:/var/lib/registry"
# fi

# create a cluster with the local registry enabled in containerd
# https://k3d.io/v5.4.4/usage/configfile/

envsubst < "$SCRIPT_DIR/k3s-cluster-config.yaml.tpl" > "$SCRIPT_DIR/k3s-cluster-config.yaml"

k3d cluster create -c "$SCRIPT_DIR/k3s-cluster-config.yaml" --registry-config "$SCRIPT_DIR/registries.yaml"

## sanity checks

# Docker push
# docker pull gcr.io/google-samples/hello-app:1.0
# docker tag gcr.io/google-samples/hello-app:1.0 "${REGISTRY_NAME}:5001/hello-app:1.0"
# docker push "${REGISTRY_NAME}:5001/hello-app:1.0"

# kubectl 
# kubectl create deployment hello-server --image="${REGISTRY_NAME}:5000/hello-app:1.0"
# kubectl rollout status deployment.apps/hello-server --timeout=30s
# kubectl delete deployment.apps/hello-server
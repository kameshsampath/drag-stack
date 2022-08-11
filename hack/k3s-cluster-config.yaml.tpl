apiVersion: k3d.io/v1alpha4
kind: Simple
metadata:
  name: dag
servers: 1
agents: 2
image: rancher/k3s:v1.24.3-k3s1
ports:
  # Drone CI
  - port: 127.0.0.1:30980:30980
    nodeFilters:
      - agent:*
  # Gitea
  - port: 127.0.0.1:30950:30950
    nodeFilters:
      - agent:*
  # Argo CD
  - port: 127.0.0.1:30080:30080
    nodeFilters:
      - agent:*
registries:
  create:
    name: "${REGISTRY_NAME}"
    host: "0.0.0.0"
    hostPort: "${REGISTRY_PORT}"
    volumes:
      - "${PWD}/.k3s/registry:/var/lib/registry"
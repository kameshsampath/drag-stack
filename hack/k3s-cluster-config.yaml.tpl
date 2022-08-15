apiVersion: k3d.io/v1alpha4
kind: Simple
metadata:
  name: dag
servers: 1
# agents: 2
image: rancher/k3s:v1.24.3-k3s1
ports:
  # Drone CI
  - port: 127.0.0.1:30980:30980
    nodeFilters:
      - loadbalancer
  # Gitea
  - port: 127.0.0.1:30950:30950
    nodeFilters:
      - loadbalancer
  # Argo CD
  - port: 127.0.0.1:30080:30080
    nodeFilters:
     - loadbalancer
  # Nexus3 Repo Manager and Registry
  - port: 127.0.0.1:30081:30081
    nodeFilters:
     - loadbalancer
registries:
  create:
      name: "${REGISTRY_NAME}"
      host: "0.0.0.0"
      hostPort: "5001"
      volumes:
        - "/Users/kameshs/MyLabs/.k3s/registry:/var/lib/registry"
#  config: |
#      mirrors:
#        "docker.io":
#           endpoint:
#             - "http://k3d-docker-io-proxy:5100"
#        "quay.io":
#           endpoint:
#             - "http://k3d-quay-io-proxy:5200"
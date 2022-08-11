# Commands

Handy Commands used while debugging and testing.

## Helm Dry Run

```shell
helm install --dry-run --debug  -f <your values file> helloworld ./apps
```

## Kubernetes Dashboard

```shell
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --wait
```

```shell
export POD_NAME=$(kubectl get pods -n default -l "app.kubernetes.io/name=kubernetes-dashboard,app.kubernetes.io/instance=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}")
echo https://127.0.0.1:8443/
kubectl -n default port-forward svc/kubernetes-dashboard 8443:443
```

## dnsmasq

```shell
brew install dnsmaq
```

Edit `/opt/homebrew/etc/dnsmasq.conf` and append `address=/.localhost/127.0.0.1`.

```shell
sudo mkdir -p /etc/resolver/localhost
sudo tee /etc/resolver/localhost > /dev/null <<EOF
nameserver 127.0.0.1
domain localhost
search_order 1
EOF
```

# Commands

Handy Commands used while debugging and testing.

## Helm Dry Run

```shell
helm install --dry-run --debug  -f <your values file> helloworld ./apps
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

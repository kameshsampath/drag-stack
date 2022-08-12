#!/bin/bashsh

set -euxo pipefail

local_reg="$MY_REGISTRY_URL:5000"
img_name="$local_reg/example/hello-app:1.0"
docker pull gcr.io/google-samples/hello-app:1.0
docker tag gcr.io/google-samples/hello-app:1.0 "$img_name"
docker push "$img_name"
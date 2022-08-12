#!/bin/bash

set -euxo pipefail

# Internal 
docker pull gcr.io/google-samples/hello-app:1.0
docker tag gcr.io/google-samples/hello-app:1.0 "${MY_REGISTRY_URL}/example/hello-app:1.0"
docker push  "${MY_REGISTRY_URL}/example/hello-app:1.0"

# External
docker pull gcr.io/google-samples/hello-app:1.0
docker tag gcr.io/google-samples/hello-app:1.0 "${MY_REGISTRY_EXTERNAL_URL}/example/hello-app:1.0"
docker push  "${MY_REGISTRY_EXTERNAL_URL}/example/hello-app:1.0"
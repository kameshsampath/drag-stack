#!/usr/bin/env bash

set -uo pipefail

curl -X POST -H 'Content-Type: application/xml' -u "${ADMIN_USER_NAME}:${ADMIN_USER_PASSWORD}"  "artifactory.${POD_NAMESPACE}:8081/artifactory/api/system/configuration" -d @/config/config.xml

printf "\n Artifactory Configuration Updated\n"
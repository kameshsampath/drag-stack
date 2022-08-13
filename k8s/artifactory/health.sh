#!/usr/bin/env bash

set -uo pipefail

ARTIFACTORY_URL="http://artifactory.infra:8081/artifactory"

res_code=$(curl --silent --fail --output /dev/null -w '%{http_code}' "${ARTIFACTORY_URL}")

until [ "$res_code" -ne 000 ] &&  [ "$res_code" -lt 400 ];
do
  sleep 5
	res_code=$(curl --silent --fail --output /dev/null -w '%{http_code}' "${ARTIFACTORY_URL}")
done

printf "\n API Ready\n"
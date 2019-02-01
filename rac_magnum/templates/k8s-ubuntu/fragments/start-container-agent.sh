#!/bin/bash

. /etc/default/heat-params

set -ux

_prefix=${CONTAINER_INFRA_PREFIX:-docker.io/openstackmagnum/}
docker pull ${_prefix}heat-container-agent

docker run -d ${_prefix}heat-container-agent

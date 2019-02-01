#!/bin/bash

. /etc/default/heat-params

opts="-H fd:// -H tcp://0.0.0.0:2375 "

if [ "$TLS_DISABLED" = 'False' ]; then
    opts=$opts"--tlsverify --tlscacert=/etc/docker/ca.crt "
    opts=$opts"--tlskey=/etc/docker/server.key "
    opts=$opts"--tlscert=/etc/docker/server.crt "
fi

DOCKER_CONF=/etc/systemd/system/docker.service.d/execstart.conf

mkdir -p /etc/systemd/system/docker.service.d
cat <<EOF  > $DOCKER_CONF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd $opts
EOF

systemctl daemon-reload
systemctl --no-block restart docker.service

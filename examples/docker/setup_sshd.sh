#!/bin/bash

set -euo pipefail

: ${CT_IMAGE:='hpc-benchmarks:24.06-efa-1.11.0-aws'}
: ${CT_NAME:="hpc-benchmarks"}
: ${CT_START_OPTS="--gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 --privileged"}
: ${PUB_SSH_KEY:="$(cat ~/.ssh/id_rsa.pub)"}
: ${HOST_FILE:="$(realpath ~/.ssh/mpi_hosts.txt)"}
: ${SSH_PORT:=2222}



function ct_exec()
{
    docker exec $CT_NAME bash -c "$@"
}

# Start stateless container with host network to minimize difference with system case
# enable privileged capabilities so sched_setaffinity(2) will works
docker run \
       -d \
       --network=host --privileged  \
       --rm \
       --name $CT_NAME \
       $CT_START_OPTS \
       $CT_IMAGE  \
       bash -c "mkdir /run/sshd; /usr/sbin/sshd -D -p $SSH_PORT"
# Setup passworldless ssh connect
ct_exec "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config"
ct_exec "mkdir -p /root/.ssh && echo \"$PUB_SSH_KEY\" >> /root/.ssh/authorized_keys"
ct_exec " cat > /root/.ssh/config <<EOF
   StrictHostKeyChecking no
   UserKnownHostsFile /dev/null
   LogLevel QUIET
   Port ${SSH_PORT}
EOF"
ct_exec "chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys"
docker cp $HOST_FILE $CT_NAME:/root/.ssh/mpi_hosts.txt

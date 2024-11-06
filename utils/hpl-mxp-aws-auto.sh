#!/bin/bash

readonly INSTANCE_TYPE=$(cat /sys/devices/virtual/dmi/id/product_name)
readonly SCRIPT_DIR="$(readlink -f "$(dirname "$0")")"
readonly ENV_FILE="$SCRIPT_DIR/aws-env/$INSTANCE_TYPE"

if [ ! -f $ENV_FILE ]
then
    echo "Unknown instance type: $INSTANCE_TYPE"
    exit 1
fi

source $ENV_FILE

/workspace/hpl-mxp.sh \
    --gpu-affinity "$GPU_AFFINITY" \
    --mem-affinity "$MEM_AFFINITY" \
    --cpu-affinity "$CPU_AFFINITY" \
    $@

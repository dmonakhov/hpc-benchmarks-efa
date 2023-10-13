#!/bin/bash

export NCCL_NET='AWS Libfabric'
export FI_EFA_USE_DEVICE_RDMA=1
export HPL_FCT_COMM_POLICY=1
export HPL_USE_NVSHMEM=0

/workspace/hpl.sh \
    --mem-affinity 0:0:0:0:1:1:1:1 \
    --cpu-affinity 0-11:12-23:24-35:36-47:48-59:60-71:72-83:84-95 \
    $@

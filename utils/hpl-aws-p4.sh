#!/bin/bash

export NCCL_NET='AWS Libfabric'
export FI_EFA_USE_DEVICE_RDMA=1
export HPL_FCT_COMM_POLICY=1
export HPL_USE_NVSHMEM=0

/workspace/hpl.sh \
    ./hpl.sh --mem-affinity 0:0:0:0:1:1:1:1 \
    --cpu-affinity 0-3:4-7:8-11:12-15:24-27:28-31:32-35:36-49 \
    $@

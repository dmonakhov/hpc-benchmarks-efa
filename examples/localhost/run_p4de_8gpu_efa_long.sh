#!/bin/bash

# Run HPL on localhost, all compunications only via EFA
# Perform 10 iterations of long warmup 80%
# Runtime: ~240sec * 10 = 2400s =>  ~40min

DIR=$(dirname $0)
mpirun --bind-to none \
       -x NCCL_DEBUG=INFO \
       -x NCCL_SHM_DISABLE=1 \
       -x NCCL_P2P_DISABLE=1 \
       -x NCCL_NET='AWS Libfabric' \
       -x LD_LIBRARY_PATH=/usr/local/cuda/efa/lib:$LD_LIBRARY_PATH \
       -np 8 \
       $DIR/hpl_10iters.sh --mem-affinity 0:0:0:0:1:1:1:1 \
       --cpu-affinity 0-3:4-7:8-11:12-15:24-27:28-31:32-35:36-49 \
       --no-multinode $@

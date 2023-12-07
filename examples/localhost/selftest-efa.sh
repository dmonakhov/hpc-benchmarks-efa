#!/bin/bash

docker run --rm -it --privileged --gpus all --shm-size=1g \
       -v $(pwd):/efa \
       hpc-benchmarks:23.10-efa-1.7.4-aws \
       mpirun --bind-to none --timeout 3600 \
       -np 8 \
       -x NCCL_DEBUG=INFO \
       -x NCCL_SHM_DISABLE=1 \
       -x NCCL_P2P_DISABLE=1 \
       /efa/utils/hpl-aws-auto.sh --dat hpl-linux-x86_64/sample-dat/HPL-8GPUs.dat

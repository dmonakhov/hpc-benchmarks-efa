#!/bin/bash

docker run --pull=never --rm --privileged --gpus all --shm-size=1g \
       -v $(pwd):/efa \
       hpc-benchmarks:24.06-efa-1.11.0-aws \
       mpirun --bind-to none --timeout 36000 \
       -np 8 \
       -x NCCL_DEBUG=INFO \
       -x TEST_LOOPS=100 \
       -x WARMUP_END_PROG=80 \
       /efa/utils/hpl-aws-auto.sh --dat hpl-linux-x86_64/sample-dat/HPL-8GPUs.dat

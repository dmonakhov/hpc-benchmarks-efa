#!/bin/bash

#Run xhpl on vanilla container
docker run --rm -it --privileged --gpus all --shm-size=1g \
       -v $(pwd):/efa \
       nvcr.io/nvidia/hpc-benchmarks:23.10 \
       mpirun --bind-to none --timeout 3600 \
       -np 8 \
       -x NCCL_DEBUG=INFO \
       -x NCCL_NET="Socket" \
       /efa/utils/hpl-aws-auto.sh  --no-multinode --dat hpl-linux-x86_64/sample-dat/HPL-8GPUs.dat

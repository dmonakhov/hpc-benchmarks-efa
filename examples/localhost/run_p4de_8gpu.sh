#!/bin/bash

# Run HPL on localhost, using all transport
# Runtime: ~100sec

mpirun --bind-to none \
       -np 8 \
       ./hpl.sh --mem-affinity 0:0:0:0:1:1:1:1 \
       --cpu-affinity 0-3:4-7:8-11:12-15:24-27:28-31:32-35:36-49 \
       --no-multinode $@

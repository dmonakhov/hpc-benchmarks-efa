# hpc-benchmarks-efa
Docker image based on the NVIDIA [hpc-benchmarks image](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/hpc-benchmarks) with EFA support.

# Build
make build
# Run selftest on single P4De.24xlarge instance
```

# Run basic check with all transports
docker run --rm -it --privileged --gpus all --shm-size=1g \
       -v $(pwd)/examples/localhost:/hpl \
       hpc-benchmarks:23.10-efa-1.7.4-aws \
       mpirun --bind-to none --timeout 3600 \
       -np 8 \
       -x NCCL_DEBUG=INFO \
       ./hpl-aws-auto.sh --dat hpl-linux-x86_64/sample-dat/HPL-8GPUs.dat

# Run basic check with EFA only transport
docker run --rm -it --privileged --gpus all --shm-size=1g \
       -v $(pwd)/examples/localhost:/hpl \
       hpc-benchmarks:23.10-efa-1.7.4-aws \
       mpirun --bind-to none --timeout 3600 \
       -np 8 \
       -x NCCL_DEBUG=INFO \
       -x NCCL_SHM_DISABLE=1 \
       -x NCCL_P2P_DISABLE=1 \
       ./hpl-aws-auto.sh --dat hpl-linux-x86_64/sample-dat/HPL-8GPUs.dat
```

# Run slurm job on p5.48xlarge cluster of 8 nodes
```
# import as squashfs image
make  enroot-img EXPORT_PATH=/fsx/ct-img
# run job
srun -N 8 --ntasks-per-node 8 --mpi=pmix --container-image=/fsx/ct-img/hpc-benchmarks+23.5-efa-1.7.3-aws.sqsh \
     ./hpl-aws-p5.sh --dat ./hpl-linux/sample-dat/HPL-dgx-8N.dat
```
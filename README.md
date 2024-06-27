# hpc-benchmarks-efa
Docker image based on the NVIDIA [hpc-benchmarks image](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/hpc-benchmarks) with EFA support.

# Build
```
make build
```
# Run selftests on single P4,P5 instance
```
# Run all singlehost selftests
make check

# Run individual selftests
make check-nvlink
make check-efa
```

# Run slurm job on p5.48xlarge cluster of 2 nodes
```
# import as squashfs image, will be saved to /fsx/app/hpc-benchmarks+24.03-efa-1.9.1-aws.sqsh
make  enroot-img EXPORT_PATH=/fsx/app

# run a job
srun --mpi=pmi2 \
     -N 2 --ntasks-per-node 8 \
     --container-image=/fsx/app/hpc-benchmarks+24.03-efa-1.9.1-aws.sqsh \
     ./hpl-aws-auto.sh --dat hpl-linux-x86_64/sample-dat/HPL-dgx-2N.dat
```

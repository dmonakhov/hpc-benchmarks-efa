# hpc-benchmarks-efa
Docker image based on the NVIDIA [hpc-benchmarks image](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/hpc-benchmarks) with EFA support.

# Build
docker build  --tag=hpc-benchmarks:23.5-efi .
# Run selftest on single P4De.24xlarge instance
```
docker run --rm -it --privileged --gpus all --shm-size=1g \
    -v (pwd)/examples/localhost:/hpl hpc-benchmarks:23.5-efi \
    /hpl/run_p4de_8gpu_efa.sh --dat hpl-linux/sample-dat/HPL-dgx-1N.dat

```

# Run slurm job on p5.48xlarge cluster of 8 nodes
```
# import as squashfs image
make  enroot-img EXPORT_PATH=/fsx/ct-img
# run job
srun -N 8 --ntasks-per-node 8 --mpi=pmix --container-image=/fsx/ct-img/hpc-benchmarks+23.5-efa-1.7.3-aws.sqsh \
     ./hpl-aws-p5.sh --dat ./hpl-linux/sample-dat/HPL-dgx-8N.dat
```
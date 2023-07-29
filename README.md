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

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
# Run hpl-mxp on P5 instance
```
# Run 20 iterations of xhpl-mxp, each iter takes ~4min, total runtime expected ~1.5hours
time docker run --pull=never --rm --privileged --gpus all --shm-size=1g \
     nvcr.io/nvidia/hpc-benchmarks:24.03 \
     mpirun --bind-to none --timeout 6000 -np 8  \
     ./hpl-mxp.sh  --nb 2048 --nprow 2 --npcol 4 --nporder row \
     --gpu-affinity 0:1:2:3:4:5:6:7 \
     --cpu-affinity 0-11:12-23:24-35:36-47:48-59:60-71:72-83:84-95 \
     --mem-affinity 0:0:0:0:1:1:1:1 \
     --n 380000 --test-loop 20
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

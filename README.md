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
# It is possible to run hpl-mxp on a single host with vanilla container
```
# Run 20 iterations of xhpl-mxp, each iter takes ~4min, total runtime expected ~1.5hours
time docker run --pull=never  --rm --privileged --gpus all --shm-size=1g \
       -v $(pwd):/host \
       nvcr.io/nvidia/hpc-benchmarks:24.09 \
       mpirun --bind-to none --timeout 6000 -np 8  \
       /host/utils/hpl-mxp-aws-auto.sh  \
       --nb 2048 --nprow 2 --npcol 4 --nporder row \
       --n 380000
```
# Run slurm job on p5.48xlarge cluster of 2 nodes
```
## import as squashfs image, will be saved to /fsx/app/hpc-benchmarks+24.09-efa-1.11.0-aws.sqsh
make  enroot-img EXPORT_PATH=/fsx/app

## run a job
srun --mpi=pmi2 \
     -N 2 --ntasks-per-node 8 \
     --container-image=/fsx/app/hpc-benchmarks+24.09-efa-1.11.0-aws.sqsh \
     ./hpl-aws-auto.sh --dat hpl-linux-x86_64/sample-dat/HPL-dgx-2N.dat
```


# Run multihost tests with plain docker.
If SLURM or other cluster aware runtime is not available it is possible to run multihosts tests with docker like container runtime.
Preconditions: docker, openmpi and passwordless ssh access.

```
# build container images
make build tar-img
# Deploy container to all hostsfile default MPI_HOSTFILE=~/.ssh/mpi_hosts.txt
make mpi-deploy-img
# On each node we start container with sshd, see [examples/docker/setup_sshd.sh]
make mpi-ssh-container-create

# Run xhpl test via docker exec on 16 nodes.
./examples/docker/mpirun.docker \
	-bind-to none \
	-hostfile /root/.ssh/mpi_hosts.txt \
	-N 8 -np 128 \
	./hpl-aws-auto.sh --dat hpl-linux-x86_64/sample-dat/HPL-dgx-16N.dat
```
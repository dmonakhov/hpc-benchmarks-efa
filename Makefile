IMAGE_NAME ?= hpc-benchmarks
IMAGE_BASE_REPO=nvcr.io/nvidia/
IMAGE_BASE_TAG  ?= 24.06
AWS_OFI_NCCL_VER ?= 1.11.0-aws
AWS_EFA_INSTALLER_VER ?=1.34.0

# podman:// or dockerd://
CT_RUNTIME ?= dockerd://
EXPORT_PATH ?= ..
ZSTD_COMPRESS_OPTIONS ?= --ultra -22

TAG=${IMAGE_BASE_TAG}-efa-${AWS_OFI_NCCL_VER}
MPI_HOSTFILE ?= ~/.ssh/mpi_hosts.txt


fetch:
	docker pull "${IMAGE_BASE_REPO}${IMAGE_NAME}:${IMAGE_BASE_TAG}"
build:
	docker build --progress plain --rm \
		--tag "${IMAGE_NAME}:${TAG}" \
		--build-arg AWS_OFI_NCCL_VER="${AWS_OFI_NCCL_VER}" \
		--build-arg AWS_EFA_INSTALLER_VER=${AWS_EFA_INSTALLER_VER} .

tar-img:
	docker save \
		"${IMAGE_BASE_REPO}${IMAGE_NAME}:${IMAGE_BASE_TAG}" \
		"${IMAGE_NAME}:${TAG}"  | \
		zstdmt ${ZSTD_COMPRESS_OPTIONS} -v -f -o ${EXPORT_PATH}/${IMAGE_NAME}-${TAG}.tar.zst
mpi-deploy-img:
	# MPICAT see https://github.com/dmonakhov/gpu_toolbox/blob/main/mpitools/README.md#cat1-for-mpi-environment	
	cat ${EXPORT_PATH}/${IMAGE_NAME}-${TAG}.tar.zst | \
	mpirun -N 1 -hostfile ${MPI_HOSTFILE} bash -c 'mpicat | zstdcat | docker load'

enroot-img:
	if [ -e ${EXPORT_PATH}/${IMAGE_NAME}+${TAG}.sqsh ]; then unlink ${EXPORT_PATH}/${IMAGE_NAME}+${TAG}.sqsh; fi
	enroot import -o ${EXPORT_PATH}/${IMAGE_NAME}+${TAG}.sqsh ${CT_RUNTIME}${IMAGE_NAME}:${TAG}

check-nvlink:
	examples/localhost/selftest-vanilla.sh

check-efa:
	examples/localhost/selftest-efa.sh

check: check-nvlink check-efa

mpi-ssh-container-create:
	tar -c  -C examples/docker setup_sshd.sh | mpirun -N 1 -hostfile ${MPI_HOSTFILE} bash -c 'mpicat | tar xv -C /tmp/'
	mpirun -N 1 -hostfile ${MPI_HOSTFILE} /tmp/setup_sshd.sh
	docker cp ~/.ssh/id_rsa hpc-benchmarks:/root/.ssh/id_rsa

mpi-ssh-container-destroy:
	mpirun -N 1 -hostfile ${MPI_HOSTFILE} docker stop hpc-benchmarks 

mpi-ssh-container-test:
	./examples/docker/mpirun.docker -N 8 -np 16 -bind-to none -hostfile /root/.ssh/mpi_hosts.txt ./hpl-aws-auto.sh --dat hpl-linux-x86_64/sample-dat/HPL-dgx-2N.dat

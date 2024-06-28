IMAGE_NAME ?= hpc-benchmarks
IMAGE_BASE_REPO=nvcr.io/nvidia/
IMAGE_BASE_TAG  ?= 24.03
AWS_OFI_NCCL_VER ?= 1.9.1-aws
AWS_EFA_INSTALLER_VER ?=1.32.0

# podman:// or dockerd://
CT_RUNTIME ?= dockerd://
EXPORT_PATH ?= ..
ZSTD_COMPRESS_OPTIONS ?= --ultra -22

TAG=${IMAGE_BASE_TAG}-efa-${AWS_OFI_NCCL_VER}
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

enroot-img:
	if [ -e ${EXPORT_PATH}/${IMAGE_NAME}+${TAG}.sqsh ]; then unlink ${EXPORT_PATH}/${IMAGE_NAME}+${TAG}.sqsh; fi
	enroot import -o ${EXPORT_PATH}/${IMAGE_NAME}+${TAG}.sqsh ${CT_RUNTIME}${IMAGE_NAME}:${TAG}

check-nvlink:
	examples/localhost/selftest-vanilla.sh

check-efa:
	examples/localhost/selftest-efa.sh

check: check-nvlink check-efa

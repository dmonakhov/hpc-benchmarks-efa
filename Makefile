IMAGE_NAME ?= hpc-benchmarks
IMAGE_BASE_TAG  ?= 23.5
AWS_OFI_NCCL_VER ?= 1.7.3-aws
EXPORT_PATH ?= ..

ENROOT_SQUASH_OPTIONS ?= -comp lzo

# podman:// or dockerd://
CT_RUNTIME ?= podman://

TAG=${IMAGE_BASE_TAG}-efa-${AWS_OFI_NCCL_VER}
build:
	docker build --rm \
		--tag "${IMAGE_NAME}:${TAG}" \
		--build-arg AWS_OFI_NCCL_VER="${AWS_OFI_NCCL_VER}" .

tar-img: build
	docker save "${IMAGE_NAME}:${TAG}"  | \
		zstdmt -v --ultra -21 -f -o ${EXPORT_PATH}/${IMAGE_NAME}-${TAG}.tar.zst

enroot-img: build
	ENROOT_SQUASH_OPTIONS="${ENROOT_SQUASH_OPTIONS}" \
		enroot import -o ${EXPORT_PATH}/${IMAGE_NAME}+${TAG}.sqsh ${CT_RUNTIME}${IMAGE_NAME}:${TAG}

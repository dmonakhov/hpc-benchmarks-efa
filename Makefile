IMAGE_NAME ?= hpc-benchmarks
IMAGE_BASEE_TAG  ?= 23.5
AWS_OFI_NCCL_VER ?= 1.7.2-aws

build:
	docker build --tag "${IMAGE_NAME}:${IMAGE_BASEE_TAG}-efa-${AWS_OFI_NCCL_VER}" .

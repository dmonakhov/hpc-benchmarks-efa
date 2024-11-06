#!/bin/bash


set -xeu -o pipefail

case "$(cat /sys/devices/virtual/dmi/id/product_name)" in
    p4d.24xlarge)
	DAT_FILE=/host/utils/hpl-linux-x86_64/sample-dat/HPL-dgx-8GPU-40G.dat
	GFLOPS=15000
	;;
    p4de.24xlarge)
	DAT_FILE=hpl-linux-x86_64/sample-dat/HPL-8GPUs.dat
	GFLOPS=16000
	;;
    p5.48xlarge)
	DAT_FILE=hpl-linux-x86_64/sample-dat/HPL-8GPUs.dat
	GFLOPS=42000
	;;
    p5e.48xlarge|p5en.48xlarge)
	DAT_FILE=hpl-linux-x86_64/sample-dat/HPL-H200-8GPUs.dat
	GFLOPS=46000
	;;
    *)
	echo "Unknown instance type: $INSTANCE_TYPE"
	exit 1
	;;
esac



#Run xhpl on vanilla container
docker run --pull=never  --rm --privileged --gpus all --shm-size=1g \
       -v $(pwd):/host \
       nvcr.io/nvidia/hpc-benchmarks:24.06 \
       mpirun --bind-to none --timeout 300 \
       -np 8 \
       -x NCCL_DEBUG=INFO \
       -x NCCL_NET="Socket" \
       /host/utils/hpl-aws-auto.sh  --no-multinode --dat $DAT_FILE | tee hpl_report.log

# Check performance
utils/hpl-parse-report.py --json --min-gflops $GFLOPS  hpl_report.log

exit 0

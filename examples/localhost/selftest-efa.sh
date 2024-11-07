#!/bin/bash


set -xeu -o pipefail

case "$(cat /sys/devices/virtual/dmi/id/product_name)" in
    p4d.24xlarge)
	DAT_FILE=/host/utils/hpl-linux-x86_64/sample-dat/HPL-dgx-8GPU-40G.dat
	GFLOPS=7700
	;;
    p4de.24xlarge)
	DAT_FILE=hpl-linux-x86_64/sample-dat/HPL-8GPUs.dat
	GFLOPS=11000
	;;
    p5.48xlarge)
	DAT_FILE=hpl-linux-x86_64/sample-dat/HPL-8GPUs.dat
	GFLOPS=39500
	;;
    p5e.48xlarge)
	DAT_FILE=hpl-linux-x86_64/sample-dat/HPL-H200-8GPUs.dat
	GFLOPS=45000
	;;
    *)
	echo "Unknown instance type: $INSTANCE_TYPE"
	exit 1
	;;
esac



#Run xhpl on vanilla container
docker run --pull=never  --rm  --privileged --gpus all --shm-size=1g \
       -v $(pwd):/host \
       hpc-benchmarks:24.09-efa-1.11.0-aws \
       mpirun --bind-to none --timeout 300 \
       -np 8 \
       -x NCCL_DEBUG=INFO \
       -x NCCL_SHM_DISABLE=1 \
       -x NCCL_P2P_DISABLE=1 \
       -x NCCL_NVLS_ENABLE=0 \
     /host/utils/hpl-aws-auto.sh  --no-multinode --dat $DAT_FILE | tee hpl_report.log

# Check performance
utils/hpl-parse-report.py --json --min-gflops $GFLOPS  hpl_report.log

exit 0

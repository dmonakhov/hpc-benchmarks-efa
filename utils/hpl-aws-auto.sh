#!/bin/bash

INSTANCE_TYPE=$(cat /sys/devices/virtual/dmi/id/product_name)
WDIR=$(dirname $0)

case $INSTANCE_TYPE in
    p4d.24xlarge|p4de.24xlarge)
	BIN=$WDIR/hpl-aws-p4.sh
	;;
    p5.48xlarge)
	BIN=$WDIR/hpl-aws-p5.sh
	;;
    p5e.48xlarge)
	BIN=$WDIR/hpl-aws-p5e.sh
	;;
    *)
	echo "Unknown instance type: $INSTANCE_TYPE"
	exit 1
	;;
esac

$BIN $@

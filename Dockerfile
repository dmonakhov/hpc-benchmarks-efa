# syntax=docker/dockerfile:1

FROM nvcr.io/nvidia/hpc-benchmarks:24.03
ARG AWS_OFI_NCCL_VER=1.8.1-aws
ARG AWS_EFA_INSTALLER_VER=1.30.0
ARG CUDA_HOME=/usr/local/cuda-12.2
ARG BDIR=/tmp/bld

RUN apt-get update -y && \
    apt-get install -y \
	    libhwloc-dev \
	    libtool \
	    autoconf \
	    openssh-server && \
    mkdir $BDIR && \
    cd $BDIR && \
    curl -sL https://efa-installer.amazonaws.com/aws-efa-installer-${AWS_EFA_INSTALLER_VER}.tar.gz | tar zx && \
    cd aws-efa-installer && \
    ./efa_installer.sh -k -y -n && \
     apt-get remove openmpi*aws -y && \
    cd .. && \
    curl -sL https://github.com/aws/aws-ofi-nccl/releases/download/v${AWS_OFI_NCCL_VER}/aws-ofi-nccl-${AWS_OFI_NCCL_VER}.tar.gz | tar zxv && \
    cd aws-ofi-nccl-${AWS_OFI_NCCL_VER} && \
    ./autogen.sh  && \
    ./configure --with-libfabric=/opt/amazon/efa \
		--with-cuda=/usr/local/cuda \
		--with-mpi=/opt/hpcx/ompi/ \
		--enable-platform-aws \
		--prefix ${CUDA_HOME}/efa && \
    make -j && make install && \
    echo /usr/local/cuda/efa/lib > /etc/ld.so.conf.d/aws-ofi-nccl.conf && \
    cd / && \
    rm -rf $BDIR && \
    apt-get remove -y libhwloc-dev libtool autoconf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
       /usr/share/doc /usr/share/doc-base \
       /usr/share/man /usr/share/locale /usr/share/zoneinfo
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${CUDA_HOME}/efa/lib
COPY utils/*.sh /workspace/


MAINTAINER Monakhov Dmitry monakhov@amazon.com

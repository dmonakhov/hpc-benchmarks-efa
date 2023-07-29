#!/bin/bash

# FIXME - workaround for Singularity
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

export UCX_WARN_UNUSED_ENV_VARS=n

export OMP_PROC_BIND=TRUE
export OMP_PLACES=sockets

export NVSHMEM_DISABLE_CUDA_VMM=1
export NVSHMEM_SYMMETRIC_SIZE=${NVSHMEM_SYMMETRIC_SIZE:-4G}

# Global settings
export MONITOR_GPU=${MONITOR_GPU:-0}
export GPU_TEMP_WARNING=${GPU_TEMP_WARNING:-75}
export GPU_CLOCK_WARNING=${GPU_CLOCK_WARNING:-1400}
export GPU_POWER_WARNING=${GPU_POWER_WARNING:-400}
export GPU_PCIE_GEN_WARNING=${GPU_PCIE_GEN_WARNING:-3}
export GPU_PCIE_WIDTH_WARNING=${GPU_PCIE_WIDTH_WARNING:-2}

export TEST_LOOPS=${TEST_LOOPS:-10}
export WARMUP_END_PROG=${WARMUP_END_PROG:-80}

# HPL specific
# Default values are used. See `TUNING` file

# HPL-AI specific
export MAX_H2D_MS=200
export MAX_D2H_MS=200
export TRSM_CUTOFF=9000000
export USE_LP_GEMM=3
export PAD_LDA_ODD=64
export NUM_WORK_BUF=3
export FACT_GEMM_PRINT=0
export FACT_GEMM=1
export FACT_GEMM_MIN=0 #32
export TEST_SYSTEM_PARAMS_COUNT=0
export CPU_CORES_PER_RANK=8
export MKL_NUM_THREADS=$CPU_CORES_PER_RANK
export OMP_NUM_THREADS=$CPU_CORES_PER_RANK
MNB=12288
NB=1024
export FACT_IC_OS_ROWS=$MNB
export FACT_IC_OS_COLS=$NB
export SORT_RANKS=0
export PRINT_SCALE=2.0
export TEST_SYSTEM_PARAMS=0 
export CUDA_DEVICE_MAX_CONNECTIONS=16
export CUDA_COPY_SPLIT_THRESHOLD_MB=1
export GPU_DGEMM_SPLIT=1.0
export GPU_GEMM_SPLIT=1.0
export ICHUNK_SIZE=$NB
export CHUNK_SIZE=$MNB
export SCHUNK_SIZE=$MNB
export MKL_DEBUG_CPU_TYPE=5


usage() {
  echo ""
  echo "$(basename $0) [OPTION]"
  echo "    --dat <string>                path to HPL.dat"
  echo "    --xhpl-ai                     use the HPL-AI-NVIDIA benchmark"
  echo "    --cuda-compat                 manually enable CUDA forward compatibility"
  echo "    --no-multinode                enable flags for no-multinode (no-network) execution"
  echo "    --gpu-affinity <string>       colon separated list of gpu indices"
  echo "    --cpu-affinity <string>       colon separated list of cpu index ranges"  
  echo "    --mem-affinity <string>       colon separated list of memory indices"
  echo "    --ucx-affinity <string>       colon separated list of UCX devices"
  echo "    --ucx-tls <string>            UCX transport to use"
  echo "    --exec-name <string>          HPL executable file"
  echo ""
}

info() {
  local msg=$*
  echo -e "INFO: ${msg}"
}

warning() {
  local msg=$*
  echo -e "WARNING: ${msg}"
}

error() {
  local msg=$*
  echo -e "ERROR: ${msg}"
  exit 1
}

 
# split the affinity string, e.g., '0:2:4:6' into an array,
# e.g., map[0]=0, map[1]=2, ...  The array index is the MPI rank.
read_gpu_affinity_map() {
    local affinity_string=$1
    readarray -t GPU_AFFINITY_MAP <<<"$(tr ':' '\n'<<<"$affinity_string")"
}

# split the affinity string, e.g., '0:2:4:6' into an array,
# e.g., map[0]=0, map[1]=2, ...  The array index is the MPI rank.
read_net_affinity_map() {
    local affinity_string=$1
    readarray -t NET_AFFINITY_MAP <<<"$(tr ':' '\n'<<<"$affinity_string")"
}

# split the affinity string, e.g., '0:2:4:6' into an array,
# e.g., map[0]=0, map[1]=2, ...  The array index is the MPI rank.
read_mem_affinity_map() {
    local affinity_string=$1
    readarray -t MEM_AFFINITY_MAP <<<"$(tr ':' '\n'<<<"$affinity_string")"
}

# split the affinity string, e.g., '0:2:4:6' into an array,
# e.g., map[0]=0, map[1]=2, ...  The array index is the MPI rank.
read_cpu_affinity_map() {
    local affinity_string=$1
    readarray -t CPU_AFFINITY_MAP <<<"$(tr ':' '\n'<<<"$affinity_string")"
}

# set PMIx client configuration to match the server
# enroot already handles this, so only do this under singularity
# https://github.com/NVIDIA/enroot/blob/master/conf/hooks/extra/50-slurm-pmi.sh
set_pmix() {
    if [ -d /.singularity.d ]; then
        if [ -n "${PMIX_PTL_MODULE-}" ] && [ -z "${PMIX_MCA_ptl-}" ]; then
            export PMIX_MCA_ptl=${PMIX_PTL_MODULE}
        fi
        if [ -n "${PMIX_SECURITY_MODE-}" ] && [ -z "${PMIX_MCA_psec-}" ]; then
            export PMIX_MCA_psec=${PMIX_SECURITY_MODE}
        fi
        if [ -n "${PMIX_GDS_MODULE-}" ] && [ -z "${PMIX_MCA_gds-}" ]; then
            export PMIX_MCA_gds=${PMIX_GDS_MODULE}
        fi
    fi
}

### main script starts here
XHPL=/workspace/hpl-linux-x86_64/xhpl

# Read command line arguments
while [ "$1" != "" ]; do
  case $1 in
   --cuda-compat )
      export LD_LIBRARY_PATH="/usr/local/cuda/compat:$LD_LIBRARY_PATH"
      ;;
    --no-multinode )
      export NVSHMEM_REMOTE_TRANSPORT=none
      ;;
    --dat )
      if [ -n "$2" ]; then
        DAT="$2"
      else
        usage
        exit 1
      fi
      shift
      ;;
    --exec-name )
        XHPL=$2
        shift
        ;;
    --xhpl-ai )
      XHPL=/workspace/hpl-ai-linux-x86_64/xhpl_ai
      ;;
    --ucx-tls )
      if [ -n "$2" ]; then
        export UCX_TLS="$2"
      else
        usage
        exit 1
      fi
      shift
      ;;
    --ucx-affinity )
      if [ -n "$2" ]; then
        NET_AFFINITY="$2"
      else
        usage
        exit 1
      fi
      shift
      ;;
    --gpu-affinity )
      if [ -n "$2" ]; then
        GPU_AFFINITY="$2"
      else
        usage
        exit 1
      fi
      shift
      ;;
    --mem-affinity )
      if [ -n "$2" ]; then
        MEM_AFFINITY="$2"
      else
        usage
        exit 1
      fi
      shift
      ;;
    --cpu-affinity )
      if [ -n "$2" ]; then
        CPU_AFFINITY="$2"
      else
        usage
        exit 1
      fi
      shift
      ;;
  * )
    usage
    exit 1
  esac
  shift
done

# Setup PMIx, if using
if [[ -z "${SLURM_MPI_TYPE-}" || "${SLURM_MPI_TYPE}" == pmix* ]]; then
  set_pmix
fi

read_rank() {
  # Global rank
  if [ -n "${OMPI_COMM_WORLD_RANK}" ]; then
    RANK=${OMPI_COMM_WORLD_RANK}
  elif [ -n "${PMIX_RANK}" ]; then
    RANK=${PMIX_RANK}
  elif [ -n "${PMI_RANK}" ]; then
    RANK=${PMI_RANK}
  elif [ -n "${SLURM_PROCID}" ]; then
    RANK=${SLURM_PROCID}
  else
    warning "could not determine rank"
  fi

  # Node local rank
  if [ -n "${OMPI_COMM_WORLD_LOCAL_RANK}" ]; then
    LOCAL_RANK=${OMPI_COMM_WORLD_LOCAL_RANK}
  elif [ -n "${SLURM_LOCALID}" ]; then
    LOCAL_RANK=${SLURM_LOCALID}
  else
    error "could not determine local rank"
  fi
}

if [[ -n "${NET_AFFINITY}" ]]; then
  read_rank
  read_net_affinity_map $NET_AFFINITY
  NET=${NET_AFFINITY_MAP[$LOCAL_RANK]}
  if [ -n "${NET}" ]; then
    export UCX_NET_DEVICES="$NET:1"
  fi
fi

if [[ -n "${GPU_AFFINITY}" ]]; then
  read_rank
  read_gpu_affinity_map $GPU_AFFINITY
  GPU=${GPU_AFFINITY_MAP[$LOCAL_RANK]}
  export CUDA_VISIBLE_DEVICES=${GPU}
fi

if [[ -n "${MEM_AFFINITY}" ]]; then
  read_rank
  read_mem_affinity_map $MEM_AFFINITY
  MEM=${MEM_AFFINITY_MAP[$LOCAL_RANK]}
  MEMBIND="--membind=${MEM}"
fi

if [[ -n "${CPU_AFFINITY}" ]]; then
  read_rank
  read_cpu_affinity_map $CPU_AFFINITY
  CPU=${CPU_AFFINITY_MAP[$LOCAL_RANK]}
  CPUBIND="--physcpubind=${CPU}"
fi

if [ -n "${MEMBIND}" ] || [ -n "${CPUBIND}" ]; then
  NUMCMD="numactl "
fi

if [ -z "$DAT" ]; then
  error "DAT file not provided"
fi

# if [ $LOCAL_RANK -eq 0 ]; then
#   sudo nvidia-smi -lgc ${GPU_CLOCK}
# fi

${NUMCMD} ${CPUBIND} ${MEMBIND} ${XHPL} ${DAT}

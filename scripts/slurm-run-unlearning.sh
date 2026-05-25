#!/bin/bash -l
#SBATCH --job-name=slurm-run-purge
#SBATCH --output=logs/slurm-run-purge-%j.log
# Request the number of gpus usint "--gres=gpu:<number>". E.g.:
#SBATCH --gres=gpu:3
# Request more time using "--time=<hours:mins:secs>". E.g.:
#SBATCH --time=02:30:00
# Request time partition "--partition=<Partition>". E.g.:
#SBATCH --partition=sc-gpu# Add host, time, and directory name for later troubleshooting

REPO_DIR="${REPO_DIR:-/home/balalru/purge}"
TRAIN_SCRIPT="${TRAIN_SCRIPT:-${REPO_DIR}/src/purge.py}"
SINGLE_GPU_CONFIG="${SINGLE_GPU_CONFIG:-${REPO_DIR}/src/configs/accelerate_single_gpu.yaml}"
MULTI_GPU_CONFIG="${MULTI_GPU_CONFIG:-${REPO_DIR}/src/configs/accelerate_multi_gpu.yaml}"
IFS=',' read -ra VISIBLE_GPUS <<< "${CUDA_VISIBLE_DEVICES:-0}"
NUM_GPUS="${NUM_GPUS:-${#VISIBLE_GPUS[@]}}"
if ! [[ "${NUM_GPUS}" =~ ^[0-9]+$ ]] || [[ "${NUM_GPUS}" -lt 1 ]]; then
  echo "Invalid NUM_GPUS value: ${NUM_GPUS}" >&2
  exit 2
fi

if [[ "${NUM_GPUS}" -gt 1 ]]; then
  ACCELERATE_CONFIG="${ACCELERATE_CONFIG:-${MULTI_GPU_CONFIG}}"
else
  ACCELERATE_CONFIG="${ACCELERATE_CONFIG:-${SINGLE_GPU_CONFIG}}"
fi

echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-not set}"
echo "Detected ${NUM_GPUS} GPU(s)"
echo "Using accelerate config: ${ACCELERATE_CONFIG}"


hostname; pwd; date
# Run the program/command
source "$HOME/anaconda3/etc/profile.d/conda.sh"
echo "Activate virtual environment (must exist)"
conda activate py312

echo "Run unlearning script"
accelerate launch \
  --config_file "${ACCELERATE_CONFIG}" \
  --num_processes "${NUM_GPUS}" \
  "${TRAIN_SCRIPT}" \
  "$@"
echo "Finished unlearning script"
date
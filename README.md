# SETCUDA

A Simple CUDA setup script that quickly sets `CUDA_VISIBLE_DEVICES` to the GPU(s) with the lowest memory usage on your machine. Suitable for both single and multi-GPU configurations in PyTorch on multi-GPU servers.

## Download

```bash
wget https://raw.githubusercontent.com/lankoestee/setcuda/master/setcuda.sh
chmod +x setcuda.sh
```
## Usage

```bash
# Configure the best single GPU
. ./setcuda.sh  

# Configure the best 4 GPUs
. ./setcuda.sh 4
```
## Equivalence

This script is fully equivalent to manually using the `nvidia-smi` command to identify the GPUs with the lowest memory usage and configuring `export CUDA_VISIBLE_DEVICES=x` accordingly.
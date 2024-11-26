#!/bin/bash

# Function to check if nvidia-smi is available and working
check_nvidia_smi() {
    if ! command -v nvidia-smi &> /dev/null; then
        echo "Error: nvidia-smi didn't work."
        echo "Check if you have Nvidia GPU or if the corresponding driver is installed correctly."
        exit 1
    fi

    # Check if nvidia-smi can query GPU information
    if ! nvidia-smi -L &> /dev/null; then
        echo "Error: nvidia-smi didn't work."
        echo "Check if you have Nvidia GPU or if the corresponding driver is installed correctly."
        exit 1
    fi
}

# Call the function to check nvidia-smi
check_nvidia_smi

# Determine how many GPUs to select based on the script argument
num_gpus=${1:-1}

# Get all GPU information using nvidia-smi
gpu_info=$(nvidia-smi --query-gpu=index,name,memory.free,memory.total --format=csv,noheader,nounits)

# Sort the GPU info by free memory in descending order
sorted_gpu_info=$(echo "$gpu_info" | sort -t',' -k3nr)

# Initialize arrays to hold the selected GPU indices and those with low memory percentage
selected_gpu_indices=()
low_memory_gpus=()

# Select the specified number of GPUs with the most free memory
for ((i=0; i<num_gpus; i++)); do
    # Read the next line of sorted GPU information
    IFS=, read -r index name free_memory total_memory <<< "$(echo "$sorted_gpu_info" | sed -n "$((i+1))p")"
    
    # Calculate memory percentage
    memory_percentage=$(echo "scale=2; 100 * $free_memory / $total_memory" | bc)
    
    # Check if the memory percentage is less than 50%
    if (( $(echo "$memory_percentage < 50" | bc -l) )); then
        low_memory_gpus+=("$index")
    fi
    
    # Add the GPU index to the list of selected indices
    selected_gpu_indices+=("$index")
done

# Convert the list of selected GPU indices into a comma-separated string
gpu_indices_str=$(IFS=,; echo "${selected_gpu_indices[*]}")

# Output the selected GPU information
echo -e  "\n------------------------------------"
for index in "${selected_gpu_indices[@]}"; do
    free_memory_gb=$(nvidia-smi --query-gpu=memory.free --format=csv,noheader --id=$index | awk '{printf "%.1f", $1/1024}')
    all_memory_gb=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader --id=$index | awk '{printf "%.1f", $1/1024}')
    memory_percentage=$(echo "scale=2; 100 * $free_memory_gb / $all_memory_gb" | bc)
    # check if the free memory is less than 10
    if (( $(echo "$free_memory_gb < 10" | bc -l) )); then
        # if less than 10, add a leading space
        free_memory_gb=" $free_memory_gb"
    fi
    if (( $(echo "$memory_percentage < 1" | bc -l) )); then
        # if less than 1, add a leading zero
        memory_percentage="0$memory_percentage"
    fi
    echo "GPU-Index   : $index"
    echo "Name        : $(nvidia-smi --query-gpu=name --format=csv,noheader --id=$index)"
    echo "Free-Memory : ${free_memory_gb}G - ${memory_percentage}%"
    echo "------------------------------------"
done

# Set the environment variable
export CUDA_VISIBLE_DEVICES=$gpu_indices_str

# Inform the user about the selected GPUs
echo -e "\nYour cuda devices have been set to $gpu_indices_str\n"

# If there are any GPUs with a memory percentage below 50%, output a warning
if [ ${#low_memory_gpus[@]} -ne 0 ]; then
    echo "Warning: The following GPUs have less than 50% free memory:"
    for index in "${low_memory_gpus[@]}"; do
        echo "  - GPU-Index: $index"
    done
fi
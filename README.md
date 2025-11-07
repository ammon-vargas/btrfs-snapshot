# btrfs-snapshot: Interactive Btrfs Subvolume Management Tool

This script provides an interactive command-line interface to simplify the process of mounting Btrfs partitions and creating subvolumes. It's particularly useful for setting up Btrfs filesystems, such as for a root filesystem with dedicated subvolumes for snapshots (`@`, `@home`, etc.).

## Features

- **Interactive Partition Selection**: Uses `whiptail` or `dialog` to let you choose from available partitions.
- **Mount Point Specification**: Allows you to define where the selected partition should be mounted.
- **Btrfs Check**: Verifies if the selected partition is indeed a Btrfs filesystem before proceeding with subvolume creation.
- **Subvolume Creation**: Guides you through naming and creating new Btrfs subvolumes.
- **Existing Subvolume Listing**: Shows existing subvolumes on the mounted partition.
- **Error Handling**: Provides clear messages for common issues like mounting failures or non-Btrfs partitions.

## Prerequisites

Before running this script, ensure you have the following utilities installed on your system:

- `sudo`: For elevated privileges required for mounting and Btrfs operations.
- `lsblk`: To list block devices and partitions.
- `awk`, `grep`, `read`: Standard Unix text processing tools.
- `blkid`: To identify filesystem types.
- `btrfs-progs`: The Btrfs userspace utilities, essential for `btrfs subvolume` commands.
- `whiptail` or `dialog`: For the interactive menu interface. `whiptail` is usually pre-installed on Debian/Ubuntu-based systems, while `dialog` might need to be installed separately (`sudo apt install dialog` or `sudo dnf install dialog`).

## Cloning the Repository

To get a copy of this script, you can clone the Git repository:

```bash
git clone https://github.com/your-username/btrfs-snapshot.git # Replace with your actual repository URL
cd btrfs-snapshot
```

## Usage

The script is designed to be run interactively.

1.  **Make the script executable**:

    ```bash
    chmod +x run.sh
    ```

2.  **Run the script**:

    ```bash
    ./run.sh
    ```

3.  **Follow the interactive prompts**:

    *   **Welcome Message**: You'll first see a welcome message.
    *   **Select Partition**: A menu will appear listing all detected partitions, their sizes, and filesystem types. Use the arrow keys to navigate and `Enter` to select the Btrfs partition you wish to work with.
    *   **Enter Mount Point**: You'll be prompted to enter a mount point (e.g., `/mnt/btrfs_root` or `/mnt/new_system`). The script will attempt to create this directory if it doesn't exist and then mount the selected partition there.
    *   **Create Subvolume?**: After successful mounting, you'll be asked if you want to create a Btrfs subvolume.
        *   If you choose "Yes", it will first list any existing subvolumes on the mounted partition.
        *   Then, you'll be prompted to enter a name for the new subvolume (e.g., `@`, `@home`, `@snapshots`).
        *   A success message will confirm the creation.
    *   **Perform another operation?**: You can choose to repeat the process for another partition or subvolume, or exit the script.

### Example Workflow

Let's say you want to set up a new Btrfs root filesystem on `/dev/sda1` and create `@` and `@home` subvolumes:

1.  Run `./run.sh`.
2.  Select `/dev/sda1` from the partition list.
3.  Enter `/mnt/new_root` as the mount point.
4.  Choose "Yes" to create a subvolume.
5.  Enter `@` as the subvolume name.
6.  Choose "Yes" to perform another operation.
7.  (The script will automatically use the already mounted partition and mount point). Choose "Yes" to create another subvolume.
8.  Enter `@home` as the subvolume name.
9.  Choose "No" to perform another operation and exit.

## Configuration

The script is designed to be simple and self-contained, with minimal configuration options.

- **`DIALOG` Variable**: By default, the script tries to use `whiptail`. If you prefer `dialog` (and have it installed), you can set the `DIALOG` environment variable before running the script:

    ```bash
    DIALOG=dialog ./run.sh
    ```

- **Error Handling (`set -euo pipefail`)**:
    - `set -e`: Exits immediately if a command exits with a non-zero status.
    - `set -u`: Treats unset variables as an error and exits.
    - `set -o pipefail`: The return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if all commands exit successfully.

- **Cleanup (`trap`)**: The script includes a `trap` command to ensure that if the script exits prematurely, any partition that was mounted by the script will be unmounted. This prevents leaving partitions mounted unexpectedly.

    ```bash
    trap '[[ -n "${MOUNT:-}" ]] && sudo umount "$MOUNT" 2>/dev/null || true' EXIT
    ```
    This line ensures that if the `MOUNT` variable is set (meaning a partition was mounted), `sudo umount "$MOUNT"` is attempted upon script exit, suppressing any errors.

## Troubleshooting

- **"command not found"**: Ensure all prerequisites listed above are installed and available in your system's PATH.
- **"Permission denied"**: The script uses `sudo` for mounting and Btrfs operations. Make sure your user has `sudo` privileges.
- **"Partition is not Btrfs"**: The script explicitly checks the filesystem type. If you intend to use a non-Btrfs partition, you'll need to format it to Btrfs first (e.g., `sudo mkfs.btrfs /dev/sdXN`). **Be extremely careful when formatting partitions, as this will erase all data.**
- **"Failed to mount"**: Check if the partition is already mounted, if the mount point exists and is accessible, or if there are any issues with the partition itself.

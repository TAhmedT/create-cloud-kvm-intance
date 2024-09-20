#!/bin/bash

set -e

VM_NAME="test"
DISK_SIZE="40G"
BLK_NAME="vda"

function usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --name <VM_NAME>                Specify VM name"
    echo "  --disk <DISK_SIZE>              Specify disk size. Default value 40G"
    echo "  --target <BLK_NAME>             Specify blk name"
    echo "  -h, --help                      Show this help message"
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name) VM_NAME="$2"; shift;;
        --disk) DISK_SIZE="$2"; shift ;;
        --target) BLK_NAME="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option $1"; usage; exit 1 ;;
    esac
    shift
done

ATTACH_DISK_NAME="${VM_NAME}-${BLK_NAME}"

lvcreate -n cloud00/${VM_NAME}-${BLK_NAME} -L $DISK_SIZE -y

VOLUME_NAME="${ATTACH_DISK_NAME//-/--}"

virsh attach-disk $VM_NAME /dev/mapper/cloud00-${VOLUME_NAME} $BLK_NAME --persistent
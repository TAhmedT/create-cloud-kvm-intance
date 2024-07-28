#!/usr/bin/env bash

VM_NAME="test"
VOLUME_NAME="${VM_NAME//-/--}"
LIBVIRT_IMAGES_PATH=/var/lib/libvirt/images/$VM_NAME

function usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --name <VM_NAME>                Specify VM name. Default value 'test'"
    echo "  -h, --help                      Show this help message"
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name) VM_NAME="$2"; shift;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option $1"; usage; exit 1 ;;
    esac
    shift
done


virsh destroy $VM_NAME || true
virsh undefine $VM_NAME || true
rm -rf $LIBVIRT_IMAGES_PATH
lvremove cloud00/$VM_NAME -y || true
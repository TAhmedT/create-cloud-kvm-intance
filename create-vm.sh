#!/bin/bash

set -ex

die() { echo "ERR: $@" >&2 ; exit 2 ; }
ok() { echo "${@:-OK}" ; }

function usage() {
    cat << EOF
NAME
    create-vm - Deploy cloud VM on KVM
COMMANDS
    ./create-vm vm_name disk_size distr vcpus_count ram
    ./create-vm test 40G (centos or ubuntu) 2 2048M
EOF
    exit 0
}

function prechecks() {
    test -f $ISO_PATH/centos8.qcow2 || die "Check centos8 cloud image exists"
    test -f $ISO_PATH/ubuntu2204.qcow2 || die "Check ubuntu2204 cloud image exists"

    if test $DISTR = "centos"; then
        IMAGE_NAME="centos8.qcow2"
        CLOUD_INIT_CONFIG_PATH="$SCRIPT_DIR/centos-config"
        OS_VARIANT="centos8"
    elif test $DISTR = "ubuntu"; then
        IMAGE_NAME="ubuntu2204.qcow2"
        CLOUD_INIT_CONFIG_PATH="$SCRIPT_DIR/ubuntu-config"
        OS_VARIANT="ubuntu22.04"
    else
        die "Distr not correct"
    fi

}

function cleanup_vm() {
    virsh destroy $VM_NAME || true
    virsh undefine $VM_NAME || true
    rm -rf $LIBVIRT_IMAGES_PATH
}


VM_NAME=${1:-test}
DISK_SIZE=${2:-40G}
DISTR=${3:-ubuntu}
VCPUS=${4:-2}
RAM=${5:-2048M}
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ISO_PATH="${SCRIPT_DIR}/ISO"
LIBVIRT_IMAGES_PATH=/var/lib/libvirt/images/$VM_NAME
CLOUD_INIT_CONFIG_PATH=""
IMAGE_NAME=""
OS_VARIANT=""

echo "Prechecks before setup"
prechecks

echo "Cleanup old VM"
cleanup_vm

echo "Generate cloud-init config"
cat  > $CLOUD_INIT_CONFIG_PATH/meta-data << EOF
#cloud-config
instance-id: $VM_NAME
local-hostname: $VM_NAME
EOF

genisoimage -output $SCRIPT_DIR/config.iso -V cidata -r -J $CLOUD_INIT_CONFIG_PATH/user-data \
$CLOUD_INIT_CONFIG_PATH/meta-data \
$CLOUD_INIT_CONFIG_PATH/network-config

echo "Copy images to libvirt dir"
mkdir $LIBVIRT_IMAGES_PATH
cp $SCRIPT_DIR/config.iso $LIBVIRT_IMAGES_PATH/
cp $ISO_PATH/$IMAGE_NAME $LIBVIRT_IMAGES_PATH/${VM_NAME}.qcow2
rm $SCRIPT_DIR/config.iso

echo "Change root pass"
virt-customize -a $LIBVIRT_IMAGES_PATH/${VM_NAME}.qcow2 --root-password password:root

echo "Resize QCOW disk size"
qemu-img resize $LIBVIRT_IMAGES_PATH/${VM_NAME}.qcow2 $DISK_SIZE


echo "Create VM"
virt-install --ram ${RAM} \
--vcpus ${VCPUS} \
--name ${VM_NAME} \
--disk path=${LIBVIRT_IMAGES_PATH}/${VM_NAME}.qcow2,format=qcow2 \
--disk path=${LIBVIRT_IMAGES_PATH}/config.iso,device=cdrom \
--os-variant ${OS_VARIANT} \
--network network=default,model=virtio \
--graphics none \
--noautoconsole \
--import
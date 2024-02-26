#!/bin/bash

set -e

die() { echo "ERR: $@" >&2 ; exit 2 ; }

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
    lvremove cloud00/$VM_NAME || true
}

function create_disk() {

    lvcreate -n cloud00/$VM_NAME -L $DISK_SIZE
    qemu-img convert $ISO_PATH/$IMAGE_NAME -O raw /dev/mapper/cloud00-${VOLUME_NAME}
}


VM_NAME=${1:-test}
DISK_SIZE=${2:-40G}
DISTR=${3:-ubuntu}
VCPUS=${4:-2}
RAM=${5:-2048M}
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ISO_PATH="${SCRIPT_DIR}/ISO"
LIBVIRT_IMAGES_PATH=/var/lib/libvirt/images/$VM_NAME
VOLUME_NAME="${VM_NAME//-/--}"
CLOUD_INIT_CONFIG_PATH=""
IMAGE_NAME=""
OS_VARIANT=""

echo "Prechecks before setup"
prechecks

echo "Cleanup old VM"
cleanup_vm

echo "Create disk"
create_disk

echo "Generate cloud-init config"
cat  > $CLOUD_INIT_CONFIG_PATH/meta-data << EOF
#cloud-config
instance-id: $VM_NAME
local-hostname: $VM_NAME
EOF

genisoimage -output $SCRIPT_DIR/config.iso -V cidata -r -J $CLOUD_INIT_CONFIG_PATH/user-data \
$CLOUD_INIT_CONFIG_PATH/meta-data \
$CLOUD_INIT_CONFIG_PATH/network-config

echo "Copy cloud-init config to libvirt dir"
mkdir $LIBVIRT_IMAGES_PATH
cp $SCRIPT_DIR/config.iso $LIBVIRT_IMAGES_PATH/
rm $SCRIPT_DIR/config.iso


echo "Create VM"
virt-install --ram ${RAM} \
--vcpus ${VCPUS} \
--name ${VM_NAME} \
--disk path=/dev/mapper/cloud00-${VOLUME_NAME} \
--disk path=${LIBVIRT_IMAGES_PATH}/config.iso,device=cdrom \
--os-variant ${OS_VARIANT} \
--network network=virbr0,model=virtio \
--graphics none \
--noautoconsole \
--import

virsh autostart $VM_NAME
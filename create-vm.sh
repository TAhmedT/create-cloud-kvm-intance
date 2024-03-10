#!/bin/bash

set -e

VM_NAME="test"
VCPUS_COUNT="2"
MEMORY_AMOUNT="2048"
DISK_SIZE="40G"
LINUX_DISTRIBUITION=""
IP_ADDRESS=""
SUBNET=""
DEFAULT_GATEWAY=""
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ISO_PATH="${SCRIPT_DIR}/ISO"
LIBVIRT_IMAGES_PATH=""
VOLUME_NAME=""
CLOUD_INIT_CONFIG_PATH=""
IMAGE_NAME=""
OS_VARIANT=""


function usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --name <VM_NAME>                Specify VM name. Default value 'test'"
    echo "  --vcpus <VCPUS_COUNT>           Specify CPU counts. Default value 2"
    echo "  --memory <MEMORY_AMOUNT>        Specify memory amount in MB. Default value 2048"
    echo "  --disk <DISK_SIZE>              Specify disk size. Default value 40G"
    echo "  --distr <LINUX_DISTRIBUITION>   Specify distribution(centos/ubuntu)"
    echo "  --ip <IP_ADDRESS>               Specify static ip"
    echo "  --subnet <SUBNET>               Specify subnet. Example --subnet 24 or 32"
    echo "  --gateway <DEFAULT_GATEWAY>     Specify default gateway"
    echo "  -h, --help                      Show this help message"
}

function prechecks_and_fill_vars() {
    LIBVIRT_IMAGES_PATH=/var/lib/libvirt/images/$VM_NAME
    VOLUME_NAME="${VM_NAME//-/--}"

    if test $LINUX_DISTRIBUITION = "centos"; then
        IMAGE_NAME="centos8.qcow2"
        CLOUD_INIT_CONFIG_PATH="$SCRIPT_DIR/centos-config"
        OS_VARIANT="centos8"
    elif test $LINUX_DISTRIBUITION = "ubuntu"; then
        IMAGE_NAME="ubuntu2204.qcow2"
        CLOUD_INIT_CONFIG_PATH="$SCRIPT_DIR/ubuntu-config"
        OS_VARIANT="ubuntu22.04"
    else
        echo "distribution not correct"
        exit 2
    fi

    if [ -z $IP_ADDRESS ]; then
        echo "Specify the ip address"
        exit 2
    fi

    if [ -z $SUBNET ]; then
        echo "Specify the subnet address"
        exit 2
    fi
}

function cleanup_old_vm() {

    virsh destroy $VM_NAME || true
    virsh undefine $VM_NAME || true
    rm -rf $LIBVIRT_IMAGES_PATH
    lvremove cloud00/$VM_NAME -y || true
}

function create_vm_disk() {

    lvcreate -n cloud00/$VM_NAME -L $DISK_SIZE -y
    qemu-img convert $ISO_PATH/$IMAGE_NAME -O raw /dev/mapper/cloud00-${VOLUME_NAME}
}

function generate_cloud_init_config() {


    #GENERATE meta-data
    cat > $CLOUD_INIT_CONFIG_PATH/meta-data << EOF
    #cloud-config
    instance-id: $VM_NAME
    local-hostname: $VM_NAME
EOF


    #GENERATE network-config
    if test $LINUX_DISTRIBUITION = "centos"; then
        cat > ${CLOUD_INIT_CONFIG_PATH}/network-config << EOF
#cloud-config
network:
  version: 1
  config:
    - type: physical
      name: eth0
      subnets:
        - type: static
          address: ${IP_ADDRESS}/${SUBNET}
          gateway: ${DEFAULT_GATEWAY}
          dns_nameservers:
            - 8.8.8.8
            - 8.8.4.4
EOF

    else
        cat > ${CLOUD_INIT_CONFIG_PATH}/network-config << EOF
#cloud-config
network:
  version: 2
  ethernets:
    enp1s0:
      addresses:
        - ${IP_ADDRESS}/${SUBNET}
      gateway4: ${DEFAULT_GATEWAY}
      nameservers:
        addresses:
            - 8.8.8.8
            - 8.8.4.4
EOF
    fi    


    genisoimage -output $SCRIPT_DIR/config.iso -V cidata -r -J $CLOUD_INIT_CONFIG_PATH/user-data \
    $CLOUD_INIT_CONFIG_PATH/meta-data \
    $CLOUD_INIT_CONFIG_PATH/network-config

    echo "Copy cloud-init config to libvirt dir"
    mkdir $LIBVIRT_IMAGES_PATH
    cp ${SCRIPT_DIR}/config.iso ${LIBVIRT_IMAGES_PATH}/
    rm ${SCRIPT_DIR}/config.iso
}


while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name) VM_NAME="$2"; shift;;
        --vcpus) VCPUS_COUNT="$2"; shift ;;
        --memory) MEMORY_AMOUNT="$2"; shift ;;
        --disk) DISK_SIZE="$2"; shift ;;
        --distr) LINUX_DISTRIBUITION="$2"; shift ;;
        --ip) IP_ADDRESS="$2"; shift ;;
        --subnet) SUBNET="$2"; shift ;;
        --gateway) DEFAULT_GATEWAY="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option $1"; usage; exit 1 ;;
    esac
    shift
done

echo "Prechecks and filling in variables"
prechecks_and_fill_vars

echo "Cleanup old VM"
cleanup_old_vm


echo "Create VM disk"
create_vm_disk

echo "Generate cloud-init config"
generate_cloud_init_config


echo "Create VM"
virt-install --ram ${MEMORY_AMOUNT} \
--vcpus ${VCPUS_COUNT} \
--name ${VM_NAME} \
--disk path=/dev/mapper/cloud00-${VOLUME_NAME} \
--disk path=${LIBVIRT_IMAGES_PATH}/config.iso,device=cdrom \
--os-variant ${OS_VARIANT} \
--network network=default,model=virtio \
--graphics none \
--noautoconsole \
--import

virsh autostart $VM_NAME
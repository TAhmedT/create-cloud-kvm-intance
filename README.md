# create-cloud-kvm-intance

## Packages(Ubuntu/Debian)
```shell
sudo apt install qemu-kvm libvirt-daemon-system virtinst libvirt-clients bridge-utils genisoimage
```

## LVM Volume
```shell
echo "- - -" | tee /sys/class/scsi_host/host*/scan #SCAN NEW SCSI BUS
pvcreate /dev/sdb #CLOUD00 PV
vgcreate cloud00 /dev/sdb 
```

## Command
```shell
sudo ./create-vm.sh --name VM_NAME --vcpus CPU_COUNT --memory MEMORY_AMOUNT --disk DISK_SIZE --distr ubuntu/centos --ip IP_ADDR --subnet SUBNET_CIDR --gateway DEFAULT_GATEWAY
sudo ./create-vm.sh --name test --vcpus 2 --memory 2048 --disk 40G --distr ubuntu --ip 192.168.122.10 --subnet 24 --gateway 192.168.122.1
```

## Cloud images
```
1. https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-latest.x86_64.qcow2 -> centos8.qcow2
2. https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -> ubuntu2204.qcow2
```

### Download image to script_dir/ISO

## Help scripts
```shell
attach-disk.sh - attach disk
cleanup-vm.sh  - Destroy VM, remove all files and lvm volume 
setup.sh       - Download images
```
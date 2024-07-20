# create-cloud-kvm-intance

## Command
```shell
sudo ./create-vm.sh --name VM_NAME --vcpus CPU_COUNT --memory MEMORY_AMOUNT --disk DISK_SIZE --distr ubuntu/centos --ip IP_ADDR --subnet SUBNET_CIDR --gateway DEFAULT_GATEWAY
```

## Cloud images
```
1. https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20230308.3.x86_64.qcow2 -> centos8.qcow2
2. https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -> ubuntu2204.qcow2
```

### Download image to script_dir/ISO

#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

mkdir $SCRIPT_DIR/ISO
wget https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20230308.3.x86_64.qcow2 -O $SCRIPT_DIR/ISO/centos8.qcow2
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -O $SCRIPT_DIR/ISO/ubuntu2204.qcow2
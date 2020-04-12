#!/bin/bash

# Update hosts file
#echo "[TASK 1] Update /etc/hosts file"
#cat >>/etc/hosts<<EOF
#172.42.42.100 kmaster.example.com kmaster
#172.42.42.101 kworker1.example.com kworker1
#172.42.42.102 kworker2.example.com kworker2
#EOF

# Install docker from Docker-ce repository
echo "[TASK 2] Install docker container engine"
sudo yum update -y  
sudo yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1  
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1  
sudo yum install -y -q docker-ce docker-ce-cli containerd.io > /dev/null 2>&1  
sudo systemctl enable docker  
sudo systemctl start docker  

# Enable docker service
echo "[TASK 3] Enable and start docker service"
systemctl enable docker >/dev/null 2>&1
systemctl start docker

# Disable SELinux
echo "[TASK 4] Disable SELinux"
sudo setenforce 0
sudo sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

# Stop and disable firewalld
echo "[TASK 5] Stop and Disable firewalld"
sudo systemctl disable firewalld >/dev/null 2>&1
sudo systemctl stop firewalld

# Add sysctl settings
echo "[TASK 6] Add sysctl settings"
sudo bash -c 'cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF'
sudo sysctl --system

# Disable swap
echo "[TASK 7] Disable and turn off SWAP"
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

# Add yum repo file for Kubernetes
echo "[TASK 8] Add yum repo file for kubernetes"
sudo bash -c 'cat >>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF'


# Install Kubernetes
echo "[TASK 9] Install Kubernetes (kubeadm, kubelet and kubectl)"
sudo yum install -y -q kubeadm kubelet kubectl >/dev/null 2>&1

# Start and Enable kubelet service
echo "[TASK 10] Enable and start kubelet service"
sudo systemctl enable kubelet >/dev/null 2>&1
sudo systemctl start kubelet >/dev/null 2>&1

# Enable ssh password authentication
echo "[TASK 11] Enable ssh password authentication"
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl reload sshd

# Set Root password
echo "[TASK 12] Set root password"
sudo echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# Update vagrant user's bashrc file
sudo echo "export TERM=xterm" >> /etc/bashrc

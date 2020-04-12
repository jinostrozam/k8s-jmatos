# Install Kubernetes Cluster using kubeadm
Follow this documentation to set up a Kubernetes cluster on __CentOS 7__ Virtual machines.

This documentation guides you in setting up a cluster with one master node and one worker node.

## Assumptions
|Role|FQDN|IP|OS|RAM|CPU|
|----|----|----|----|----|----|
|Master|kmaster.example.com|172.42.42.100|CentOS 7|2G|2|
|Worker|kworker.example.com|172.42.42.101|CentOS 7|1G|1|

## Checking Hosts
cat /etc/redhat-release  
free -m  
nproc  


## On both Kmaster and Kworker
Perform all the commands as root user unless otherwise specified
### Pre-requisites
##### Update /etc/hosts
So that we can talk to each of the nodes in the cluster
```
cat >>/etc/hosts<<EOF
172.42.42.100 kmaster.example.com kmaster
172.42.42.101 kworker.example.com kworker
EOF
```
##### Install, enable and start docker service
Use the Docker repository to install docker.
> If you use docker from CentOS OS repository, the docker version might be old to work with Kubernetes v1.13.0 and above
```
yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
yum install -y -q docker-ce >/dev/null 2>&1

systemctl enable docker
systemctl start docker

--
sudo yum update -y  
sudo yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1  
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1  
sudo yum install -y -q docker-ce docker-ce-cli containerd.io > /dev/null 2>&1  
sudo systemctl enable docker  
sudo systemctl start docker  
sudo docker run hello-world  
sudo usermod -aG docker vagrant

```
##### Disable SELinux
```
sudo setenforce 0
sudo sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
```
##### Disable Firewall
```
sudo systemctl disable firewalld
sudo systemctl stop firewalld
```
##### Disable swap
```
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a
```
##### Update sysctl settings for Kubernetes networking
```
sudo bash -c 'cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF'
sudo sysctl --system
```
### Kubernetes Setup
##### Add yum repository
```
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
```
##### Install Kubernetes
```
sudo yum install -y kubeadm kubelet kubectl
```
##### Enable and Start kubelet service
```
sudo systemctl enable kubelet
sudo systemctl start kubelet
```
## On kmaster
##### Initialize Kubernetes Cluster
```
sudo kubeadm init --apiserver-advertise-address=172.42.42.100 --pod-network-cidr=192.168.0.0/16  

copy line 'kubeadm join ...' or run the following command to output the command again:  


```
##### Copy kube config
To be able to use kubectl command to connect and interact with the cluster, the user needs kube config file.

In my case, the user account is venkatn
```
sudo mkdir /home/vagrant/.kube
sudo cp /etc/kubernetes/admin.conf /home/venkatn/.kube/config
sudo chown -R venkatn:venkatn /home/venkatn/.kube
```
##### Deploy Calico network
This has to be done as the user in the above step (in my case it is __venkatn__)
```
kubectl create -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml
```

##### Cluster join command
```
kubeadm token create --print-join-command
```
## On Kworker
##### Join the cluster
Use the output from __kubeadm token create__ command in previous step from the master server and run here with sudo.

## Verifying the cluster
##### Get Nodes status
```
kubectl get nodes  
kubectl get nodes -o wide
```
##### Get component status
```
kubectl get cs
kubectl cluster-info  
kubectl version --short  
```

Have Fun!!

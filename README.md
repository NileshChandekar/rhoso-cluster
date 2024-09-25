### Hybrid Infra Management Tool - kcli 
#### Example: Red Hat OpenStack On Red Hat OpenShift  on KVM Infra Provider via kcli 
- **NOTE: kcli plan can be used for other cloud infra provider**
#### Baremetal Node Information | Hypervisor Host (TESTED):
* Dell R440 | 40 Core Cpu | 256 GB Ram
* HOST OS: RHEL 9.4 
* Reference: 
  * <https://github.com/karmab/kcli>
  * <https://kcli.readthedocs.io/en/latest/>
* **NOTE: Tested using root permisions only.**
#### Register RHEL Node:
```
subscription-manager register --username _RHN_USERNAME_
```
#### Update the RHEL node with latest updates, basic utility packages & ssh key gneration: 
```
dnf update -y
dnf install tmux mc podman-docker bash-completion vim jq tar git yum-utils  -y
ssh-keygen
```
#### Check if reboot requires or not
```
needs-restarting -r
```
- **NOTE: # More information: https://access.redhat.com/solutions/27943**
#### Install libvirt (KVM Virtualization):
```
yum -y install libvirt libvirt-daemon-driver-qemu qemu-kvm
usermod -aG qemu,libvirt $(id -un)
newgrp libvirt
systemctl enable --now libvirtd
systemctl status libvirtd
```
#### Install Local NTP Server:
```
dnf install chrony -y
```
#### Configure NTP Server (chrony):
```
cat <EOF> /etc/chrony.conf
server 0.rhel.pool.ntp.org iburst
server 1.rhel.pool.ntp.org iburst
server 2.rhel.pool.ntp.org iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
bindcmdaddress ::
allow all
EOF
```
#### Enable Local NTP Service:
```
systemctl enable chronyd --now
```
#### Install [kcli](https://kcli.readthedocs.io/en/latest/) - Hybrid Infra Management Toolchain:
```
ssh-keygen  # Ignore if already created root SSH key pair
dnf -y copr enable karmab/kcli
dnf -y install kcli
```
#### Configure default pool for kcli:
```
kcli create pool -p /var/lib/libvirt/images default 
```
#### Create Bastion Host for Red Hat OpenStack & Red Hat OpenShift
```
kcli create plan -f infra-rhoso-rhocp-cluster.redhat.lab.kcli rhoso-rhocp-cluster -A
```

#### Create Local Registry on Bastion Host
```
kcli ssh bastion-rhoso-rhocp-cluster.redhat.lab
sudo -i
./MakeMyLocalRegistry.Bash
curl -k -u 'registry-admin:redhat' https://bastion-rhoso-rhocp-cluster.redhat.lab:5000/v2/_catalog
podman login -u registry-admin bastion-rhoso-rhocp-cluster.redhat.lab:5000
```

#### Create Red Hat OpenShift Cluster (rhocp) at Red Hat Lab (redhat.lab) From Hypervisor Host :
```
 kcli create cluster openshift --pf rhoso-rhocp-cluster.redhat.lab.kcli -P tag="4.14" -P plan="rhoso-rhocp-cluster" -P cluster="rhoso-rhocp-cluster" -P pool="rhoso-rhocp-cluster"
```
- **NOTE: tag="4.14"  will decide your Red Hat OpenShift Version**

#### Download Red Hat OpenShift Container Platform (RHOCP) Pull Secret:
```
Donwload RHOCP Pull Secret from: https://console.redhat.com/openshift/install/pull-secret
```

#### Install oc/kubectl/opm CLIs on Hypervisor Host:
```
kcli download oc -P version=stable -P tag='4.14'
kcli download kubectl -P tag='4.14'
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/opm-linux.tar.gz
tar -zxvf opm-linux.tar.gz
cp kubectl oc opm /usr/bin/
```

### Sample Expected Output From Hypervisor Host For Red Hat Openshift Version 4.16 
```
[root@dell-r440-09 rhoso-ocp414-kcli]# kcli  list vms && kcli list dns redhat.lab && cat /etc/hosts
+---------------------------------+--------+--------------+----------------------------------------------------+----------------------+-----------------+
|               Name              | Status |      Ip      |                       Source                       |         Plan         |     Profile     |
+---------------------------------+--------+--------------+----------------------------------------------------+----------------------+-----------------+
|   bastion-rhoso-ocp416-cluster  |   up   | 10.10.10.10  |                       rhel94                       | rhoso-ocp416-cluster | rhel94-c4m8d100 |
| rhoso-ocp416-cluster-ctlplane-0 |   up   | 10.10.10.209 | rhcos-416.94.202405291527-0-openstack.x86_64.qcow2 | rhoso-ocp416-cluster |      kvirt      |
| rhoso-ocp416-cluster-ctlplane-1 |   up   | 10.10.10.109 | rhcos-416.94.202405291527-0-openstack.x86_64.qcow2 | rhoso-ocp416-cluster |      kvirt      |
| rhoso-ocp416-cluster-ctlplane-2 |   up   | 10.10.10.200 | rhcos-416.94.202405291527-0-openstack.x86_64.qcow2 | rhoso-ocp416-cluster |      kvirt      |
|  rhoso-ocp416-cluster-worker-0  |   up   | 10.10.10.50  | rhcos-416.94.202405291527-0-openstack.x86_64.qcow2 | rhoso-ocp416-cluster |      kvirt      |
|  rhoso-ocp416-cluster-worker-1  |   up   | 10.10.10.35  | rhcos-416.94.202405291527-0-openstack.x86_64.qcow2 | rhoso-ocp416-cluster |      kvirt      |
|  rhoso-ocp416-cluster-worker-2  |   up   | 10.10.10.110 | rhcos-416.94.202405291527-0-openstack.x86_64.qcow2 | rhoso-ocp416-cluster |      kvirt      |
+---------------------------------+--------+--------------+----------------------------------------------------+----------------------+-----------------+
+--------------------------------------------+------+-----+-----------------------------+
|                   Entry                    | Type | TTL |             Data            |
+--------------------------------------------+------+-----+-----------------------------+
|  bastion-rhoso-ocp416-cluster.redhat.lab   |  A   |  0  |  10.10.10.10 (RedHatLabNet) |
|    dns-rhoso-ocp416-cluster.redhat.lab     |  A   |  0  |  10.10.10.1 (RedHatLabNet)  |
| rhoso-ocp416-cluster-ctlplane-0.redhat.lab |  A   |  0  | 10.10.10.209 (RedHatLabNet) |
| rhoso-ocp416-cluster-ctlplane-1.redhat.lab |  A   |  0  | 10.10.10.109 (RedHatLabNet) |
| rhoso-ocp416-cluster-ctlplane-2.redhat.lab |  A   |  0  | 10.10.10.200 (RedHatLabNet) |
|  rhoso-ocp416-cluster-worker-0.redhat.lab  |  A   |  0  |  10.10.10.50 (RedHatLabNet) |
|  rhoso-ocp416-cluster-worker-1.redhat.lab  |  A   |  0  |  10.10.10.35 (RedHatLabNet) |
|  rhoso-ocp416-cluster-worker-2.redhat.lab  |  A   |  0  | 10.10.10.110 (RedHatLabNet) |
+--------------------------------------------+------+-----+-----------------------------+
```

#### Follow Official Beta Document Deploying Red Hat OpenStack Services on OpenShift: 
```
https://docs.redhat.com/en/documentation/red_hat_openstack_services_on_openshift/18.0-beta/html-single/deploying_red_hat_openstack_services_on_openshift/index
```


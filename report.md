# INFRASTRUCTURE PROJECT
... Rayane, CHOUKROUNE Nathan, CHAPUIS Julien
## Introduction

 The goal of this project is to build a service for the automatic deployment of a Big Data application
 in a virtualized environment. This service will rely on KVM with libvirt for providing virtual
 machines, Terraform for provisioning virtual machines, Ansible for deploying the Spark
 infrastructure and application. Then we have to automate the whole process with a script.

In this report we will describe what we did to :
 - Install the tools
 - Use Ansible to deploy Spark
 - Automate the process

## I/ Installation

### KVM / Libvirt
Here are the steps to install LibVirt & check if KVM is useable :

```bash
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients virt-manager bridge-utils
```

Since libvirt-bin isn’t downloadable in newer version of linux, we just have to get the deamon, client, manager & the bridge utils.

Then you have to start the service :

```bash
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo systemctl status libvirtd
```

The last command should tell you that the service is “active (running)”.

now for KVM :

```bash
sudo kvm-ok
```

It should display :

```bash
INFO: /dev/kvm exists
KVM acceleration can be used
```

if not, go into BIOS and enable KVM if you hardware allows it.

### Local network with libvirt

```sudo nano /etc/libvirt/qemu/networks/default.xml```
```xml
<network>
  <name>default</name>
  <uuid>e1e8ab56-7863-4e79-9e0d-596abe4b8f3d</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:cf:15:e4'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

you should have something like this. only uuid can be different.

```bash
sudo virsh net-define /etc/libvirt/qemu/networks/default.xml
sudo virsh net-start default
sudo virsh net-autostart default
```

the point of those command is to define the default file for the network, start it, and make it so that everytime you start libvirt, the default network starts with it.

```bash
sudo virsh net-list --all

 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes
```

you should then see something like this.

```bash
sudo systemctl restart libvirtd
```

if needed you can restart libvirt

### Terraform Install & script to launch it

Install Terraform : 

```bash
sudo apt update
sudo apt install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
sudo apt-get install terraform
sudo apt-get install genisoimage 
terraform -version
mkdir ~/terraform-libvirt
cd ~/terraform-libvirt
```
Some permissions have to be setup so that the terraform can launch.
You also have to disable your anti-virus, else you’ll get permission denied even as sudo

```bash
sudo chown root:libvirt /var/run/libvirt/libvirt-sock
sudo chmod 660 /var/run/libvirt/libvirt-sock
sudo systemctl restart libvirtd

sudo chown $USER:$USER terraform.tfstate
sudo chmod 644 terraform.tfstate
sudo chown -R $USER:$USER ~/big-data

rm -f .terraform.tfstate.lock.info

sudo chown -R $USER:$USER ~/big-data

sudo aa-status
sudo systemctl stop apparmor

```

```bash
sudo systemctl status apparmor
sudo nano /etc/libvirt/qemu.conf
```

add at the end of qemu.conf:

```conf
user = "root"
group = "root"
security_driver = "none"
```
Then you should restart your computer.

create cloud-init.yml :

```yml
#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    lock_passwd: false
    passwd: $6$rounds=4096$ZgC9tLzMQz5zT$AkrLXGAYk.FKgQGAaluaoRsQhU6.AUt9X.VrF3N5rfNSi2F1kwyX/WqRLVeWtFPf4xbtPVGY0O8e5jvZpVj/j.
ssh_pwauth: true
chpasswd:
  list: |
    ubuntu:ubuntu
  expire: False
runcmd:
  - systemctl restart ssh
```

create [main.tf](http://main.tf) :

```bash

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"  
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

#storage pool disks
resource "libvirt_pool" "default1" {
  name = "default1"
  type = "dir"
  path = "$HOME/terraform-libvirt/pool_dir"
}

# unique disk image for the vms
resource "libvirt_volume" "ubuntu_image" {
  count  = 3   
  name   = "ubuntu_image_${count.index}.qcow2"
  pool   = libvirt_pool.default1.name
  source = "https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

# cloud init disk for the vms
resource "libvirt_cloudinit_disk" "commoninit" {
  count     = 3
  name      = "cloudinit-disk-${count.index}.iso"
  pool      = libvirt_pool.default1.name
  user_data = file("$HOME/terraform-libvirt/cloud-init.yml")
}

# vms
resource "libvirt_domain" "vm" {
  count = 3   
  name  = "spark-vm-${count.index}"

  memory = 2048  # 2 GB RAM per VM
  vcpu   = 2     # 2 vCPUs per VM

  network_interface {
    network_name = "default"
  }

  # attach VM to its disk
  disk {
    volume_id = libvirt_volume.ubuntu_image[count.index].id
  }

  # attach cloud-init disk to its VM
  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

```

This is the terraform script. In here we setup the VM that we will create with their settings. cloud_init goal is to make the source of the cloud image reachable & without issues.

then use :

```bash
terraform init
terraform apply
```

to connect to the vm : 

```bash
virsh console spark-vm-x
ubuntu login: ubuntu
Password: ubuntu
```

to check the network : (since the range on the network is wide, the ip is random so it can differ from computers)

```bash
sudo virsh net-dhcp-leases default
 2024-10-17 17:56:48   52:54:00:16:54:74   ipv4       192.168.122.52/24    ubuntu     ff:b5:5e:67:ff:00:02:00:00:ab:11:55:5c:aa:ed:4e:fd:f5:03
 2024-10-17 17:56:48   52:54:00:96:bd:a3   ipv4       192.168.122.7/24     ubuntu     ff:b5:5e:67:ff:00:02:00:00:ab:11:17:6d:ba:86:b1:b7:8d:e5
 2024-10-17 17:56:48   52:54:00:9a:80:b3   ipv4       192.168.122.104/24   ubuntu     ff:b5:5e:67:ff:00:02:00:00:ab:11:38:fa:2c:5d:b9:d6:8b:c7

```

if you alredy have vm running, you can destroy them & undefine them. Same goes for the pool: 

```bash
virsh destroy spark-vm-0
virsh undefine spark-vm-0

virsh destroy spark-vm-1
virsh undefine spark-vm-1

virsh destroy spark-vm-2
virsh undefine spark-vm-2

#virsh pool-destroy default1
#virsh pool-undefine default1

```

```bash
virsh net-dhcp-leases default
virsh net-dhcp-leases default | grep 52:54:00: | awk '{print $5}' | cut -d'/' -f1
virsh net-dhcp-leases default | grep 192.168.122 | awk '/ubuntu/ {print $5}' | cut -d'/' -f1

```
Those commands are meant to retrieve the IP adresses for the automation script

## II/ Ansible

Resources

https://www.youtube.com/watch?v=4REljLsOnXk

https://www.digitalocean.com/community/cheatsheets/how-to-use-ansible-cheat-sheet-guide

https://blog.clairvoyantsoft.com/spark-standalone-deployment-using-ansible-9917d58c7768

https://stackoverflow.com/questions/43235179/how-to-execute-ssh-keygen-without-prompt

[Ansible Installation](https://www.notion.so/Ansible-Installation-12547df25bcf8091bba4cfcd7b3ac580?pvs=21)

[Spark installation](https://www.notion.so/Spark-installation-12547df25bcf8036af58fbd78bd69ca0?pvs=21)

Ansible is an automation software capable of running a list of command and plugins on all the nodes of the cluster. It saves configuration time and complexity. To use it we will install it on the master node and give it the inventory and the playbook to run the automation. 

The playbook is a list of tasks given to Ansible, configuring the environment variables and running the plugins. The inventory is a list of IP addresses to which Ansible will connect to and run the playbook. 

We start by installing all the necessary components:  

```bash
sudo apt install -y openssh-server, nettools, python3, python3-virtualenv
```

Multiple Ansible installations were tried but the python one was the most successful: 

Ansible needs ssh access from the control node to the slaves to run any tasks. So once the vm are running, the script takes the ip and uses it to copy ssh keys. 

It will then use this connection to connect and control the nodes. To The host file (inventory) server name or ip address of the slaves

Multiple ways of retrieving the vm ip addresses were tried but the bash variable was the most useful: 

create [ip.sh](http://ip.sh) 

[fichier ansible](https://www.notion.so/fichier-ansible-3fbfc830d2ae4bbc982ad9e1004904c5?pvs=21)

INVENTORY

The script will generate the ansible inventory by pasting the ip addresses of the nodes to the file. We can check the inventory configuration with ```ansible-inventory -i inventory.ini --list```

```bash
nano ~/ansible/inventory.ini

#add ip adresses of the nodes
[nodes]
192.168
192.168

```

ANSIBLE

```bash
ansible-inventory --list -y
ansible-galaxy collection list
ansible-galaxy collection install <module>
ansible all --key-file ~/.ssh/ansible -i inventory.ini -m ping -u root
```

ANSIBLE COMMANDS

```bash
ansible all -a "df -h" -u root

ansible-playbook playbook.yml --extra-vars="jar_name=$jar_name , file_name=$file_name , slave_count=$slave_count "
```

PLAYBOOK TASKS

- config
- copy ssh
- copy install files
- install java hadoop spark

```jsx
- name: deactivate the firewall
	ignore_errors: yes
	command: "sudo systemctl stop firewalld"
```

```jsx
- name: Copy installation tar
  copy:
    src: other/jdk-8u202-linux-x64.tar.gz
    dest: /tmp/jdk-8u202-linux-x64.tar.gz

- name: Extract Java
  unarchive:
    src: /tmp/jdk-8u202-linux-x64.tar.gz
    dest: /opt/
    remote_src: yes
    
- name: Extract Hadoop
  unarchive:
    src: /tmp/hadoop-2.7.1.tar.gz
    dest: /opt/
    remote_src: yes
    
- name: Extract Spark
  unarchive:
    src: /tmp/spark-2.4.3-bin-hadoop2.7.tgz
    dest: /opt/
    remote_src: yes
    
    
- name: Delete tar file
  ansible.builtin.file:
    state: absent
    path: /tmp/jdk-8u202-linux-x64.tar.gz

- name: Delete tar file
  ansible.builtin.file:
    state: absent
    path: /tmp/hadoop-2.7.1.tar.gz

- name: Delete tar file
  ansible.builtin.file:
    state: absent
    path: /tmp/spark-2.4.3-bin-hadoop2.7.tgz
```

```jsx
- name: Ensure growpart is installed
  package:
    name: cloud-guest-utils  # Required for growpart
    state: present

- name: Check current disk usage
  command: df -h /
  register: disk_usage

- name: Print current disk usage
  debug:
    var: disk_usage.stdout_lines

- name: Resize partition
  command: growpart /dev/vda 1  # Adjust the device if necessary
  when: "'/dev/vda' in disk_usage.stdout"

- name: Resize filesystem
  command: resize2fs /dev/vda1  # Adjust the partition if necessary
  when: "'/dev/vda1' in disk_usage.stdout"

- name: Check resized disk usage
  command: df -h /
  register: new_disk_usage

- name: Print new disk usage
  debug:
    var: new_disk_usage.stdout_lines
```

```bash
~/.bashrc

export SPARK_HOME='/opt/spark-2.4.3-bin-hadoop2.7'
export PYSPARK_PYTHON='/usr/bin/python3'
export JAVA_HOME='/opt/jdk-8u202-linux-x64'
export HADOOP_HOME='/opt/hadoop-2.7.1'

export PATH=$PATH:$SPARK_HOME/bin:$JAVA_HOME/bin:$PYSPARK_PYTHON:$HADOOP_HOME/bin:$HADOOP_HOME/lib/native

- name: Modify bashrc
  command: cat bash_template.txt >> ~/.bashrc
- name: Relaunch bashrc
  command: source ~/.bashrc

```

Spark installation: 

```bash
java -version && hadoop --version && spark --version && spark-shell
```

default path on ubuntu
`export PATH=/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games`

## III/ Automate the process

## Conclusion
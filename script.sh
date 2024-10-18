#!/bin/sh


# VARIABLES

jar_name=$1
file_name=$2
slave_count=$3

jar_name=java/sparck_project/wc.jar
file_name=java/filesample.txt
slave_count=3

# FUNCTIONS

run_main(){
  echo "main script"
}

wait(){
  echo "Press any key to continue..."
  # Loop until a key is pressed
  while true; do
    read -p "waiting..." key  # Read a single character silently
    if [ $key ] 
    then
    echo "One key detected. Program terminated."
    break  # Exit the loop if a key is pressed
    fi
  done
}

# INTRODUCTION

echo "Hello to the server generator"
echo "You are in:"
pwd
echo "Installation will be done in /home/$USER"
echo "This script will run instances of $1 with data in $2 file, on $3 VM servers"

while true; do
  read -p "Do you want to continue? [Y/n]" yn
  case $yn in
    [Yy]* ) run_main; break;;
    [Nn]* ) exit;;
    * ) run_main; break;;
  esac
done

# INSTALLATIONS

installations(){
  sudo apt update -y
  sudo apt -y upgrade

  sudo apt install openssh-server -y
  sudo apt install net-tools -y

  sudo apt install python3 -y
  sudo apt install python3-pip -y
  sudo apt install python3-virtualenv -y
}
#installations

# GENERATING THE VM SERVERS

# SSH CONFIGURATION

# CAPTURE THE IP ADDRESSES
#ip -4 addr | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
#hostname -I


# ANSIBLE CONFIG
ansible_config(){
  virtualenv -p python3.12 venv-ansible
  source venv-ansible/bin/activate
}
#ansible_config

# GENERATE ANSIBLE INVENTORY
#cat >> ~/ansible/inventory << EOF $ips EOF

# ANSIBLE PLAYBOOK
ansible_playbook(){
  sudo ls
  ansible-playbook playbook.yml --extra-vars="jar_name=$jar_name , file_name=$file_name , slave_count=$slave_count "
  
}
#ansible_playbook

ssh_config(){
# if Strict
echo "StrictHostKeyChecking no" | sudo tee -a /etc/ssh/ssh_config 
# https://stackoverflow.com/questions/43235179/how-to-execute-ssh-keygen-without-prompt
}
#ssh_config

# if rsa
#cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

#!/bin/sh


# VARIABLES

jar_name=$1
file_name=$2
slave_count=$3

# FUNCTIONS

run_main(){
  echo "main script"
}

wait(){
  echo "Press any key to terminate the application..."
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

wait

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

# ANSIBLE CONFIG
pwd
read -p "Press enter to continue"
virtualenv -p python3.12 venv-ansible
source venv-ansible/bin/activate
pwd
#pip install ansible
pwd


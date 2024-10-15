#!/bin/sh

# INTRODUCTION

echo "Hello to the server generator"
echo "You are in:"
pwd
echo "This script will run instances of "$1" with data in "$2" file, on "$3" VM servers"


run_main(){
    echo "main script"
}


while true; do
    read -p "Do you want to continue? [Y/n]" yn
    case $yn in
        [Yy]* ) run_main; break;;
        [Nn]* ) exit;;
        * ) run_main; break;;
    esac
done




#!/bin/sh

echo "Hello to the server generator"
ls

# Accessing an Environment Variable
echo $USER

# Creating and accessing User defined Variable
variable_name="Geeksforgeeks"
echo $variable_name

x=10
y=11
if [ $x -ne $y ] 
then
echo "Not equal"
fi

x=2
while [ $x -lt 6 ]
do
echo $x
x=`expr $x + 1`
done

echo "No of arguments is $#"
echo "Name of the script is $0"
echo "First argument is $1"
echo "Second argument is $2"

var=$(hostname -I)
echo $var
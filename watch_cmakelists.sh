#!/bin/sh

pkill -f "entr ${1}/update_compile_commands.sh" # && exit
echo ${1}/CMakeLists.txt | entr ${1}/update_compile_commands.sh $1

# entr -p sh -c 

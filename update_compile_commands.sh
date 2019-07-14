#!/bin/sh

directory=$1
cd ${directory}/build
if [ $? -eq 0 ]; then
    rm -rf *
    cmake ..
    cd ..
    cp ${directory}/build/compile_commands.json ./
    ccls -index=$PWD
else
    echo "error"
fi


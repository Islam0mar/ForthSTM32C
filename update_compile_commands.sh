#!/bin/sh

directory=$1
cd ${directory}/build
if [ $? -eq 0 ]; then
    rm -rf *
    cmake ..
    cd ..
    ln -s ${directory}/build/compile_commands.json
else
    echo "error"
fi


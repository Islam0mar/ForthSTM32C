#!/bin/sh

directory = $(pwd)
cd ${directory}/build
rm -rm *
cmake ..
ln ${directory}/build/compile_commands.json ../

# entr -p sh -c "cd cmake-ide-build-dir;rm -rf *; cmake ..; ln -s ./compile_commands.json ../;"
#     (let ((command `(shell-command ,(concatenate 'string "cd"  cmake-ide-build-dir ";rm -rf *; cmake ..; ln -s ./compile_commands.json ../;"))))
#       (eval (concatenate 'string "echo " command ))



#!/bin/sh
set -eu
cd "$(dirname "$0")"
g++ -std=c++17 -O2 -g -Wall -Wextra -pedantic hi.c++ -o voxel
./voxel 42 48 world

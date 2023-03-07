#!/bin/sh

[ ! -d ffi-packages/build ] && mkdir -p ffi-packages/build

git clone https://github.com/AngusJohnson/Clipper2.git ffi-packages/Clipper2/Clipper2 && cd ffi-packages/Clipper2/Clipper2
git checkout e9bd409439bcb7a07a50f555c88e623986eea10f

cmake ../../ -DCMAKE_CXX_COMPILER=g++ -G "Unix Makefiles" -B ../../build
cd ../../build && make
#!/bin/sh

# Clipper2
if [ "$1" == "-all" ]; then
    [ ! -d ffi-packages/Clipper2/buildCP ] && mkdir -p ffi-packages/Clipper2/buildCP

    git clone https://github.com/AngusJohnson/Clipper2.git ffi-packages/Clipper2/Clipper2 && cd ffi-packages/Clipper2/Clipper2
    git checkout e9bd409439bcb7a07a50f555c88e623986eea10f

    cmake .. -DCMAKE_CXX_COMPILER=g++ -G "Unix Makefiles" -B ../buildCP
    cd ../buildCP && make && cd ../../../
fi

# TurboJPEG
if [ "$1" == "-all" ]; then
    [ ! -d ffi-packages/Images/buildJP ] && mkdir -p ffi-packages/Images/buildJP

    git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git ffi-packages/Images/libjpeg-turbo && cd ffi-packages/Images/libjpeg-turbo
    git checkout 8162eddf041e0be26f5c671bb6528723c55fed9d

    cmake ../libjpeg-turbo -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -G "Unix Makefiles" -B ../buildJP
    cd ../buildJP && make && cd ../../../
fi

# LodePNG and GifLib
[ ! -d ffi-packages/Images/buildLG ] && mkdir -p ffi-packages/Images/buildLG

git clone https://github.com/lvandeve/lodepng.git ffi-packages/Images/lodepng && cd ffi-packages/Images/lodepng
git checkout 997936fd2b45842031e4180d73d7880e381cf33f && cp -f lodepng.cpp lodepng.c && cd ../../../

git clone https://github.com/rcancro/giflib.git ffi-packages/Images/giflib && cd ffi-packages/Images/giflib
git checkout 4b0c893cfddf16421bd3f59207fdf65f06e9a10d

cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -G "Unix Makefiles" -B ../buildLG
cd ../buildLG && make && cd ../../../
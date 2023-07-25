@echo off

@rem CLipper2
if not exist ffi-packages\Clipper2\buildCP ( mkdir ffi-packages\Clipper2\buildCP )

git clone https://github.com/AngusJohnson/Clipper2.git ffi-packages\Clipper2\Clipper2 && cd ffi-packages\Clipper2\Clipper2
git checkout 866e40201476b9af9fec5ce80de16bf0b03eff7a && cd ..\buildCP

cmake .. && cmake --build . --config Release --parallel && cd ..\..\..\

@rem TurboJPEG
if not exist ffi-packages\Images\buildJP ( mkdir ffi-packages\Images\buildJP )

git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git ffi-packages\Images\libjpeg-turbo && cd ffi-packages\Images\libjpeg-turbo
git checkout 8162eddf041e0be26f5c671bb6528723c55fed9d && cd ..\buildJP

cmake ..\libjpeg-turbo && cmake --build . --config Release --parallel && cd ..\..\..\
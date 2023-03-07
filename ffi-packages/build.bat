@echo off

if not exist ffi-packages\build ( mkdir ffi-packages\build )

git clone https://github.com/AngusJohnson/Clipper2.git ffi-packages\Clipper2\Clipper2 && cd ffi-packages\Clipper2\Clipper2
git checkout e9bd409439bcb7a07a50f555c88e623986eea10f && cd ..\..\build

cmake .. && cmake --build . --config Release --parallel
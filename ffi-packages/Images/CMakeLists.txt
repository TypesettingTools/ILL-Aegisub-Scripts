cmake_minimum_required(VERSION 3.10)
option(BUILD_SHARED_LIBS "Build Shared Libs" ON)

# lodepng
project(lodepng LANGUAGES C)
set(LODEPNG_SRC lodepng/lodepng.c)
add_library(lodepng SHARED ${LODEPNG_SRC})
target_compile_options(lodepng PRIVATE -W -Wall -Wextra -ansi -pedantic -O3)

# giflib
project(giflib_wrap LANGUAGES C)
set(GIFLIB_SRC
    giflib/lib/dgif_lib.c
    giflib/lib/egif_lib.c
    giflib/lib/gif_err.c
    giflib/lib/gif_font.c
    giflib/lib/gif_hash.c
    giflib/lib/gifalloc.c
    giflib/lib/quantize.c
)
add_library(giflib SHARED ${GIFLIB_SRC})
target_compile_options(giflib PRIVATE -w -fno-builtin -g -c -W -Wreturn-type -Wcomment -O3)

if (NOT UNIX)
    target_link_libraries(lodepng PUBLIC -static)
    target_link_libraries(giflib PUBLIC -static)
endif (UNIX)

install(TARGETS lodepng giflib
    RUNTIME DESTINATION "${CMAKE_SOURCE_DIR}"
    LIBRARY DESTINATION "${CMAKE_SOURCE_DIR}"
)
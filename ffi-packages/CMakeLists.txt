CMAKE_MINIMUM_REQUIRED(VERSION 3.10)
project(clipper2 VERSION 1.1.0 LANGUAGES CXX)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(CLIPPER2_SRC Clipper2/Clipper2/CPP/Clipper2Lib/src/clipper.engine.cpp Clipper2/Clipper2/CPP/Clipper2Lib/src/clipper.offset.cpp Clipper2/clipper.wrap.cpp)
add_library(clipper2 SHARED ${CLIPPER2_SRC})
target_include_directories(clipper2 PUBLIC Clipper2/Clipper2/CPP/Clipper2Lib/include)

if (MSVC)
    target_compile_options(clipper2 PRIVATE /W4 /WX)
else()
    target_compile_options(clipper2 PRIVATE -Wall -Wextra -Wpedantic -Werror)
    if (NOT UNIX)
        target_link_libraries(clipper2 PUBLIC -static -lm)
    endif (UNIX)
endif (MSVC)

install(TARGETS clipper2 
    RUNTIME DESTINATION "${CMAKE_SOURCE_DIR}"
    LIBRARY DESTINATION "${CMAKE_SOURCE_DIR}"
)
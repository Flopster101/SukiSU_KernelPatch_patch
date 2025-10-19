cmake_minimum_required(VERSION 3.5)
project(kptools)

include_directories(${CMAKE_CURRENT_BINARY_DIR})

set(SOURCES
    image.c
    kallsym.c
    kptools.c
    order.c
    insn.c
    patch.c
    symbol.c
    kpm.c
    common.c
    sha256.c
)

add_executable(kptools ${SOURCES})

find_package(ZLIB REQUIRED)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    # Try to find static zlib first, fall back to dynamic if not found
    find_library(ZLIB_STATIC_LIB libz.a PATHS /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu)
    if(ZLIB_STATIC_LIB)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
        target_link_libraries(kptools PRIVATE ${ZLIB_STATIC_LIB})
        message(STATUS "Using static zlib: ${ZLIB_STATIC_LIB}")
    else()
        # Fall back to dynamic linking
        target_link_libraries(kptools PRIVATE ${ZLIB_LIBRARIES})
        message(STATUS "Using dynamic zlib: ${ZLIB_LIBRARIES}")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Android")
    target_link_libraries(kptools PRIVATE ${ZLIB_LIBRARIES})
else()
    target_link_libraries(kptools PRIVATE ${ZLIB_LIBRARIES})
endif()

target_include_directories(kptools PRIVATE ${ZLIB_INCLUDE_DIRS})
# Requirements to the cmake ----------------------------------------------------
cmake_minimum_required(VERSION 3.12)

# Dependency resolving ---------------------------------------------------------
if(NOT TARGET crc::crc)
    find_package(crc REQUIRED)
endif()

# Target Declaration -----------------------------------------------------------
add_executable(tstcrc)

# Target Definition ------------------------------------------------------------
target_sources(tstcrc
    PRIVATE
        tstcrc.c
)

target_link_libraries(tstcrc
    PRIVATE
        crc::crc
)

# Requirements to the cmake ----------------------------------------------------
cmake_minimum_required(VERSION 3.12)

# Target Declaration -----------------------------------------------------------
add_executable(prc)

# Target Definition ------------------------------------------------------------

target_sources(prc
    PRIVATE
        crc32_table.c
        crc64_table.c
        precalc.c
)

target_include_directories(prc
    PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

target_link_libraries(prc
    PRIVATE
        crc::common
        crc::compile_flags
)



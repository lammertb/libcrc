# Requirements to the cmake ----------------------------------------------------
cmake_minimum_required(VERSION 3.12)

# Target Declaration -----------------------------------------------------------
add_library(crc_common INTERFACE)
add_library(${PACKAGE_NAMESPACE}::common ALIAS crc_common)

set_target_properties(crc_common
    PROPERTIES
        EXPORT_NAME common
)

# Target Definition ------------------------------------------------------------
target_include_directories(crc_common
    INTERFACE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<INSTALL_INTERFACE:${PACKAGE_INSTALL_INCLUDE_DIR}>
)

# Installations ----------------------------------------------------------------
## Targets installation
install(TARGETS crc_common EXPORT commonTargets)

## CMake's configurations
install(EXPORT  commonTargets
    NAMESPACE   ${PACKAGE_NAMESPACE}::
    DESTINATION ${PACKAGE_INSTALL_CMAKE_DIR}
)

## Install files
install(FILES   checksum.h
    DESTINATION ${PACKAGE_INSTALL_INCLUDE_DIR}
    COMPONENT   library
)

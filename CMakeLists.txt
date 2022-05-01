# Requirements to the cmake ----------------------------------------------------
cmake_minimum_required(VERSION 3.12)

# Project Declaration ----------------------------------------------------------

project(crc
    VERSION         2.1.0
    DESCRIPTION     "Multi platform MIT licensed CRC library in C"
    HOMEPAGE_URL    "https://github.com/lammertb/libcrc"
    LANGUAGES       C
)

# CMake extensions -------------------------------------------------------------
add_subdirectory(cmake)

# Includes ---------------------------------------------------------------------
## cmake native modules
include(CheckCCompilerFlag)
include(CMakePackageConfigHelpers)
include(FeatureSummary)
include(GNUInstallDirs)

## local modules
include(CommonOptions)

if(WITH_INCLUDE_WHAT_YOU_USE)
    include(UseIncludeWhatYouUse)
endif()

if(WITH_CLANG_TIDY)
    include(UseClangTidy)
endif()

if(WITH_COVERAGE)
    include(CodeCoverage)
endif()

# Package setting -------------------------------------------------------------
set(PACKAGE_NAME                ${PROJECT_NAME})
set(PACKAGE_NAMESPACE           ${PROJECT_NAME})
set(PACKAGE_INSTALL_CMAKE_DIR   ${CMAKE_INSTALL_LIBDIR}/cmake/${PACKAGE_NAME})
set(PACKAGE_INSTALL_INCLUDE_DIR ${CMAKE_INSTALL_INCLUDEDIR}/${PACKAGE_NAME})
set(PACKAGE_INSTALL_LIBRARY_DIR ${CMAKE_INSTALL_LIBDIR})
if(WIN32)
    set(PACKAGE_INSTALL_CMAKE_DIR   cmake)
    set(PACKAGE_INSTALL_INCLUDE_DIR ${CMAKE_INSTALL_INCLUDEDIR})
endif()


# Target Declaration -----------------------------------------------------------
add_library(${PROJECT_NAME} STATIC)
add_library(${PACKAGE_NAMESPACE}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

# Compilation flags ------------------------------------------------------------

add_library(crc_compile_flags INTERFACE)
add_library(${PACKAGE_NAMESPACE}::compile_flags ALIAS crc_compile_flags)

set(compiler_flags -Wall)
if(WIN32)
    list(APPEND compiler_flags -Ox -Ot -MT -GT -J -sdl -WX
                               -volatile:iso -nologo
                               -wd4464 -wd4668 -wd4710 -wd4711 -wd4201 -wd4820
    )
else()
    list(APPEND compiler_flags -Wextra -Wstrict-prototypes -Wshadow
                               -Wpointer-arith -Wcast-qual -Wcast-align
                               -Wwrite-strings -Wredundant-decls -Wnested-externs
                               -funsigned-char
    )
endif()

foreach(compiler_flag IN LISTS compiler_flags)
    check_c_compiler_flag(${compiler_flag} supports${compiler_flag})
    if(supports${compiler_flag})
        target_compile_options(crc_compile_flags
            INTERFACE
                $<BUILD_INTERFACE:${compiler_flag}>
        )
    endif()
endforeach()

# Dependency resolving ---------------------------------------------------------

add_subdirectory(include)
add_subdirectory(precalc)


# File generation --------------------------------------------------------------
foreach(arch 32 64)
    add_custom_command(OUTPUT tab/gentab${arch}.inc
        COMMAND ${CMAKE_COMMAND} -E make_directory tab
        COMMAND prc --crc${arch} tab/gentab${arch}.inc
        COMMENT "precalc: generate tab/gentab${arch}.inc"
        VERBATIM
    )
endforeach()


add_library(crc_gentab INTERFACE)
add_library(${PACKAGE_NAMESPACE}::gentab ALIAS crc_gentab)
target_sources(crc_gentab
    INTERFACE
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/tab/gentab32.inc>
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/tab/gentab64.inc>
)
target_include_directories(crc_gentab
    INTERFACE
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/tab>
)

# Target Definition ------------------------------------------------------------

target_sources(${PROJECT_NAME}
    PRIVATE
        src/crc8.c
        src/crc16.c
        src/crc32.c
        src/crc64.c
        src/crcccitt.c
        src/crcdnp.c
        src/crckrmit.c
        src/crcsick.c
        src/nmea-chk.c
)

target_link_libraries(${PROJECT_NAME}
    PUBLIC
        crc::common
    PRIVATE
        $<BUILD_INTERFACE:crc::compile_flags>
        $<BUILD_INTERFACE:crc::gentab>
)

# Package configuration --------------------------------------------------------
set(PACKAGE_EXPORTS common crc)
configure_package_config_file(
        cmake/templates/${PACKAGE_NAME}Config.cmake.in
        ${PACKAGE_NAME}Config.cmake
    INSTALL_DESTINATION ${PACKAGE_INSTALL_CMAKE_DIR}
    NO_SET_AND_CHECK_MACRO
)

write_basic_package_version_file(${PROJECT_NAME}ConfigVersion.cmake
    COMPATIBILITY AnyNewerVersion
)

# pkgconfig configuration ------------------------------------------------------
configure_file("cmake/templates/${PACKAGE_NAME}.pc.in"
               "${PACKAGE_NAME}.pc"
    @ONLY
)

# Static Code analysis ---------------------------------------------------------
if(WITH_CLANG_TIDY)
    target_setup_clang_tidy(${PROJECT_NAME})
endif()

# Testing ----------------------------------------------------------------------
if(WITH_UNIT_TEST)

    if(WITH_COVERAGE)
        target_setup_coverage(${PROJECT_NAME})
    endif()

    include(CTest)
    enable_testing()
    add_subdirectory(test)
endif()

# Examples ---------------------------------------------------------------------
if(WITH_EXAMPLE)
    add_subdirectory(examples)
endif()

# Feature summary --------------------------------------------------------------
feature_summary(WHAT ALL
    DESCRIPTION "-- [${PROJECT_NAME} summary] ---------------------------------"
)

# Installations ----------------------------------------------------------------

## Targets installation
install(TARGETS                 ${PROJECT_NAME}
    EXPORT                      ${PROJECT_NAME}Targets
    ARCHIVE         DESTINATION ${PACKAGE_INSTALL_LIBRARY_DIR}
    LIBRARY         DESTINATION ${PACKAGE_INSTALL_LIBRARY_DIR}
    PUBLIC_HEADER   DESTINATION ${PACKAGE_INSTALL_INCLUDE_DIR}
    COMPONENT                   ${PROJECT_NAME}
)

## CMake's configurations
install(EXPORT ${PROJECT_NAME}Targets
    NAMESPACE   ${PACKAGE_NAMESPACE}::
    DESTINATION ${PACKAGE_INSTALL_CMAKE_DIR}
)


## Package configurations
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}Config.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}ConfigVersion.cmake
    DESTINATION ${PACKAGE_INSTALL_CMAKE_DIR}
)

## pkgconfig configurations ----------------------------------------------------
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}.pc"
    DESTINATION ${PACKAGE_INSTALL_LIBRARY_DIR}/pkgconfig
)
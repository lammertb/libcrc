include(FeatureSummary)
set_package_properties(Gcov
    PROPERTIES
        URL         "https://gcc.gnu.org/onlinedocs/gcc/Gcov.html"
        DESCRIPTION "Tool to test code coverage"
)

macro(find_gnu_gcov_executable)
    # potential names:
    # gcov
    # gcov-x // x - major version of GCC
    # ${CROSS_COMPILE}gcov-x
    # ${CROSS_COMPILE}gcov
    string(REGEX MATCH "^[0-9]+" GCC_VERSION_MAJOR
        "${CMAKE_${LANG}_COMPILER_VERSION}"
    )

    set(gcov_filenames gcov-${GCC_VERSION_MAJOR} gcov)

    if(DEFINED ENV{CROSS_COMPILE})
        list(PREPEND gcov_filenames $ENV{CROSS_COMPILE}gcov-${GCC_VERSION_MAJOR} $ENV{CROSS_COMPILE}gcov)
    endif()

    # compiler path provided by call site
    find_program(Gcov_EXECUTABLE
        NAMES ${gcov_filenames}
        HINTS "${COMPILER_PATH}"
    )

    if(Gcov_EXECUTABLE)
        set(Gcov_EXECUTABLE "${Gcov_EXECUTABLE}" CACHE FILEPATH "")
        set(Gcov_COMMAND "${Gcov_EXECUTABLE}" CACHE STRING "")
        mark_as_advanced(Gcov_EXECUTABLE Gcov_COMMAND)
    endif()
endmacro()

get_property(ENABLED_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)

foreach(LANG ${ENABLED_LANGUAGES})
    # no language
    if(LANG STREQUAL "NONE")
        continue()
    endif()

    # if Gcov was already found - skip search
    if(Gcov_${CMAKE_${LANG}_COMPILER_ID}_EXECUTABLE)
        continue()
    endif()

    # gcov usually placed near to the compiler
    get_filename_component(COMPILER_PATH "${CMAKE_${LANG}_COMPILER}" PATH)

    if("${CMAKE_${LANG}_COMPILER_ID}" STREQUAL "GNU")
        find_gnu_gcov_executable()
    elseif("${CMAKE_${LANG}_COMPILER_ID}" MATCHES "^(Apple)?Clang$")

        # potential names:
        # llvm-cov
        # llvm-cov-x   // x - major version of LLVM
        # llvm-cov-x.y // x.y - version string of LLVM
        string(REGEX MATCH "^[0-9]+.[0-9]+" LLVM_VERSION_STRING
            "${CMAKE_${LANG}_COMPILER_VERSION}"
        )

        string(REGEX REPLACE "^([0-9]+).[0-9]+" "\\1" LLVM_VERSION_MAJOR
            "${LLVM_VERSION_STRING}"
        )

        # llvm-cov version < 3.5 not supported
        if(LLVM_VERSION_STRING VERSION_GREATER 3.4)
            find_program(LLVM_cov_EXECUTABLE
                    NAMES "llvm-cov-${LLVM_VERSION_STRING}"
                          "llvm-cov-${LLVM_VERSION_MAJOR}"
                          "llvm-cov"
                    HINTS ${COMPILER_PATH}
                )

            if(LLVM_cov_EXECUTABLE)
                set(Gcov_EXECUTABLE "${LLVM_cov_EXECUTABLE}" CACHE FILEPATH "")
                # llvm-cov gcov - emulates gcov
                file(WRITE
                    ${CMAKE_BINARY_DIR}/CMakeFiles/gcov
                    "#!/bin/bash\nexec ${LLVM_cov_EXECUTABLE} gcov \"$@\""
                )
                file(COPY               ${CMAKE_BINARY_DIR}/CMakeFiles/gcov
                    DESTINATION         ${CMAKE_BINARY_DIR}
                    FILE_PERMISSIONS    OWNER_EXECUTE OWNER_WRITE OWNER_READ
                                        GROUP_EXECUTE             GROUP_READ
                                        WORLD_EXECUTE             WORLD_READ
                )
                set(Gcov_COMMAND "${CMAKE_BINARY_DIR}/gcov" CACHE STRING "")
                mark_as_advanced(LLVM_cov_EXECUTABLE Gcov_EXECUTABLE Gcov_COMMAND)
            else()
                # if nothing found try to find GNU gcov
                find_gnu_gcov_executable()
            endif()
        endif()
    endif()

    if(Gcov_EXECUTABLE)
        # do not repeat search for this compiler anymore
        set(Gcov_${CMAKE_${LANG}_COMPILER_ID}_EXECUTABLE "${Gcov_EXECUTABLE}"
            CACHE FILEPATH "${LANG} gcov binary."
        )
    endif()

endforeach()

# get and parse version
# exports:
# Gcov_VERSION_STRING
# Gcov_VERSION_MAJOR
# Gcov_VERSION_MINOR
# Gcov_VERSION_PATCH
if(Gcov_EXECUTABLE)
    execute_process(
        COMMAND         ${Gcov_COMMAND} -version
        OUTPUT_VARIABLE Gcov_VERSION_RAW
        ERROR_VARIABLE  Gcov_VERSION_RAW
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(Gcov_VERSION_RAW MATCHES "([0-9]+\.[0-9]+\.[0-9]+)")
        set(Gcov_VERSION_STRING "${CMAKE_MATCH_1}")
        string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+" "\\1"
           Gcov_VERSION_MAJOR ${Gcov_VERSION_STRING}
        )
        string(REGEX REPLACE "[0-9]+\\.([0-9]+)\\.[0-9]+" "\\1"
           Gcov_VERSION_MINOR ${Gcov_VERSION_STRING}
        )
        string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1"
           Gcov_VERSION_PATCH ${Gcov_VERSION_STRING}
        )
    endif()
endif()

# include required Modules
include(FindPackageHandleStandardArgs)
# FPHSA to cover flags and version
find_package_handle_standard_args(Gcov
    REQUIRED_VARS Gcov_EXECUTABLE
                  Gcov_COMMAND
    VERSION_VAR   Gcov_VERSION_STRING
)

# clean-up
unset(ENABLED_LANGUAGES)
unset(Gcov_VERSION_RAW)

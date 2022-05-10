# Author: Vitalii Shylienkov <vshylienkov@gmail.com>
# License: MIT
# Copyright: (c) 2018-2022 Vitalii Shylienkov

#[=============================================================================[.rst:
FindGcov
--------

Locate ``gcov``-compatible program:

- ``gcov`` in case of GNU environment
- ``llvm-cov`` for LLVM environment (can emulate ``gcov``)

Requirements
^^^^^^^^^^^^

- At least one of languages ``C`` ``CXX`` should be enabled for the project

Components
^^^^^^^^^^

This module doesn't support modules

Result variables
^^^^^^^^^^^^^^^^
This module will set the following variables in your project:

    :cmake:variable:`Gcov_FOUND`,
    :cmake:variable:`GCOV_FOUND`

        Found ``gcov`` package

    :cmake:variable:`Gcov_EXECUTABLE`

        Path to the ``gcov``/``llvm-cov`` executable

    :cmake:variable:`Gcov_COMMAND`

        String that has to be used to call ``gcov``

    :cmake:variable:`Gcov_VERSION_STRING`

        ``gcov`` full version string

    :cmake:variable:`Gcov_VERSION_MAJOR`

        ``gcov`` major version

    :cmake:variable:`Gcov_VERSION_MINOR`

        ``gcov`` minor version

    :cmake:variable:`Gcov_VERSION_PATCH`

        ``gcov`` version patch

Hints
^^^^^

The following variables may be set to provide hints to this module:

    :cmake:variable:`Gcov_DIR`,
    :cmake:variable:`GCOV_DIR`

        Path to the installation root of gcov

Environment variables with the same names will be also checked:

    :cmake:envvar:`Gcov_DIR`,
    :cmake:envvar:`GCOV_DIR`

Example usage
^^^^^^^^^^^^^

.. code-block:: cmake

    find_package(Gcov REQUIRED)

    execute_process(
        COMMAND         ${Gcov_COMMAND} -version
        OUTPUT_VARIABLE Gcov_VERSION_RAW
        ERROR_VARIABLE  Gcov_VERSION_RAW
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

#]=============================================================================]

# includes ---------------------------------------------------------------------
include(FeatureSummary)
include(FindPackageHandleStandardArgs)

# Internal variables -----------------------------------------------------------
set(cfp_NAME "${CMAKE_FIND_PACKAGE_NAME}")
string(TOUPPER "${cfp_NAME}" CFP_NAME)
set(_Gcov_log_prefix "${_cf_log_prefix}${cfp_NAME}:" CACHE INTERNAL "FindGcov Log prefix")

# Declare package properties ---------------------------------------------------
set_package_properties(${cfp_NAME}
    PROPERTIES
        URL         "https://gcc.gnu.org/onlinedocs/gcc/Gcov.html"
        DESCRIPTION "Tool to test code coverage"
)

# Validate find_package() arguments --------------------------------------------
if(${cfp_NAME}_FIND_COMPONENTS AND NOT ${cfp_NAME}_FIND_QUIETLY)
    message(WARNING "${_${cfp_NAME}_log_prefix} components not supported")
endif()

# Helper functions -------------------------------------------------------------

#[==[
    Search gcov for GNU environment

    Names to search for (x - major version of GCC):

        ${CROSS_COMPILE}gcov-x      # if crosscompilation is enabled and
        ${CROSS_COMPILE}gcov        # an environment variable CROSS_COMPILE is
                                    # defined
        gcov-x
        gcov

    Cache Variables

        ``Gcov_DIR``        # may also be set as an environment variable
        ``GCOV_DIR``        # may also be set as an environment variable
        ``COMPILER_PATH``

    Result variables

        ``Gcov_EXECUTABLE``     # path to gcov executable
        ``Gcov_COMMAND``        # same
#]==]
macro(__gcov_find_gnu_program)

    # get compiler major version
    string(REGEX MATCH "^[0-9]+" GCC_VERSION_MAJOR
        "${CMAKE_${LANG}_COMPILER_VERSION}"
    )

    # build list of potential names
    set(${cfp_NAME}_names gcov gcov-${GCC_VERSION_MAJOR})

    if(CMAKE_CROSSCOMPILING AND DEFINED ENV{CROSS_COMPILE})
        list(APPEND ${cfp_NAME}_names
            $ENV{CROSS_COMPILE}gcov
            $ENV{CROSS_COMPILE}gcov-${GCC_VERSION_MAJOR}
        )
    endif()
    list(REMOVE_DUPLICATES ${cfp_NAME}_names)
    list(REVERSE ${cfp_NAME}_names)

    # build list of hints
    # compiler path provided by call site
    set(${cfp_NAME}_hints "${COMPILER_PATH}")
    list(APPEND ${cfp_NAME}_hints ${__gcc_hints})
    foreach(dir ${cfp_NAME}_DIR ${CFP_NAME}_DIR)
        if(DEFINED dir)
            list(APPEND ${cfp_NAME}_hints "${dir}")
        endif()
    endforeach()
    list(REMOVE_DUPLICATES ${cfp_NAME}_hints)
    unset(dir)

    # look for executable
    find_program(${cfp_NAME}_EXECUTABLE
        NAMES   ${${cfp_NAME}_names}
        HINTS   ${${cfp_NAME}_hints}
            ENV ${cfp_NAME}_DIR
            ENV ${CFP_NAME}_DIR
    )

    # clean-up
    unset(${cfp_NAME}_hints)
    unset(${cfp_NAME}_names)
    unset(GCC_VERSION_MAJOR)

    # store in cache
    if(${cfp_NAME}_EXECUTABLE)
        set(${cfp_NAME}_COMMAND "${${cfp_NAME}_EXECUTABLE}" CACHE STRING "")
        mark_as_advanced(${cfp_NAME}_EXECUTABLE ${cfp_NAME}_COMMAND)
    endif()
endmacro()

#[==[
    Search gcov for LLVM environment

    Names to search for (x - major version of LLVM, y - minor version):

        ${CROSS_COMPILE}llvm-cov-x.y    # if crosscompilation is enabled and
        ${CROSS_COMPILE}llvm-cov-x      # an environment variable CROSS_COMPILE is
        ${CROSS_COMPILE}llvm-cov        # defined
        llvm-cov-x.y
        llvm-cov-x
        llvm-cov

    Cache Variables

        ``Gcov_DIR``        # may also be set as an environment variable
        ``GCOV_DIR``        # may also be set as an environment variable
        ``COMPILER_PATH``

    Result variables

        ``Gcov_EXECUTABLE``     # path to gcov executable
        ``Gcov_COMMAND``        # path to script wrapping call to gcov
#]==]
macro(__gcov_find_llvm_program)
    # get compiler major and minor versions
    string(REGEX MATCH "^[0-9]+.[0-9]+" LLVM_VERSION_STRING
        "${CMAKE_${LANG}_COMPILER_VERSION}"
    )

    # llvm-cov version < 3.5 not supported
    if(LLVM_VERSION_STRING VERSION_GREATER 3.4)
        string(REGEX REPLACE "^([0-9]+).[0-9]+" "\\1" LLVM_VERSION_MAJOR
            "${LLVM_VERSION_STRING}"
        )

        # build list of potential names
        set(${cfp_NAME}_names llvm-cov
                              llvm-cov-${LLVM_VERSION_MAJOR}
                              llvm-cov-${LLVM_VERSION_STRING}
        )

        if(CMAKE_CROSSCOMPILING AND DEFINED ENV{CROSS_COMPILE})
            list(APPEND ${cfp_NAME}_names $ENV{CROSS_COMPILE}llvm-cov
                                          $ENV{CROSS_COMPILE}llvm-cov-${LLVM_VERSION_MAJOR}
                                          $ENV{CROSS_COMPILE}llvm-cov-${LLVM_VERSION_STRING}
            )
        endif()
        list(REMOVE_DUPLICATES ${cfp_NAME}_names)
        list(REVERSE ${cfp_NAME}_names)

        # build list of hints
        # compiler path provided by call site
        set(${cfp_NAME}_hints "${COMPILER_PATH}")
        list(APPEND ${cfp_NAME}_hints ${__clang_hints})
        foreach(dir ${cfp_NAME}_DIR ${CFP_NAME}_DIR)
            if(DEFINED dir)
                list(APPEND ${cfp_NAME}_hints "${dir}")
            endif()
        endforeach()
        list(REMOVE_DUPLICATES ${cfp_NAME}_hints)
        unset(dir)

        # look for executable
        find_program(${cfp_NAME}_EXECUTABLE
            NAMES   ${${cfp_NAME}_names}
            HINTS   ${${cfp_NAME}_hints}
                ENV ${cfp_NAME}_DIR
                ENV ${CFP_NAME}_DIR
        )

        # clean-up
        unset(${cfp_NAME}_hints)
        unset(${cfp_NAME}_names)
        unset(LLVM_VERSION_MAJOR)
        unset(LLVM_VERSION_STRING)

        # store in cache
        if(${cfp_NAME}_EXECUTABLE)
            # create shell script for gcov command
            # llvm-cov gcov - emulates gcov
            file(WRITE ${CMAKE_BINARY_DIR}/CMakeFiles/gcov
                "#!/bin/bash\nexec ${${cfp_NAME}_EXECUTABLE} gcov \"$@\""
            )
            file(COPY               ${CMAKE_BINARY_DIR}/CMakeFiles/gcov
                DESTINATION         ${CMAKE_BINARY_DIR}
                FILE_PERMISSIONS    OWNER_EXECUTE OWNER_WRITE OWNER_READ
                                    GROUP_EXECUTE             GROUP_READ
                                    WORLD_EXECUTE             WORLD_READ
            )
            set(${cfp_NAME}_COMMAND "${CMAKE_BINARY_DIR}/gcov" CACHE STRING "")
            mark_as_advanced(${cfp_NAME}_EXECUTABLE ${cfp_NAME}_COMMAND)
        endif()
    endif()
endmacro()

#TODO:VSH proper version handling

# for each enabled language try to find bonary
get_property(ppt_enabled_languages GLOBAL PROPERTY ENABLED_LANGUAGES)

foreach(LANG IN LISTS ppt_enabled_languages)
    # no language
    if(LANG STREQUAL "NONE")
        continue()
    endif()

    # if Gcov was already found - skip search
    if(${cfp_NAME}_${CMAKE_${LANG}_COMPILER_ID}_EXECUTABLE)
        continue()
    endif()

    # gcov usually placed near to the compiler
    get_filename_component(COMPILER_PATH "${CMAKE_${LANG}_COMPILER}" PATH)

    # if we are in llvm environment
    if(CMAKE_${LANG}_COMPILER_ID MATCHES "^(Apple)?Clang$")
        __gcov_find_llvm_program()
    endif()

    # we are in GNU environment or
    # llvm-cov was not found - fallback to GNU
    if(NOT ${cfp_NAME}_EXECUTABLE)
        __gcov_find_gnu_program()
    endif()

    if(${cfp_NAME}_EXECUTABLE)
        # do not repeat search for this compiler anymore
        set(${cfp_NAME}_${CMAKE_${LANG}_COMPILER_ID}_EXECUTABLE "${${cfp_NAME}_EXECUTABLE}"
            CACHE FILEPATH "${LANG} gcov binary."
        )
    endif()

endforeach()
unset(ppt_enabled_languages)
unset(LANG)

# Figuring out gcov version
if(${cfp_NAME}_EXECUTABLE)
    execute_process(
        COMMAND         ${${cfp_NAME}_COMMAND} -version
        OUTPUT_VARIABLE ${cfp_NAME}_VERSION_RAW
        ERROR_VARIABLE  ${cfp_NAME}_VERSION_RAW
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(${cfp_NAME}_VERSION_RAW MATCHES "([0-9]+\.[0-9]+\.[0-9]+)")
        set(${cfp_NAME}_VERSION_STRING "${CMAKE_MATCH_1}")
        string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+" "\\1"
           ${cfp_NAME}_VERSION_MAJOR ${${cfp_NAME}_VERSION_STRING}
        )
        string(REGEX REPLACE "[0-9]+\\.([0-9]+)\\.[0-9]+" "\\1"
           ${cfp_NAME}_VERSION_MINOR ${${cfp_NAME}_VERSION_STRING}
        )
        string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1"
           ${cfp_NAME}_VERSION_PATCH ${${cfp_NAME}_VERSION_STRING}
        )
    endif()
endif()
unset(${cfp_NAME}_VERSION_RAW)

# FPHSA to cover flags and version
find_package_handle_standard_args(${cfp_NAME}
    REQUIRED_VARS ${cfp_NAME}_EXECUTABLE
                  ${cfp_NAME}_COMMAND
    VERSION_VAR   ${cfp_NAME}_VERSION_STRING
    FAIL_MESSAGE  "Install: `sudo apt install gcov`."
)

# clean-up
unset(cfp_NAME)
unset(CFP_NAME)

# Author: Vitalii Shylienkov <vshylienkov@gmail.com>
# License: MIT
# Copyright: (c) 2018-2022 Vitalii Shylienkov

#[=============================================================================[.rst:
FindIncludeWhatYouUse
---------------------

Locates `include-what-you-use <https://include-what-you-use.org/>`_,
a tool for use with clang to analyze #includes in C and C++ source files.


Components
^^^^^^^^^^

This module doesn't support components

Result variables
^^^^^^^^^^^^^^^^
This module will set the following variables in your project:

    :cmake:variable:`IncludeWhatYouUse_FOUND`,
    :cmake:variable:`INCLUDEWHATYOUUSE_FOUND`

        Found ``IncludeWhatYouUse`` package

    :cmake:variable:`IncludeWhatYouUse_EXECUTABLE`

        Path to the ``include-what-you-use`` executable

    :cmake:variable:`IncludeWhatYouUse_COMMAND`

        String that has to be used to invoke ``include-what-you-use``

    :cmake:variable:`IncludeWhatYouUse_VERSION_STRING`

        ``include-what-you-use`` full version string

    :cmake:variable:`IncludeWhatYouUse_VERSION_MAJOR`

        ``include-what-you-use`` major version

    :cmake:variable:`IncludeWhatYouUse_VERSION_MINOR`

        ``include-what-you-use`` minor version

Hints
^^^^^

The following variables may be set to provide hints to this module:

    :cmake:variable:`IncludeWhatYouUse_DIR`,
    :cmake:variable:`INCLUDEWHATYOUUSE_DIR`

        Path to the installation root of ``include-what-you-use``

Environment variables with the same names will be also checked:

    :cmake:envvar:`IncludeWhatYouUse_DIR`,
    :cmake:envvar:`INCLUDEWHATYOUUSE_DIR`

Example usage
^^^^^^^^^^^^^

.. code-block:: cmake

    find_package(IncludeWhatYouUse REQUIRED)

    set(CMAKE_CXX_INCLUDE_WHAT_YOU_USE "${IncludeWhatYouUse_COMMAND}")

#]=============================================================================]

# includes ---------------------------------------------------------------------
include(FeatureSummary)
include(FindPackageHandleStandardArgs)

# Internal variables -----------------------------------------------------------
set(cfp_NAME "${CMAKE_FIND_PACKAGE_NAME}")
string(TOUPPER "${cfp_NAME}" CFP_NAME)
set(_IncludeWhatYouUse_log_prefix "${_cf_log_prefix}${cfp_NAME}:"  
    CACHE INTERNAL "FindIncludeWhatYouUse Log prefix"
)

# Declare package properties ---------------------------------------------------
set_package_properties(${cfp_NAME}
    PROPERTIES
        URL         "https://include-what-you-use.org/"
        DESCRIPTION "A tool for use with clang to analyze #includes in C and C++ source files"
)

# Validate find_package() arguments --------------------------------------------
# No components supported
if(${cfp_NAME}_FIND_COMPONENTS AND NOT ${cfp_NAME}_FIND_QUIETLY)
    message(WARNING "${_IncludeWhatYouUse_log_prefix} components not supported")
endif()

# build list of hints
set(${cfp_NAME}_hints "")
foreach(dir ${cfp_NAME}_DIR ${CFP_NAME}_DIR)
    if(DEFINED ${dir})
        list(APPEND ${cfp_NAME}_hints "${${dir}}")
    endif()
endforeach()
unset(dir)


# Find binary ------------------------------------------------------------------

find_program(${cfp_NAME}_EXECUTABLE
    NAMES           include-what-you-use
    HINTS           ${${cfp_NAME}_hints}
        ENV         ${cfp_NAME}_DIR
        ENV         ${CFP_NAME}_DIR
    PATH_SUFFIXES   bin
    DOC             "The ${cfp_NAME} executable"
)
unset(${cfp_NAME}_hints)

# Figure out the version -------------------------------------------------------

if(${cfp_NAME}_EXECUTABLE)
    set(${cfp_NAME}_COMMAND "${${cfp_NAME}_EXECUTABLE}" CACHE STRING "")
    mark_as_advanced(${cfp_NAME}_EXECUTABLE ${cfp_NAME}_COMMAND)

    execute_process(
        COMMAND         ${${cfp_NAME}_COMMAND} --version
        RESULT_VARIABLE ${cfp_NAME}_version_result
        OUTPUT_VARIABLE ${cfp_NAME}_version_output
        ERROR_VARIABLE  ${cfp_NAME}_version_error
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(${${cfp_NAME}_version_result} EQUAL 0)
        if(${cfp_NAME}_version_output MATCHES "include-what-you-use ([0-9]+\.[0-9]+)")
            set(${cfp_NAME}_VERSION_STRING "${CMAKE_MATCH_1}")

            string(REGEX REPLACE "([0-9]+)\\.[0-9]+" "\\1"
                ${cfp_NAME}_VERSION_MAJOR "${${cfp_NAME}_VERSION_STRING}"
            )
            string(REGEX REPLACE "[0-9]+\\.([0-9]+)" "\\1"
                ${cfp_NAME}_VERSION_MINOR "${${cfp_NAME}_VERSION_STRING}"
            )
        endif()
    else()
        if(NOT ${cfp_NAME}_FIND_QUIETLY)
            message(WARNING "${_IncludeWhatYouUse_log_prefix}: version query failed: ${${cfp_NAME}_version_error}")
        endif()
    endif()

    unset(${cfp_NAME}_version_result)
    unset(${cfp_NAME}_version_output)
    unset(${cfp_NAME}_version_error)
endif()

# handling
find_package_handle_standard_args(${cfp_NAME}
    REQUIRED_VARS ${cfp_NAME}_EXECUTABLE
                  ${cfp_NAME}_COMMAND
    VERSION_VAR   ${cfp_NAME}_VERSION_STRING
    FAIL_MESSAGE  "Installation: https://github.com/include-what-you-use/include-what-you-use#how-to-install"
)

# clean-up ---------------------------------------------------------------------
unset(CFP_NAME)
unset(cfp_NAME)
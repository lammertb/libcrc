# Author: Vitalii Shylienkov <vshylienkov@gmail.com>
# License: MIT
# Copyright: (c) 2018-2022 Vitalii Shylienkov

#[=============================================================================[.rst:
FindGcovr
---------

Locates `Gcovr <https://gcovr.com/en/stable/>`_, an utility for managing the use
of the ``GNU`` ``gcov`` utility and generating summarized code coverage results.


Components
^^^^^^^^^^

This module doesn't support components

Result variables
^^^^^^^^^^^^^^^^
This module will set the following variables in your project:

    :cmake:variable:`Gcovr_FOUND`,
    :cmake:variable:`GCOVR_FOUND`

        Found ``gcovr`` package

    :cmake:variable:`Gcovr_EXECUTABLE`

        Path to the ``gcovr`` executable

    :cmake:variable:`Gcovr_COMMAND`

        String that has to be used to invoke ``gcovr``

    :cmake:variable:`Gcovr_DIR`

        Root directory of ``gcovr`` installation

    :cmake:variable:`Gcovr_VERSION_STRING`

        ``gcovr`` full version string

    :cmake:variable:`Gcovr_VERSION_MAJOR`

        ``gcovr`` major version

    :cmake:variable:`Gcovr_VERSION_MINOR`

        ``gcovr`` minor version

Hints
^^^^^

The following variables may be set to provide hints to this module:

    :cmake:variable:`Gcovr_DIR`,
    :cmake:variable:`GCOVR_DIR`

        Path to the installation root of ``gcovr``

Environment variables with the same names will be also checked:

    :cmake:envvar:`Gcovr_DIR`,
    :cmake:envvar:`GCOVR_DIR`

Example usage
^^^^^^^^^^^^^

.. code-block:: cmake

    find_package(Gcovr REQUIRED)

    execute_process(
        COMMAND ${Gcovr_COMMAND}
            ${CMAKE_BINARY_DIR}/coverage
            --root ${CMAKE_SOURCE_DIR}
            --gcov-executable ${Gcov_COMMAND}
            --output coverage.txt
    )

#]=============================================================================]

# includes ---------------------------------------------------------------------
include(FeatureSummary)
include(FindPackageHandleStandardArgs)

# Internal variables -----------------------------------------------------------
set(cfp_NAME "${CMAKE_FIND_PACKAGE_NAME}")
string(TOUPPER "${cfp_NAME}" CFP_NAME)
set(_Gcovr_log_prefix "${_cf_log_prefix}${cfp_NAME}:" CACHE INTERNAL "FindGcovr Log prefix")

# Declare package properties ---------------------------------------------------
set_package_properties(${cfp_NAME}
    PROPERTIES
        URL         "https://gcovr.com/en/stable/"
        DESCRIPTION "An utility for managing the use of the GNU gcov utility and generating summarized code coverage results"
)

# Validate find_package() arguments --------------------------------------------
# No components supported
if(${cfp_NAME}_FIND_COMPONENTS AND NOT ${cfp_NAME}_FIND_QUIETLY)
    message(WARNING "${_${cfp_NAME}_log_prefix} components not supported")
endif()

# Helper functions -------------------------------------------------------------
macro(__gcovr_parse_shebang _line)
    set(_OPTIONS "")
    # exclude heading or trailing whitespaces
    string(REGEX REPLACE "^ +| +$" "" _line "${_line}")

    if(_line MATCHES "^#!([^ ]*/python.*)")
        set(_COMMAND "${CMAKE_MATCH_1}")
        if(_COMMAND MATCHES "([^ ]+) (.*)")
            set(_COMMAND "${CMAKE_MATCH_1}")

            # options transformed to cmake ;-list
            string (REGEX REPLACE " +" ";" _OPTIONS "${CMAKE_MATCH_2}")
        endif ()
    elseif(_line MATCHES "^#!(.*env python.*)$")
        set(_COMMAND "${CMAKE_MATCH_1}")
        if(_COMMAND MATCHES "([^ ]+) (python[23]?)(.*)")
            # command
            set(_COMMAND "${CMAKE_MATCH_2}")

            # options transformed to cmake ;-list
            string (REGEX REPLACE " +" ";" _OPTIONS "${CMAKE_MATCH_3}")
        endif ()
    else()
        set(_COMMAND NOTFOUND)
    endif()
    unset(_line)
endmacro()


# build list of hints
set(${cfp_NAME}_hints "")
foreach(dir ${cfp_NAME}_DIR ${CFP_NAME}_DIR)
    if(DEFINED ${dir})
        list(APPEND ${cfp_NAME}_hints "${${dir}}")
    endif()
endforeach()
unset(dir)

# Gcovr can be installed into Python user script directory:
# Unix: ~/.local/bin
# Windows: %APPDATA%/Python/Scripts
# https://www.python.org/dev/peps/pep-0370
find_package(Python QUIET COMPONENTS Interpreter)

if(Python_Interpreter_FOUND)
    execute_process(
        COMMAND ${Python_EXECUTABLE} -m site --user-base
        RESULT_VARIABLE USER_BASE_DIR_RESULT
        OUTPUT_VARIABLE USER_BASE_DIR_OUTPUT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(USER_BASE_DIR_RESULT EQUAL 0)
        list(APPEND ${cfp_NAME}_hints "${USER_BASE_DIR_OUTPUT}")
    endif()
    unset(USER_BASE_DIR_RESULT)
    unset(USER_BASE_DIR_OUTPUT)
endif()
list(REMOVE_DUPLICATES ${cfp_NAME}_hints)

# look for executable
find_program(${cfp_NAME}_EXECUTABLE
    NAMES         gcovr
                  gcovr.py
    HINTS         ${cfp_NAME}_hints
        ENV       ${cfp_NAME}_DIR
        ENV       ${CFP_NAME}_DIR
    PATH_SUFFIXES bin Scripts
    DOC           "The ${cfp_NAME} executable"
)
unset(${cfp_NAME}_hints)

# build up command
if(${cfp_NAME}_EXECUTABLE)
    mark_as_advanced(${cfp_NAME}_EXECUTABLE)

    file(STRINGS "${${cfp_NAME}_EXECUTABLE}" SHEBANG LIMIT_COUNT 1)

    __gcovr_parse_shebang(${SHEBANG})
    unset(SHEBANG)

    if(_COMMAND)
        # escape any special charecter
        string(REGEX REPLACE "([.+*?^$])" "\\\\\\1"
            _Pythong_EXECUTABLE_ESCEPED "${Python_EXECUTABLE}"
        )

        list(FIND _OPTIONS -E INDEX)
        if((INDEX EQUAL -1) AND
            (NOT _COMMAND MATCHES "^${_Pythong_EXECUTABLE_ESCEPED}$"))
            list(INSERT _OPTIONS 0 -E)
        endif()

        set(${cfp_NAME}_COMMAND "${_COMMAND};${_OPTIONS};${${cfp_NAME}_EXECUTABLE}" CACHE STRING "")

        unset(_Pythong_EXECUTABLE_ESCEPED)
        unset(INDEX)
        unset(_COMMAND)
        unset(_OPTIONS)
    else()
        set(${cfp_NAME}_COMMAND "${${cfp_NAME}_EXECUTABLE}" CACHE STRING "")
    endif()
    mark_as_advanced(${cfp_NAME}_COMMAND)
endif()


# Figuring out gcovr version
if(${cfp_NAME}_COMMAND)
    execute_process(
        COMMAND         ${${cfp_NAME}_COMMAND} --version
        OUTPUT_VARIABLE ${cfp_NAME}_VERSION_RAW
        ERROR_VARIABLE  ${cfp_NAME}_VERSION_RAW
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(${cfp_NAME}_VERSION_RAW MATCHES "gcovr ([.0-9]+)")
        set(${cfp_NAME}_VERSION_STRING "${CMAKE_MATCH_1}")

        string(REGEX REPLACE "([0-9]+)\\.[0-9]+" "\\1"
            ${cfp_NAME}_VERSION_MAJOR ${${cfp_NAME}_VERSION_STRING}
        )
        string(REGEX REPLACE "[0-9]+\\.([0-9]+)" "\\1"
            ${cfp_NAME}_VERSION_MINOR ${${cfp_NAME}_VERSION_STRING}
        )
    endif()
endif()
unset(${cfp_NAME}_VERSION_RAW)

# Get gcovr installation dir
if(${cfp_NAME}_EXECUTABLE)
    get_filename_component(${cfp_NAME}_DIR "${${cfp_NAME}_EXECUTABLE}" PATH)
    string(REGEX REPLACE "/bin/?$" "" ${cfp_NAME}_DIR "${${cfp_NAME}_DIR}")
    # cache it
    set(${cfp_NAME}_DIR "${${cfp_NAME}_DIR}" CACHE PATH "${cfp_NAME} installation path")
endif()

# handle components, version, quiet, required and other flags
find_package_handle_standard_args(${cfp_NAME}
    REQUIRED_VARS ${cfp_NAME}_EXECUTABLE
                  ${cfp_NAME}_COMMAND
                  ${cfp_NAME}_DIR
    VERSION_VAR   ${cfp_NAME}_VERSION_STRING
    FAIL_MESSAGE  "Install: `python3 -m pip install -U gcovr`.\nRemove default: `sudo apt remove gcovr`\n"
)

# clean-up
unset(cfp_NAME)
unset(CFP_NAME)

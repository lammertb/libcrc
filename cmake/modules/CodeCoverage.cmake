# Author: Vitalii Shylienkov <vshylienkov@gmail.com>
# License: MIT
# Copyright: (c) 2018-2022 Vitalii Shylienkov

#[=============================================================================[.rst:
CodeCoverage
------------

This file adds functions and utility targets to collect code coverage statistics
in ``txt`` and ``html`` formats.

Synopsis
^^^^^^^^

One can mark all targets coverage of which is required. To mark target see
:cmake:command:`target_setup_coverage`. After the build step first group of
auxiliary files will be created. Then invoke the test binaries to generate the
second group of auxiliary files. And after use utility target ``coverage-report-notest``
to generate coverage report.

#]=============================================================================]

# include guard ----------------------------------------------------------------
include_guard(GLOBAL)

# coverage may be set up from another CodeCoverage.cmake file
# include_guard doesn't work here
# use our own guard mechanism
if(TARGET coverage)
    return()
endif()

get_filename_component(_module_NAME ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
set(_CodeCoverage_log_prefix "${_cf_log_prefix}${_module_NAME}:"
    CACHE INTERNAL "CodeCoverage Log prefix"
)

message(STATUS "${_CodeCoverage_log_prefix} included")

#[=============================================================================[.rst:
Options
^^^^^^^

This file introduce several options, all of them ``OFF`` by default.

- :cmake:option:`COVERAGE_SORT_LINES`

    Sort coverage report by lines covered

- :cmake:option:`COVERAGE_SORT_PERCENTAGE`

    Sort coverage report by percent of coverage

.. note::

    Options :cmake:option:`COVERAGE_SORT_LINES` and :cmake:option:`COVERAGE_SORT_PERCENTAGE`
    are exclusive and shouldn't be both set at time.
#]=============================================================================]
include(FeatureSummary)

option(COVERAGE_SORT_LINES "Sort coverage report by lines covered"    OFF)
add_feature_info([GLOBAL].CoverageSortedLines
    COVERAGE_SORT_LINES
    "Sort entries by increasing number of uncovered lines."
)

option(COVERAGE_SORT_PERCENTAGE
    "Sort coverage report by percent of coverage"
    OFF
)
add_feature_info([GLOBAL].CoverageSortedPercents
    COVERAGE_SORT_PERCENTAGE
    "Sort entries by increasing percentage of uncovered lines."
)

#[=============================================================================[.rst:
Requirements
^^^^^^^^^^^^

Requires:

- ``gcov``

    Uses :cmake:module:`FindGcov` to obtain ``gcov`` command.

- ``gcovr``

    Uses :cmake:module:`FindGcovr` to obtain ``gcovr`` command.

#]=============================================================================]
# Environment validation -------------------------------------------------------
find_package(Gcov REQUIRED)
find_package(Gcovr 4.3 REQUIRED)


#[=============================================================================[.rst:
Variables
^^^^^^^^^

Client of the module can define next variables to control the behavior:

- :cmake:variable:`COVERAGE_PRODUCTS_DIR`

    Path to the directory where auxiliary files will be stored

- :cmake:variable:`COVERAGE_REPORT_DIR`

    Path to the directory where report files will be stored

- :cmake:variable:`COVERAGE_REPORT_TXT_FILE`

    Path to the coverage report in ``txt`` format

- :cmake:variable:`COVERAGE_REPORT_HTML_FILE`

    Path to the coverage report in ``html`` format

.. note::

    Some default values will be set if nothing provided.

#]=============================================================================]
# Variables --------------------------------------------------------------------
if(NOT DEFINED COVERAGE_PRODUCTS_DIR)
    set(COVERAGE_PRODUCTS_DIR ${CMAKE_BINARY_DIR}/coverage)
endif()
if(NOT DEFINED COVERAGE_REPORT_DIR)
    set(COVERAGE_REPORT_DIR ${CMAKE_BINARY_DIR}/coverage_results)
endif()
if(NOT DEFINED COVERAGE_REPORT_TXT_FILE)
    set(COVERAGE_REPORT_TXT_FILE ${COVERAGE_REPORT_DIR}/coverage_results.txt)
endif()
if(NOT DEFINED COVERAGE_REPORT_HTML_FILE)
    set(COVERAGE_REPORT_HTML_FILE ${COVERAGE_REPORT_DIR}/index.html)
endif()

set(Gcovr_PARAMS ${COVERAGE_PRODUCTS_DIR}
    --root ${CMAKE_SOURCE_DIR}
    --gcov-executable ${Gcov_COMMAND}
    $<$<BOOL:${COVERAGE_SORT_LINES}>:--sort-uncovered>
    $<$<BOOL:${COVERAGE_SORT_PERCENTAGE}>:--sort-percentage>
)

#[=============================================================================[.rst:
Utility Targets
^^^^^^^^^^^^^^^

Introduces targets:

- ``coverage-clean``

    Run clean-up to wipe the results of the coverage analysis, including auxiliary
    files.

- ``coverage-report-notest``

    Collect code coverage counters without running all the tests.

- ``coverage-report``

    Collect code coverage counters, running all the tests beforehand.

.. note::

    To run tests utility target ``test`` will be used. In case it is defined.

- ``coverage``

    Alias to ``coverage-report``

#]=============================================================================]

# Targets ----------------------------------------------------------------------
add_custom_target(coverage-clean
    COMMAND
        ${CMAKE_COMMAND} -E remove -f ${COVERAGE_PRODUCTS_DIR}/*.gcda
    COMMAND
        ${CMAKE_COMMAND} -E remove -f ${COVERAGE_PRODUCTS_DIR}/*.gcno
    COMMAND
        ${CMAKE_COMMAND} -E remove -f ${COVERAGE_REPORT_DIR}/*.html
    COMMAND
        ${CMAKE_COMMAND} -E remove -f ${COVERAGE_REPORT_TXT_FILE}
    COMMENT
        "${_CodeCoverage_log_prefix} cleaning: code coverage counters and reports"
)

add_custom_target(coverage-report-notest
    COMMAND
        ${CMAKE_COMMAND} -E make_directory ${COVERAGE_REPORT_DIR}
    COMMAND
        ${CMAKE_COMMAND} -E make_directory ${COVERAGE_PRODUCTS_DIR}
    COMMAND
        find ${CMAKE_BINARY_DIR}/ -type f \"\(\" -name \"*.gcda\" -o -name \"*.gcno\" \"\)\"
            -exec cp -u -t ${COVERAGE_PRODUCTS_DIR}/ {} +
    COMMAND
        ${Gcovr_EXECUTABLE} ${Gcovr_PARAMS}
        $<$<BOOL:$<TARGET_PROPERTY:coverage-report-notest,EXCLUDE>>:$<TARGET_PROPERTY:coverage-report-notest,EXCLUDE>>
        --output ${COVERAGE_REPORT_TXT_FILE}
    COMMAND
        ${Gcovr_EXECUTABLE} ${Gcovr_PARAMS} --html-details --print-summary
        $<$<BOOL:$<TARGET_PROPERTY:coverage-report-notest,EXCLUDE>>:$<TARGET_PROPERTY:coverage-report-notest,EXCLUDE>>
        --output ${COVERAGE_REPORT_HTML_FILE}
    COMMENT
        "${_CodeCoverage_log_prefix} processing: code coverage counters and generating report"
    DEPENDS
        coverage-clean
    COMMAND_EXPAND_LISTS
)

add_custom_target(coverage-report DEPENDS coverage-report-notest)
add_custom_target(coverage DEPENDS coverage-report)

if(TARGET test)
    add_dependencies(coverage-report test)
endif()

#[=============================================================================[.rst:
Commands
^^^^^^^^

.. cmake:command:: target_setup_coverage

Marks target to be analyzed with code coverage

.. code-block:: cmake

    target_setup_coverage(<target_name> [EXCLUDE <REGEXP>[ <REGEXP> ...])

This command set needed compilation and linkage flags to the target ``<target_name>``.

    ``EXCLUDE``

        Allows to set regular expressions to exclude directories or files from
        coverage analysis.

#]=============================================================================]
# Functions --------------------------------------------------------------------
function(target_setup_coverage target)

    # Parameters verification --------------------------------------------------
    if(NOT TARGET ${target})
        message(FATAL_ERROR "${_CodeCoverage_log_prefix} target not found: ${target}")
    endif()

    # Find out un-aliased name of the target
    get_target_property(TARGET_ALIASED_TARGET ${target} ALIASED_TARGET)
    if(TARGET_ALIASED_TARGET)
        set(target ${TARGET_ALIASED_TARGET})
    endif()

    # parse EXCLUDE option
    cmake_parse_arguments(_PARAM "" "" "EXCLUDE" ${ARGN})
    if(_PARAM_EXCLUDE)
        list(TRANSFORM _PARAM_EXCLUDE PREPEND "\"")
        list(TRANSFORM _PARAM_EXCLUDE APPEND "\"")
        list(TRANSFORM _PARAM_EXCLUDE PREPEND "--exclude;")

        set_property(TARGET coverage-report-notest
             APPEND
             PROPERTY
                EXCLUDE ${_PARAM_EXCLUDE}
        )
    endif()


    message(STATUS "${_CodeCoverage_log_prefix} setup coverage for target: ${target}")

    # Target settings ----------------------------------------------------------
    target_compile_options(${target} PRIVATE --coverage)
    target_link_libraries(${target} PRIVATE --coverage)
endfunction()

# clean-up ---------------------------------------------------------------------
unset(_module_NAME)

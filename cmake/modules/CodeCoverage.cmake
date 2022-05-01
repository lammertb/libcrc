include_guard(GLOBAL)

# coverage may be set up from another CodeCoverage.cmake file
# include_guard doesn't work here
# use our own guard mechanism
if(TARGET coverage)
    return()
endif()

get_filename_component(module_name ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
set(${module_name}_log_prefix "${module_name}:")

message(STATUS "${${module_name}_log_prefix} included")

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

# Environment validation -------------------------------------------------------
find_package(Gcov REQUIRED)
find_package(Gcovr 4.3 REQUIRED)

# Variables --------------------------------------------------------------------
set(COVERAGE_PRODUCTS_DIR ${CMAKE_BINARY_DIR}/coverage 
    CACHE PATH "Coverage products"
)
set(COVERAGE_REPORT_DIR ${CMAKE_BINARY_DIR}/coverage_results 
    CACHE PATH "Coverage reports"
)
set(COVERAGE_REPORT_TXT_FILE ${CMAKE_BINARY_DIR}/coverage_results.txt 
    CACHE FILEPATH "Coverage text report"
)
set(COVERAGE_REPORT_HTML_FILE ${COVERAGE_REPORT_DIR}/index.html 
    CACHE FILEPATH "Coverage html report"
)


set(GCOVR_PARAMS ${COVERAGE_PRODUCTS_DIR} 
    --root ${CMAKE_SOURCE_DIR}
    --gcov-executable ${Gcov_COMMAND}
    $<$<BOOL:${COVERAGE_SORT_LINES}>:--sort-uncovered>
    $<$<BOOL:${COVERAGE_SORT_PERCENTAGE}>:--sort-percentage>
)

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
        "${${module_name}_log_prefix} cleaning: code coverage counters and reports"
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
        ${Gcovr_EXECUTABLE} ${GCOVR_PARAMS} 
        $<$<BOOL:$<TARGET_PROPERTY:coverage-report-notest,EXCLUDE>>:$<TARGET_PROPERTY:coverage-report-notest,EXCLUDE>>
        --output ${COVERAGE_REPORT_TXT_FILE}
    COMMAND
        ${Gcovr_EXECUTABLE} ${GCOVR_PARAMS} --html-details --print-summary
        $<$<BOOL:$<TARGET_PROPERTY:coverage-report-notest,EXCLUDE>>:$<TARGET_PROPERTY:coverage-report-notest,EXCLUDE>>
        --output ${COVERAGE_REPORT_HTML_FILE}
    COMMENT
        "${${module_name}_log_prefix} processing: code coverage counters and generating report"
    DEPENDS 
        coverage-clean
    COMMAND_EXPAND_LISTS
)

add_custom_target(coverage-report DEPENDS coverage-report-notest)
add_custom_target(coverage DEPENDS coverage-report)

if(TARGET test)
    add_dependencies(coverage-report test)
endif()

# Functions --------------------------------------------------------------------
function(target_setup_coverage target)

    # Parameters verification --------------------------------------------------
    if(NOT TARGET ${target})
        message(FATAL_ERROR "${${module_name}_log_prefix} target not found: ${target}")
    endif()

    cmake_parse_arguments(_PARAM "" "" "EXCLUDE" ${ARGN})
    if(_PARAM_EXCLUDE)
        list(TRANSFORM _PARAM_EXCLUDE PREPEND "\"")
        list(TRANSFORM _PARAM_EXCLUDE APPEND "\"")
        list(TRANSFORM _PARAM_EXCLUDE PREPEND "--exclude;")
        get_target_property(EXCLUDE_PROPERTY coverage-report-notest EXCLUDE)

        if(EXCLUDE_PROPERTY)
            list(APPEND EXCLUDE_PROPERTY "${_PARAM_EXCLUDE}")
        else()
            set(EXCLUDE_PROPERTY "${_PARAM_EXCLUDE}")
        endif()

        set_target_properties(coverage-report-notest
            PROPERTIES
                EXCLUDE "${EXCLUDE_PROPERTY}"
        )
    endif()

    get_target_property(TARGET_ALIASED_TARGET ${target} ALIASED_TARGET)
    if(TARGET_ALIASED_TARGET)
        set(target ${TARGET_ALIASED_TARGET})
    endif()

    message(STATUS "${${module_name}_log_prefix} setup coverage for target: ${target}")

    # Target settings ----------------------------------------------------------
    target_compile_options(${target}
        PRIVATE
            --coverage
    )

    target_link_libraries(${target} PRIVATE --coverage)
endfunction()


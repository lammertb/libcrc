# includes ---------------------------------------------------------------------
include(FeatureSummary)
include(FindPackageHandleStandardArgs)

# Internal variables -----------------------------------------------------------
set(cfp_NAME "${CMAKE_FIND_PACKAGE_NAME}")
string(TOUPPER "${cfp_NAME}" CFP_NAME)
set(${cfp_NAME}_log_prefix "${cfp_NAME}:")

# Declare package properties ---------------------------------------------------
set_package_properties(${cfp_NAME}
    PROPERTIES
        URL         "https://include-what-you-use.org/"
        DESCRIPTION "A tool for use with clang to analyze #includes in C and C++ source files"
)

# Validate find_package() arguments --------------------------------------------

if(${cfp_NAME}_FIND_COMPONENTS AND NOT ${cfp_NAME}_FIND_QUIETLY)
    message(WARNING "${${cfp_NAME}_log_prefix} components not supported")
endif()

# Find binary ------------------------------------------------------------------

find_program(${cfp_NAME}_EXECUTABLE
    NAMES           include-what-you-use
    HINTS           ${${cfp_NAME}_DIR} ${${CFP_NAME}_DIR}
        ENV         ${cfp_NAME}_DIR
        ENV         ${CFP_NAME}_DIR
    PATH_SUFFIXES   bin
    DOC             "The ${cfp_NAME} executable"
)

# Figure out the version -------------------------------------------------------

if(${cfp_NAME}_EXECUTABLE)
    set(${cfp_NAME}_COMMAND "${${cfp_NAME}_EXECUTABLE}")
    mark_as_advanced(${cfp_NAME}_EXECUTABLE ${cfp_NAME}_COMMAND)

    execute_process(
        COMMAND         ${${cfp_NAME}_EXECUTABLE} --version
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
            message(WARNING "${${cfp_NAME}_log_prefix}: version query failed: ${${cfp_NAME}_version_error}")
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
unset(${cfp_NAME}_log_prefix)
unset(CFP_NAME)
unset(cfp_NAME)
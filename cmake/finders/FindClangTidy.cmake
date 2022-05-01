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
        URL         "https://clang.llvm.org/extra/clang-tidy/index.html"
        DESCRIPTION "A clang-based C++ “linter” tool"
)

# Validate find_package() arguments --------------------------------------------

if(${cfp_NAME}_FIND_COMPONENTS AND NOT ${cfp_NAME}_FIND_QUIETLY)
    message(WARNING "${${cfp_NAME}_log_prefix} components not supported")
endif()

# Build list of names ----------------------------------------------------------
set(${cfp_NAME}_names "clang-tidy")

set(known_file_suffixes 3.9 4.0 5.0 6.0)
set(known_file_suffixes_major 7 8 9 10 13 14 15)

if(DEFINED ${cfp_NAME}_FIND_VERSION)                                            # if specific version was requested
    if(${cfp_NAME}_FIND_VERSION_EXACT)                                          # if exact this version has to be found
        if(${cfp_NAME}_FIND_VERSION VERSION_LESS 7)                             # we are looking for two components
            set(suffix ${${cfp_NAME}_FIND_VERSION_MAJOR})

            if(${cfp_NAME}_FIND_VERSION_COUNT EQUAL 1)                          # if only one component provided
                string(APPEND suffix ".0")                                      # we explicitly append .0
            else()
                string(APPEND suffix ".${${cfp_NAME}_FIND_VERSION_MINOR}")      # otherwise we take only two components
            endif()

            if(suffix IN_LIST known_file_suffixes)                              # if we know this version
                list(APPEND ${cfp_NAME}_names "clang-tidy-${suffix}")           # add to the list of searched names
            endif()
        else()                                                                  # one component suffix
            if(     (${cfp_NAME}_FIND_VERSION_COUNT EQUAL 1)                    # if requested one component
                OR (    (${cfp_NAME}_FIND_VERSION_COUNT EQUAL 2)                # or two with the second equals 0
                    AND (${cfp_NAME}_FIND_VERSION_MINOR EQUAL 0)))

                if(${cfp_NAME}_FIND_VERSION_MAJOR IN_LIST known_file_suffixes_major)
                    list(APPEND ${cfp_NAME}_names "clang-tidy-${${cfp_NAME}_FIND_VERSION_MAJOR}")
                endif()
            endif()
        endif()
    else()                                                                      # not exact version requested
        foreach(suffix IN LISTS known_file_suffixes known_file_suffixes_major)
            if(NOT suffix VERSION_LESS ${cfp_NAME}_FIND_VERSION)
                list(APPEND ${cfp_NAME}_names "clang-tidy-${suffix}")
            endif()
        endforeach()
    endif()
else()                                                                          # no specific version requested
    foreach(suffix IN LISTS known_file_suffixes known_file_suffixes_major)
        list(APPEND ${cfp_NAME}_names "clang-tidy-${suffix}")
    endforeach()
endif()

list(REVERSE ${cfp_NAME}_names)

unset(suffix)
unset(known_file_suffixes)
unset(known_file_suffixes_major)

# Find binary ------------------------------------------------------------------

find_program(${cfp_NAME}_EXECUTABLE
    NAMES           ${${cfp_NAME}_names}
    HINTS           ${${cfp_NAME}_DIR} ${${CFP_NAME}_DIR}
        ENV         ${cfp_NAME}_DIR
        ENV         ${CFP_NAME}_DIR
    PATH_SUFFIXES   bin
    DOC             "The ${cfp_NAME} executable"
)

unset(${cfp_NAME}_names)

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
        if(${cfp_NAME}_version_output MATCHES "([0-9]+\.[0-9]+\.[0-9]+)")
            set(${cfp_NAME}_VERSION_STRING "${CMAKE_MATCH_1}")
            
            string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+" "\\1"
                ${cfp_NAME}_VERSION_MAJOR "${${cfp_NAME}_VERSION_STRING}"
            )
            string(REGEX REPLACE "[0-9]+\\.([0-9]+)\\.[0-9]+" "\\1"
                ${cfp_NAME}_VERSION_MINOR "${${cfp_NAME}_VERSION_STRING}"
            )
            string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1"
                ${cfp_NAME}_VERSION_PATCH "${${cfp_NAME}_VERSION_STRING}"
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

# handling ---------------------------------------------------------------------
find_package_handle_standard_args(${cfp_NAME}
    REQUIRED_VARS ${cfp_NAME}_EXECUTABLE
                  ${cfp_NAME}_COMMAND
    VERSION_VAR   ${cfp_NAME}_VERSION_STRING
    FAIL_MESSAGE  "Installation: https://apt.llvm.org/"
)

# clean-up ---------------------------------------------------------------------
unset(${cfp_NAME}_log_prefix)
unset(CFP_NAME)
unset(cfp_NAME)
include(FeatureSummary)
set_package_properties(Gcovr
    PROPERTIES
        URL         "https://gcovr.com/en/stable/"
        DESCRIPTION "An utility for managing the use of the GNU gcov utility and generating summarized code coverage results"
)

# No components supported
if(Gcovr_FIND_COMPONENTS AND NOT Gcovr_FIND_QUIETLY)
    message(STATUS "Find Gcovr: components not supported")
endif()

# Hints where to look for Gcovr executable
# Environment and user variables
set(Gcovr_HINTS "")
foreach(hint Gcovr_DIR GCOVR_DIR)
    if(DEFINED ${hint})
        if((EXISTS "${${hint}}") AND (IS_DIRECTORY "${${hint}}"))
            list(APPEND Gcovr_HINTS "${${hint}}")
        endif()
    endif()
    if(DEFINED ENV{${hint}})
        if((EXISTS "$ENV{${hint}}") AND (IS_DIRECTORY "$ENV{${hint}}"))
            list(APPEND Gcovr_HINTS "$ENV{${hint}}")
        endif()
    endif()
endforeach()

# Gcovr can be installed into Python user script directory: 
# Unix: ~/.local/bin
# Windows: %APPDATA%/Python/Scripts
# https://www.python.org/dev/peps/pep-0370
find_package(Python QUIET COMPONENTS Interpreter)

if(Python_Interpreter_FOUND)
    execute_process(
        COMMAND "${Python_EXECUTABLE}" -m site --user-base
        RESULT_VARIABLE USER_BASE_DIR_RESULT
        OUTPUT_VARIABLE USER_BASE_DIR_OUTPUT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(USER_BASE_DIR_RESULT EQUAL 0)
        list(APPEND Gcovr_HINTS "${USER_BASE_DIR_OUTPUT}")
    endif()
endif()

find_program(Gcovr_EXECUTABLE
    NAMES             gcovr
                      gcovr.py
    HINTS             ${Gcovr_HINTS}
    PATH_SUFFIXES bin Scripts
    DOC               "The Gcovr executable"
)

if(Gcovr_EXECUTABLE)
    mark_as_advanced(Gcovr_EXECUTABLE)

    file(STRINGS "${Gcovr_EXECUTABLE}" SHEBANG LIMIT_COUNT 1)
    
    set(Gcovr_PYTHON_COMMAND "${Python_EXECUTABLE}")
    set(Gcovr_PYTHON_OPTIONS "")
    if(SHEBANG MATCHES "^#!(.*/python.*)$")
        # exclude heading or trailing whitespaces
        string(REGEX REPLACE "^ +| +$" "" Gcovr_PYTHON_COMMAND "${CMAKE_MATCH_1}")

        if(Gcovr_PYTHON_COMMAND MATCHES "([^ ]+) (.*)")
            # command
            set(Gcovr_PYTHON_COMMAND "${CMAKE_MATCH_1}")

            # options transformed to cmake ;-list
            string (REGEX REPLACE " +" ";" Gcovr_PYTHON_OPTIONS "${CMAKE_MATCH_2}")
        endif ()
    elseif(SHEBANG MATCHES "^#!(.*env python.*)$")
        # exclude heading or trailing whitespaces
        string(REGEX REPLACE "^ +| +$" "" Gcovr_PYTHON_COMMAND "${CMAKE_MATCH_1}")
        
        if(Gcovr_PYTHON_COMMAND MATCHES "([^ ]+) (python[23]?) ?(.*)")
            # command
            set(Gcovr_PYTHON_COMMAND "${CMAKE_MATCH_1}" "${CMAKE_MATCH_2}")

            if(CMAKE_MATCH_3)
                # options transformed to cmake ;-list
                string (REGEX REPLACE " +" ";" Gcovr_PYTHON_OPTIONS "${CMAKE_MATCH_3}")
            endif()
        endif ()
    endif()

    # escape any special charecter
    string(REGEX REPLACE "([.+*?^$])" "\\\\\\1" 
        _Gcovr_PYTHON_COMMAND_RE "${Python_EXECUTABLE}"
    )

    list(FIND Gcovr_PYTHON_OPTIONS -E INDEX)
    if((INDEX EQUAL -1) AND 
        (NOT Gcovr_PYTHON_COMMAND MATCHES "^${_Gcovr_PYTHON_COMMAND_RE}$"))
        list(INSERT Gcovr_PYTHON_OPTIONS 0 -E)
    endif()
endif()


if(Gcovr_EXECUTABLE)
    if(Gcovr_PYTHON_COMMAND)
        execute_process(
            COMMAND ${Gcovr_PYTHON_COMMAND} ${Gcovr_PYTHON_OPTIONS} "${Gcovr_EXECUTABLE}" --version
            OUTPUT_VARIABLE Gcovr_VERSION_RAW
            ERROR_VARIABLE  Gcovr_VERSION_RAW
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
        )
    elseif(UNIX)
        execute_process(
            COMMAND "${Gcovr_EXECUTABLE}" --version
            OUTPUT_VARIABLE Gcovr_VERSION_RAW
            ERROR_VARIABLE  Gcovr_VERSION_RAW
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
        )
    endif()

    if(Gcovr_VERSION_RAW MATCHES "gcovr ([.0-9]+)")
        set(Gcovr_VERSION_STRING "${CMAKE_MATCH_1}")
        
        string(REGEX REPLACE "([0-9]+)\\.[0-9]+" "\\1" 
            Gcovr_VERSION_MAJOR ${Gcovr_VERSION_STRING}
        )
        string(REGEX REPLACE "[0-9]+\\.([0-9]+)" "\\1" 
            Gcovr_VERSION_MINOR ${Gcovr_VERSION_STRING}
        )
    endif()
endif()

if(Gcovr_EXECUTABLE)
    get_filename_component(Gcovr_DIR "${Gcovr_EXECUTABLE}" PATH)
    string(REGEX REPLACE "/bin/?$" "" Gcovr_DIR "${Gcovr_DIR}")
    # cache it
    set(Gcovr_DIR "${Gcovr_DIR}" CACHE PATH "Gcovr installation path")
endif()

# handle components, version, quiet, required and other flags
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Gcovr
    REQUIRED_VARS Gcovr_EXECUTABLE Gcovr_DIR
    VERSION_VAR   Gcovr_VERSION_STRING
    FAIL_MESSAGE  "Install: `python3 -m pip install -U gcovr`.\nRemove default: `sudo apt remove gcovr`\n"
)
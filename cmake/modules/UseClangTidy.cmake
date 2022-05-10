# Author: Vitalii Shylienkov <vshylienkov@gmail.com>
# License: MIT
# Copyright: (c) 2018-2022 Vitalii Shylienkov

#[=============================================================================[.rst:
UseClangTidy
------------

This file provides support for `clang-tidy <https://include-what-you-use.org/>`_.
See `CMAKE_<LANG>_CLANG_TIDY <https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_CLANG_TIDY.html>`_
for details.

Synopsis
^^^^^^^^

Two main ways to generate static code analysis:

- in-build generation

    During build step of a project clang-tidy check every C/C++ source file.

.. warning::

    CMake will compile source code with ``clang`` which emulates the behavior
    of the compiler CMake detects by default or provided via toolchain files or
    configuration step parameters.

- out-of-build generation

    Using command :cmake:command:`target_setup_clang_tidy` to mark those target for which
    ``clang-tidy`` has to run and then use custom target ``run-clang-tidy``.

.. warning::

    Files generated in build time will not exist and may lead to analysis errors.

#]=============================================================================]


# include guard ----------------------------------------------------------------
include_guard(GLOBAL)

get_filename_component(_module_NAME ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
set(_UseClangTidy_log_prefix "${_cf_log_prefix}${_module_NAME}:"
    CACHE INTERNAL "UseClangTidy Log prefix"
)

message(STATUS "${_UseClangTidy_log_prefix} included")


#[=============================================================================[.rst:
Requirements
^^^^^^^^^^^^

Requires:

- ``clang-tidy``

    Uses :cmake:module:`FindClangTidy` to obtain ``clang-tidy`` command.
#]=============================================================================]
find_package(ClangTidy REQUIRED)

get_property(enabled_languages GLOBAL PROPERTY ENABLED_LANGUAGES)

foreach(language C CXX)
    if((language IN_LIST enabled_languages) AND (NOT DEFINED CMAKE_${language}_CLANG_TIDY))
        set(CMAKE_${language}_CLANG_TIDY "${ClangTidy_COMMAND}")
    endif()
endforeach()

unset(language)
unset(enabled_languages)

# produce compilation database
#[=============================================================================[.rst:
Compilation database
^^^^^^^^^^^^^^^^^^^^
.. note::

    For producing static code analysis diagnostics in out-of-build variant compilation
    database will be generated.

#]=============================================================================]
set(CMAKE_EXPORT_COMPILE_COMMANDS true)

#[=============================================================================[.rst:
Custom Targets
^^^^^^^^^^^^^^

Introduces targets:

- ``run-clang-tidy``

    Global target to run ``clang-tidy`` in out-of-build variant.

.. code-block:: shell

    # configure step
    cmake .. -DWITH_CLANG_TIDY=ON
    cmake --build . --target run-clang-tidy

#]=============================================================================]
add_custom_target(run-clang-tidy
    COMMENT "Static Code Analysis: clang-tidy"
)

#[=============================================================================[.rst:
Commands
^^^^^^^^

.. cmake:command:: target_setup_clang_tidy

Marks target to be analyzed by ``clang-tidy`` in out-of-build variant::

    target_setup_clang_tidy(<target_name>)

This command collects sources for the target ``<target_name>`` and create custom
target ``clang-tidy-<target_name>`` in order to run ``clang-tidy`` for this source
files. This target will be run in scope of execution ``run-clang-tidy`` target.

#]=============================================================================]
# Functions --------------------------------------------------------------------
function(target_setup_clang_tidy target)

    # Parameters verification --------------------------------------------------
    if(NOT TARGET ${target})
        message(FATAL_ERROR "${_UseClangTidy_log_prefix} target not found: ${target}")
    endif()

    # Find out un-aliased name of the target
    get_target_property(target_aliased_target ${target} ALIASED_TARGET)
    if(target_aliased_target)
        set(target ${target_aliased_target})
    endif()
    unset(target_aliased_target)

    # Prevent duplication of the target names
    set(clang_tidy_target "clang-tidy-${target}")
    if(NOT TARGET clang_tidy_target)
        message(STATUS "${_UseClangTidy_log_prefix} setup clang tidy for target: ${target}")

        # collect target sources
        get_target_property(target_sources ${target} SOURCES)
        list(FILTER target_sources EXCLUDE REGEX ".*\.hpp")

        # create custom target to analyze sources
        add_custom_target(${clang_tidy_target}
                COMMAND
                    "${ClangTidy_COMMAND}"
                        --quiet
                        -p "${CMAKE_BINARY_DIR}"
                        ${target_sources}
                DEPENDS ${CMAKE_BINARY_DIR}/compile_commands.json ${target_sources}
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                VERBATIM
                COMMAND_EXPAND_LISTS
                COMMENT "Static Code Analysis: clang-tidy: ${target}"
        )
        unset(target_sources)
    endif()

    add_dependencies(run-clang-tidy ${clang_tidy_target})
    unset(clang_tidy_target)
endfunction()

# clean-up ---------------------------------------------------------------------
unset(_module_NAME)

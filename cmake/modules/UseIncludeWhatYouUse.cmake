# Author: Vitalii Shylienkov <vshylienkov@gmail.com>
# License: MIT
# Copyright: (c) 2018-2022 Vitalii Shylienkov

#[=============================================================================[.rst:
UseIncludeWhatYouUse
--------------------

This file provides support for `include-what-you-use <https://include-what-you-use.org/>`_.
See `CMAKE_<LANG>_INCLUDE_WHAT_YOU_USE
<https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_INCLUDE_WHAT_YOU_USE.html>`_
for details.

Synopsis
^^^^^^^^

Pre-compile step will be added to each compilation run to validate the set of
included files

#]=============================================================================]

# include guard ----------------------------------------------------------------
include_guard(GLOBAL)

get_filename_component(_module_NAME ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
set(_UseIncludeWhatYouUse_log_prefix "${_cf_log_prefix}${_module_NAME}:"
    CACHE INTERNAL "UseIncludeWhatYouUse Log prefix"
)

message(STATUS "${_UseIncludeWhatYouUse_log_prefix} included")

#[=============================================================================[.rst:
Requirements
^^^^^^^^^^^^

Requires:

- ``include-what-you-use``

    Uses :cmake:module:`FindIncludeWhatYouUse` to obtain ``include-what-you-use``
    command.
#]=============================================================================]
find_package(IncludeWhatYouUse REQUIRED)

get_property(enabled_languages GLOBAL PROPERTY ENABLED_LANGUAGES)

foreach(language C CXX)
    if((language IN_LIST enabled_languages) AND (NOT DEFINED CMAKE_${language}_INCLUDE_WHAT_YOU_USE))
        set(CMAKE_${language}_INCLUDE_WHAT_YOU_USE "${IncludeWhatYouUse_COMMAND}")
    endif()
endforeach()

# clean-up ---------------------------------------------------------------------
unset(language)
unset(enabled_languages)
include_guard(GLOBAL)

get_filename_component(module_name ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
set(${module_name}_log_prefix "${module_name}:")

message(STATUS "${${module_name}_log_prefix} included")

find_package(IncludeWhatYouUse REQUIRED)

get_property(enabled_languages GLOBAL PROPERTY ENABLED_LANGUAGES)

foreach(language C CXX)
    if((language IN_LIST enabled_languages) AND (NOT DEFINED CMAKE_${language}_INCLUDE_WHAT_YOU_USE))
        set(CMAKE_${language}_INCLUDE_WHAT_YOU_USE "${IncludeWhatYouUse_COMMAND}")
    endif()
endforeach()

unset(language)
unset(enabled_languages)
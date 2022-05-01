include_guard(GLOBAL)

get_filename_component(module_name ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
set(${module_name}_log_prefix "${module_name}:")

message(STATUS "${${module_name}_log_prefix} included")

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
set(CMAKE_EXPORT_COMPILE_COMMANDS true)

add_custom_target(run-clang-tidy
    COMMENT "Static Code Analysis: clang-tidy"
)

# Functions --------------------------------------------------------------------
function(target_setup_clang_tidy target)

    # Parameters verification --------------------------------------------------
    if(NOT TARGET ${target})
        message(FATAL_ERROR "${${module_name}_log_prefix} target not found: ${target}")
    endif()

    get_target_property(target_aliased_target ${target} ALIASED_TARGET)
    if(target_aliased_target)
        set(target ${target_aliased_target})
    endif()

    set(clang_tidy_target "clang-tidy-${target}")
    if(NOT TARGET clang_tidy_target)
        message(STATUS "${${module_name}_log_prefix} setup clang tidy for target: ${target}")

        get_target_property(target_sources ${target} SOURCES)

        add_custom_target(${clang_tidy_target}
                COMMAND
                    "${ClangTidy_COMMAND}"
                        --quiet
                        -p "${CMAKE_BINARY_DIR}"
                        ${target_sources}
                DEPENDS ${CMAKE_BINARY_DIR}/compile_commands.json
                WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                VERBATIM
                COMMAND_EXPAND_LISTS
                COMMENT "Static Code Analysis: clang-tidy: ${target}"
            )
    endif()

    add_dependencies(run-clang-tidy ${clang_tidy_target})
endfunction()
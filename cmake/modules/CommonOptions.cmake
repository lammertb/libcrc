include_guard(GLOBAL)

get_filename_component(module_name ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
set(${module_name}_log_prefix "${module_name}:")

message(STATUS "${${module_name}_log_prefix} included")

include(FeatureSummary)

option(WITH_DOCUMENTING "Generate documentation for all projects" OFF)
add_feature_info([ALL].Documenting WITH_DOCUMENTING
    "Generate documentation for all projects"
)

option(WITH_UNIT_TEST "Build unit tests for all projects" OFF)
add_feature_info([ALL].Unit-tests WITH_UNIT_TEST
    "Build unit tests for all projects"
)

option(WITH_COMPONENT_TEST "Build component tests for all projects" OFF)
add_feature_info([ALL].Component-tests WITH_COMPONENT_TEST
    "Build component tests for all projects"
)

option(WITH_SW_ELEMENT_TEST "Build software element tests for all projects" OFF)
add_feature_info([ALL].Software-Element-tests WITH_SW_ELEMENT_TEST
    "Build software element tests for all projects"
)

option(WITH_COVERAGE "Generate code coverage counters for all projects" OFF)
add_feature_info([ALL].Coverage WITH_COVERAGE
    "Generate code coverage counters for all projects"
)

option(WITH_EXAMPLE "Build examples for all projects" OFF)
add_feature_info([ALL].Example WITH_EXAMPLE
    "Build examples for all projects"
)

option(ENGINEERING_BUILD "Build all projects as engineering variant" OFF)
add_feature_info([ALL].Engineering-build ENGINEERING_BUILD
    "Build all projects as engineering variant"
)

option(WITH_INCLUDE_WHAT_YOU_USE "Build with include-what-you-use globally enabled" OFF)
add_feature_info([GLOBAL].include-what-you-use WITH_INCLUDE_WHAT_YOU_USE
    "Build with include-what-you-use globally enabled"
)

option(WITH_CLANG_TIDY "Build with clang-tidy globally enabled" OFF)
add_feature_info([GLOBAL].clang-tidy WITH_CLANG_TIDY
    "Build with clang-tidy globally enabled"
)

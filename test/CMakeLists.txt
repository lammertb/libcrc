cmake_minimum_required(VERSION 3.12)

# build all project test utility target ----------------------------------------
if(NOT TARGET all_unit_tests)
    add_custom_target(all_unit_tests
        COMMENT "Build all unit tests"
    )
endif()

add_custom_target(${PROJECT_NAME}_all_unit_tests
    COMMENT "Build all ${PROJECT_NAME} unit tests"
)

add_dependencies(all_unit_tests ${PROJECT_NAME}_all_unit_tests)

# Target Declaration -----------------------------------------------------------
add_executable(testall)

# Target Definition ------------------------------------------------------------
target_sources(testall
    PRIVATE
        testnmea.c
        testcrc.c
        testall.c
)

target_include_directories(testall
    PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

target_link_libraries(testall
    PRIVATE
        crc::crc
)

add_test(
    NAME    ${PROJECT_NAME}_tesall
    COMMAND $<TARGET_FILE:testall>
)

add_dependencies(${PROJECT_NAME}_all_unit_tests testall)

# run all project test utility target ------------------------------------------
if(NOT TARGET run_unit_tests)
    add_custom_target(run_unit_tests
        COMMENT "Run all unit tests"
    )
endif()

add_custom_target(run_${PROJECT_NAME}_unit_tests
    COMMAND ${CMAKE_CTEST_COMMAND} -j $(nproc) --tests-regex \"${PROJECT_NAME}_*\" --output-on-failure
    COMMENT "Run all ${PROJECT_NAME} unit tests"
    VERBATIM
)

add_dependencies(run_unit_tests run_${PROJECT_NAME}_unit_tests)
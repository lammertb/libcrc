include_guard(GLOBAL)

if (TARGET test_gtest)  # make more strict include guard
    return()
endif()

get_filename_component(module_name ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
set(${module_name}_log_prefix "${module_name}:")

message(STATUS "${${module_name}_log_prefix} included")

# declare provided wrapping libraries

add_library(test_gtest      INTERFACE IMPORTED GLOBAL)
add_library(test_gmock      INTERFACE IMPORTED GLOBAL)
add_library(test_gtest_main INTERFACE IMPORTED GLOBAL)
add_library(test_gmock_main INTERFACE IMPORTED GLOBAL)

add_library(test::gtest       ALIAS test_gtest)
add_library(test::gmock       ALIAS test_gmock)
add_library(test::gtest::main ALIAS test_gtest_main)
add_library(test::gmock::main ALIAS test_gmock_main)

macro(usegtest_link_if_available lib)
    if(TARGET ${lib})
        target_link_libraries(test_${lib} INTERFACE ${lib})
    else()
        message(WARNING "${${module_name}_log_prefix} `${lib}` will be not available, it is not included to current build")
    endif()
endmacro()

if(TARGET gtest)                            # gtest is already included
    target_link_libraries(test_gtest INTERFACE gtest)
    usegtest_link_if_available(gmock)
    usegtest_link_if_available(gtest_main)
    usegtest_link_if_available(gmock_main)
else()
    find_package(GTest CONFIG)              # try to find cmake installed

    if(GTest_FOUND)
        if(TARGET GTest::gtest_main)        # since cmake 3.20
            target_link_libraries(test_gtest      INTERFACE GTest::gtest)
            target_link_libraries(test_gmock      INTERFACE GTest::gmock)
            target_link_libraries(test_gtest_main INTERFACE GTest::gtest_main)
            target_link_libraries(test_gmock_main INTERFACE GTest::gmock_main)
        elseif(TARGET GTest::Main)          # since cmake 3.5
            target_link_libraries(test_gtest      INTERFACE GTest::GTest)
            target_link_libraries(test_gmock      INTERFACE GMock::GMock)
            target_link_libraries(test_gtest_main INTERFACE GTest::Main)
            target_link_libraries(test_gmock_main INTERFACE GMock::Main)
        else()                              # found but no targets - prior to cmake 3.5
            find_package(Threads REQUIRED)  # mandatory

            if(Threads_FOUND)
                target_link_libraries(test_gtest      INTERFACE ${GTEST_LIBRARIES}      Threads::Threads)
                target_link_libraries(test_gmock      INTERFACE ${GMOCK_LIBRARY}        Threads::Threads)
                target_link_libraries(test_gtest_main INTERFACE ${GTEST_MAIN_LIBRARIES} Threads::Threads)
                target_link_libraries(test_gmock_main INTERFACE ${GMOCK_MAIN_LIBRARY}   Threads::Threads)
                
                foreach(_target gtest gmock)
                    target_include_directories(test_${_target}      INTERFACE ${GTEST_INCLUDE_DIRS})
                    target_include_directories(test_${_target}_main INTERFACE ${GTEST_INCLUDE_DIRS})
                endforeach()
            endif()
        endif()
    else()                                  # gtest was not found, we will fetch it and add to build
        include(FetchContent)

        FetchContent_Declare(googletest
            GIT_REPOSITORY  https://github.com/google/googletest.git
            GIT_TAG         release-1.11.0
        )

        FetchContent_GetProperties(googletest)
        if(NOT googletest_POPULATED)
            FetchContent_Populate(googletest)
            add_subdirectory(${googletest_SOURCE_DIR} ${googletest_BINARY_DIR})
        endif()

        target_link_libraries(test_gtest INTERFACE gtest)
        target_link_libraries(test_gmock INTERFACE gmock)

        target_link_libraries(test_gtest_main INTERFACE gtest_main)
        target_link_libraries(test_gmock_main INTERFACE gmock_main)
    endif()
endif()

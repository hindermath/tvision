cmake_minimum_required(VERSION 3.15)

project(TvisionCalculator VERSION 1.0.0 LANGUAGES CXX)

include(FetchContent)

# The stand-alone application needs only the tvision library. Keeping the
# dependency's examples and tests disabled reduces build time and disk usage.
set(TV_BUILD_EXAMPLES OFF CACHE BOOL "Build tvision examples" FORCE)
set(TV_BUILD_TESTS OFF CACHE BOOL "Build tvision tests" FORCE)
set(TV_BUILD_USING_GPM OFF CACHE BOOL "Use GPM on Linux" FORCE)
set(TV_LIBRARY_UNITY_BUILD OFF CACHE BOOL "Use tvision unity build" FORCE)
set(TV_OPTIMIZE_BUILD ON CACHE BOOL "Use tvision precompiled headers" FORCE)

FetchContent_Declare(
    tvision
    GIT_REPOSITORY https://github.com/hindermath/tvision.git
    GIT_TAG        9c354cc56ade01124d91dbdce746fad0b043309b
    GIT_PROGRESS   TRUE
)

# CI and tvision contributors can select a local checkout without changing
# this file by setting FETCHCONTENT_SOURCE_DIR_TVISION during configuration.
FetchContent_MakeAvailable(tvision)

function(enable_project_warnings target)
    if (MSVC)
        target_compile_options(${target} PRIVATE /W4)
    else()
        target_compile_options(${target} PRIVATE -Wall -Wextra -Wpedantic)
    endif()
endfunction()

add_library(calculator_engine STATIC
    src/calculator_engine.cpp
)

target_include_directories(calculator_engine PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
)
target_compile_features(calculator_engine PUBLIC cxx_std_17)
set_target_properties(calculator_engine PROPERTIES CXX_EXTENSIONS OFF)
enable_project_warnings(calculator_engine)

add_executable(tvision_calculator
    src/main.cpp
)

target_compile_features(tvision_calculator PRIVATE cxx_std_17)
target_link_libraries(tvision_calculator PRIVATE
    calculator_engine
    tvision::tvision
)
set_target_properties(tvision_calculator PROPERTIES CXX_EXTENSIONS OFF)
enable_project_warnings(tvision_calculator)

include(CTest)
if (BUILD_TESTING)
    add_executable(calculator_engine_tests
        tests/calculator_engine_test.cpp
    )
    target_compile_features(calculator_engine_tests PRIVATE cxx_std_17)
    target_link_libraries(calculator_engine_tests PRIVATE calculator_engine)
    set_target_properties(calculator_engine_tests PROPERTIES CXX_EXTENSIONS OFF)
    enable_project_warnings(calculator_engine_tests)

    add_test(NAME calculator_engine COMMAND calculator_engine_tests)
endif()

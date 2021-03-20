cmake_minimum_required(VERSION 3.14)
set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" "${CMAKE_CURRENT_LIST_DIR}/cmake/modules")

# register D support
include(EnableD)

project(portage-hook-ctrl D)
include(ProjectSetup)

# application code
add_subdirectory(src)

# frontend
add_subdirectory(app)

# unit tests
option(ENABLE_TESTS "Build the unit tests" OFF)
if (ENABLE_TESTS)
    add_subdirectory(tests)
endif()

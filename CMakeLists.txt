cmake_minimum_required(VERSION 3.15...3.18)

project(datrie LANGUAGES C CXX)

option(PY_DEBUG "Set if python being linked is a Py_DEBUG build" OFF)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING
            "Default build type: RelWithDebInfo" FORCE)
endif()

include(GNUInstallDirs)

find_package(pybind11 CONFIG)

if(pybind11_FOUND)
  message(STATUS "System pybind11 found")
else()
  message(STATUS "Fetching pybind11 from github")
  # Fetch pybind11
  include(FetchContent)

  FetchContent_Declare(
    pybind11
    GIT_REPOSITORY https://github.com/pybind/pybind11
    GIT_TAG v2.6.1
  )
  FetchContent_MakeAvailable(pybind11)
endif()

find_package(Threads REQUIRED)

if (${PYTHON_IS_DEBUG})
  set(PY_DEBUG ON)
endif()

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH}
    ${PROJECT_SOURCE_DIR}/cmake/)

include_directories(${PROJECT_SOURCE_DIR}/src)

add_subdirectory(src)

cmake_minimum_required(VERSION 3.15...3.18)

option(PY_DEBUG "Set if python being linked is a Py_DEBUG build" OFF)
option(USE_LIBDATRIE_PKG "Use OS-provided libdatrie package")
if(DEFINED ENV{HAVE_LIBDATRIE_PKG})
  set(USE_LIBDATRIE_PKG "$ENV{HAVE_LIBDATRIE_PKG}")
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING
            "Default build type: RelWithDebInfo" FORCE)
endif()

project(datrie LANGUAGES C CXX)

include(GNUInstallDirs)
include(CheckIncludeFile)
include(CheckIncludeFileCXX)
include(CheckIncludeFiles)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

if(USE_LIBDATRIE_PKG)
  find_package(Datrie)
endif()

if(USE_LIBDATRIE_PKG AND NOT Datrie_FOUND)
  find_package(PkgConfig)
  pkg_check_modules(DATRIE datrie-0.2 IMPORTED_TARGET)
endif()

if(NOT USE_LIBDATRIE_PKG)
  message(STATUS "Fetching libdatrie from github")
  # Fetch libdatrie
  include(FetchContent)

  FetchContent_Declare(
          libdatrie
          GIT_REPOSITORY https://github.com/tlwg/libdatrie
          GIT_TAG v0.2.13
  )
  FetchContent_MakeAvailable(libdatrie)
  # this gets us the package source directory
endif()

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

if(${PYTHON_IS_DEBUG})
  set(PY_DEBUG ON)
endif()

include_directories(${PROJECT_SOURCE_DIR}/src)
add_subdirectory(src)

cmake_minimum_required(VERSION 3.18)

option(PY_DEBUG "Set if python being linked is a Py_DEBUG build" OFF)
option(USE_GIT_SUBMODULE "Use submodules during build" ON)
option(USE_LIBDATRIE_PKG "Use OS-provided libdatrie package" OFF)

if(DEFINED ENV{HAVE_LIBDATRIE_PKG})
  set(USE_LIBDATRIE_PKG "$ENV{HAVE_LIBDATRIE_PKG}")
  if(USE_LIBDATRIE_PKG)
    set(USE_GIT_SUBMODULE OFF)
  endif()
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING
            "Default build type: RelWithDebInfo" FORCE)
endif()

if(NOT SCM_VERSION_INFO)
	# use git describe for scm_version
	EXECUTE_PROCESS(COMMAND git describe
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			OUTPUT_VARIABLE SCM_VERSION_INFO
			OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

project(datrie LANGUAGES C CXX VERSION ${SCM_VERSION_INFO})

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_VERBOSE_MAKEFILE ON)  # this does nothing with ninja :/
#set(CMAKE_VERBOSE_BUILD ON)  # this also does nothing with ninja :/

message(STATUS "Trying ${CMAKE_BUILD_TYPE} build type for datrie ${SCM_VERSION_INFO}")

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

if(USE_GIT_SUBMODULE)
  message(STATUS "Trying libdatrie submodule")
  find_package(Git QUIET)
  if(GIT_FOUND AND EXISTS "${PROJECT_SOURCE_DIR}/.git")
    # Update submodules as needed
    if(GIT_SUBMODULE)
      if(NOT EXISTS "${PROJECT_SOURCE_DIR}/libdatrie/datrie-0.2.pc.in")
        message(STATUS "Submodule update")
        execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        RESULT_VARIABLE GIT_SUBMOD_RESULT)
        if(NOT GIT_SUBMOD_RESULT EQUAL "0")
          message(FATAL_ERROR "git submodule update --init failed with ${GIT_SUBMOD_RESULT}, please checkout submodules")
        endif()
      endif()
    endif()
  endif()
endif()

# needs pybind11 in build host without some help (not found in python venv)
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
    GIT_TAG v2.7.1
  )
  FetchContent_MakeAvailable(pybind11)
endif()

find_package(Threads REQUIRED)

if(${PYTHON_IS_DEBUG})
  set(PY_DEBUG ON)
endif()

include_directories(${PROJECT_SOURCE_DIR}/src)
add_subdirectory(src)

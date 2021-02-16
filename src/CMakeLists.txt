set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(cython_module datrie)

find_package(Cython REQUIRED)

set(datrie_include_dir "${PROJECT_SOURCE_DIR}/src")
set(cython_output "${CMAKE_CURRENT_SOURCE_DIR}/${cython_module}.c")
set(cython_src ${cython_module}.pyx)
# Track cython sources
file(GLOB cy_srcs *.pyx *.pxd)

# .pyx -> .c
add_custom_command(OUTPUT ${cython_output}
                   COMMAND ${CYTHON_EXECUTABLE}
                           -a -2
                           --fast-fail
                           -I ${datrie_include_dir}
                           --output-file ${cython_output} ${cython_src}
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                   DEPENDS ${cy_srcs}
                   COMMENT "Cythonizing extension ${cython_src}")

if(NOT USE_LIBDATRIE_PKG)
  # use the locally cloned source from FetchContent
  set(DATRIE_INCLUDE_DIR "${libdatrie_SOURCE_DIR}")
  file(GLOB_RECURSE DATRIE_SOURCES
       LIST_DIRECTORIES true
       "${libdatrie_SOURCE_DIR}/datrie/*.c")
  list(APPEND cython_output ${DATRIE_SOURCES})
  include_directories(${DATRIE_INCLUDE_DIR})
endif()

add_library(${cython_module} MODULE ${cython_output})

set_target_properties(${cython_module}
                      PROPERTIES PREFIX "${PYTHON_MODULE_PREFIX}"
                      SUFFIX "${PYTHON_MODULE_EXTENSION}")

target_include_directories(${cython_module} PUBLIC
                           ${PYTHON_INCLUDE_DIRS})

target_compile_definitions(${cython_module} PRIVATE VERSION_INFO=${SCM_VERSION_INFO})

if(Datrie_FOUND)
  include_directories(${DATRIE_INCLUDE_DIRS})
  target_link_libraries(${cython_module} PRIVATE Datrie::Datrie)
elseif(DATRIE_FOUND)
  include_directories(${DATRIE_INCLUDE_DIRS})
  target_link_libraries(${cython_module} PRIVATE PkgConfig::DATRIE)
endif()

if(APPLE)
  # macos/appleclang needs this
  target_link_libraries(${cython_module} PRIVATE pybind11::module)
  target_link_libraries(${cython_module} PRIVATE pybind11::python_link_helper)
endif()

if(MSVC)
  target_compile_options(${cython_module} PRIVATE /utf-8)
  target_link_libraries(${cython_module} PRIVATE ${PYTHON_LIBRARIES})
  target_link_libraries(${cython_module} PRIVATE pybind11::windows_extras)
endif()

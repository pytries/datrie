set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Cython REQUIRED)

set(cython_module datrie)

set(datrie_include_dir "${PROJECT_SOURCE_DIR}/src")
set(cython_output "${CMAKE_CURRENT_SOURCE_DIR}/${cython_module}.c")
set(cython_src ${cython_module}.pyx)
# Track cython sources
file(GLOB cy_srcs *.pyx *.pxd)

# .pyx -> .cpp
add_custom_command(OUTPUT ${cython_output}
                   COMMAND ${CYTHON_EXECUTABLE}
                           -a -2
                           --fast-fail
                           -I ${datrie_include_dir}
                           --output-file ${cython_output} ${cython_src}
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                   DEPENDS ${cy_srcs}
                   COMMENT "Cythonizing extension ${cython_src}")

add_library(${cython_module} MODULE ${cython_output})

set_target_properties(${cython_module}
                      PROPERTIES PREFIX "${PYTHON_MODULE_PREFIX}"
                      SUFFIX "${PYTHON_MODULE_EXTENSION}")

target_include_directories(${cython_module} PUBLIC
                           ${PYTHON_INCLUDE_DIRS})

target_compile_definitions(${cython_module} PRIVATE VERSION_INFO=${SCM_VERSION_INFO})

# here we get to jump through some hoops to find libdatrie on the manylinux
# docker CI images, etc
find_package(datrie CONFIG NAMES datrie)

if(datrie_FOUND)
  message(STATUS "System datrie found")
  target_link_libraries(${cython_module} PRIVATE datrie)
elseif(NOT MSVC)
  message(STATUS "Trying PkgConfig")
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(DATRIE datrie-0.2 REQUIRED IMPORTED_TARGET)

  if(DATRIE_FOUND)
    include_directories(${DATRIE_INCLUDE_DIRS})
    target_link_libraries(${cython_module} PRIVATE PkgConfig::DATRIE)
  else()
    # last resort for manylinux: just try it
    message(STATUS "Blindly groping instead")
    link_directories("/usr/lib64" "/usr/lib")
    target_link_libraries(${cython_module} PRIVATE "libdatrie.so")
  endif()
else()
  # even though we used vcpkg, we get to do the manual dance with windows
  find_path(DATRIE_INCLUDE_DIRS datrie/triedefs.h)
  find_library(DATRIE_LIBS NAMES datrie libdatrie)
  target_include_directories(${cython_module} PUBLIC ${DATRIE_INCLUDE_DIRS})
  target_link_libraries(${cython_module} PRIVATE ${DATRIE_LIBS})
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

# This module finds headers and libdatrie library.
# Results are reported in variables:
#  Datrie_FOUND           - True if headers and library were found
#  Datrie_INCLUDE_DIRS    - libdatrie include directories
#  Datrie_LIBRARIES       - libdatrie library to be linked

find_path(Datrie_INCLUDE_DIR
  NAMES datrie/triedefs.h
  HINTS
    ENV VCPKG_ROOT
  PATH_SUFFIXES include include/datrie
  PATHS
  ~/Library/Frameworks
  /Library/Frameworks
  /opt/local
  /opt
  /usr
  /usr/local/
)

find_library(Datrie_LIBRARY
  NAMES datrie libdatrie
  HINTS
    ENV VCPKG_ROOT
  PATH_SUFFIXES lib lib64 lib32
  PATHS
  ~/Library/Frameworks
  /Library/Frameworks
  /opt/local
  /opt
  /usr
  /usr/local/
)

mark_as_advanced(Datrie_INCLUDE_DIR Datrie_LIBRARY)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Datrie
  REQUIRED_VARS Datrie_LIBRARY Datrie_INCLUDE_DIR)

if(Datrie_FOUND)
  # need if _FOUND guard to allow project to autobuild; can't overwrite imported target even if bad
  set(Datrie_INCLUDE_DIRS ${Datrie_INCLUDE_DIR})
  set(Datrie_LIBRARIES ${Datrie_LIBRARY})

  if(NOT TARGET Datrie::Datrie)
    add_library(Datrie::Datrie INTERFACE IMPORTED)
    set_target_properties(Datrie::Datrie PROPERTIES
                          INTERFACE_LINK_LIBRARIES "${Datrie_LIBRARIES}"
                          INTERFACE_INCLUDE_DIRECTORIES "${Datrie_INCLUDE_DIR}"
                        )
  endif()
endif(Datrie_FOUND)

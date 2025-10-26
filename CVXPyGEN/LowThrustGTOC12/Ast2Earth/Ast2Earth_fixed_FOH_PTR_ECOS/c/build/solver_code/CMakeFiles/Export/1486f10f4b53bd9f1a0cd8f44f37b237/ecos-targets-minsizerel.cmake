#----------------------------------------------------------------
# Generated CMake target import file for configuration "MinSizeRel".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "ecos::ecos" for configuration "MinSizeRel"
set_property(TARGET ecos::ecos APPEND PROPERTY IMPORTED_CONFIGURATIONS MINSIZEREL)
set_target_properties(ecos::ecos PROPERTIES
  IMPORTED_IMPLIB_MINSIZEREL "${_IMPORT_PREFIX}/lib/ecos.lib"
  IMPORTED_LOCATION_MINSIZEREL "${_IMPORT_PREFIX}/bin/ecos.dll"
  )

list(APPEND _cmake_import_check_targets ecos::ecos )
list(APPEND _cmake_import_check_files_for_ecos::ecos "${_IMPORT_PREFIX}/lib/ecos.lib" "${_IMPORT_PREFIX}/bin/ecos.dll" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)

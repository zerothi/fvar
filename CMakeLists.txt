cmake_minimum_required(VERSION 3.17 FATAL_ERROR)

# Include overwrites before setting up the project
set(CMAKE_USER_MAKE_RULES_OVERRIDE
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/fdictDefaultFlags.cmake")

list(APPEND CMAKE_MESSAGE_CONTEXT fdict)

# Project installation follows GNU installation directory convention
include(GNUInstallDirs)

# Export CMake package file
include(CMakePackageConfigHelpers)

project(fdict
  LANGUAGES Fortran
  DESCRIPTION "Fortran dictionary for arbitrary data-types"
)

# Define project versions
file(STRINGS "${PROJECT_SOURCE_DIR}/VERSION" PROJECT_VERSION)

# Listify the string
string(REPLACE "." ";" VERSION_LIST ${PROJECT_VERSION})
list(GET VERSION_LIST 0 PROJECT_VERSION_MAJOR)
list(GET VERSION_LIST 1 PROJECT_VERSION_MINOR)
list(GET VERSION_LIST 2 PROJECT_VERSION_PATCH)
unset(VERSION_LIST)


# Define library specific content
option(FDICT_INSTALL "Install fdict (or use as sub-project)" ${PROJECT_IS_TOP_LEVEL})
set(FDICT_AUTHOR       "Nick Papior")
set(FDICT_DESCRIPTION  "Fortran dictionary for arbitrary data-types")
set(FDICT_URL          "https://github.com/zerothi/fdict")
set(FDICT_LICENSE      "Mozilla Public License, 2.0 (MPL-2.0)")
message(STATUS "
** PROJECT_NAME = ${PROJECT_NAME}
** Please report any build problems here: ${FDICT_URL}
")


if (NOT DEFINED CMAKE_Fortran_MODULE_DIRECTORY)
	set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/fortran_modules)
endif ()

list(APPEND FDICT_FYPPFLAGS
  "-DFDICT_NAME=\\\"${PROJECT_NAME}\\\""
  "-DFDICT_VERSION=\\\"${PROJECT_VERSION}\\\""
  "-DFDICT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}"
  "-DFDICT_VERSION_MINOR=${PROJECT_VERSION_MINOR}"
  "-DFDICT_VERSION_PATCH=${PROJECT_VERSION_PATCH}"
)

# Add project options
include(cmake/fdictOptions.cmake)
include(cmake/fdictFyppify.cmake)


# create library.
add_subdirectory(src)


# Now for installing stuff.

# Generate the version include file
configure_file(fdict.inc.in fdict.inc @ONLY)
install(
  FILES
	  "${CMAKE_CURRENT_BINARY_DIR}/fdict.inc"
	DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

# Globally define a place where we will install
# cmake configuration stuff, *Target.cmake *Version.cmake etc.
set(FDICT_INSTALL_CMAKECONFIG_DIR
  "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
  CACHE STRING
  "Determine where the CMake configuration files will be installed"
)
mark_as_advanced(FDICT_INSTALL_CMAKECONFIG_DIR)


if(BUILD_SHARED_LIBS OR PROJECT_VERSION_MAJOR EQUAL 0)
  # Due to the uncertain ABI compatibility of Fortran shared libraries
  # limit compatibility for dynamic linking to same minor version.
  set(COMPATIBILITY SameMinorVersion)
else()
  # Require API compatibility via semantic versioning for static linking.
  set(COMPATIBILITY SameMajorVersion)
endif()


# Create pkg-config file
configure_file(fdict.pc.in fdict.pc @ONLY)
install(
  FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pc"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig"
)

# Export a cmake package configure file
configure_package_config_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Config.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
  INSTALL_DESTINATION "${FDICT_INSTALL_CMAKECONFIG_DIR}"
)

# Export a package version file
write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY ${COMPATIBILITY}
)

# Install cmake configuration files
install(
  FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
  DESTINATION "${FDICT_INSTALL_CMAKECONFIG_DIR}"
)

install(
  FILES "LICENSE"
  DESTINATION "${CMAKE_INSTALL_DATADIR}/licences/${PROJECT_NAME}"
)


# Install project
install(
  EXPORT ${PROJECT_NAME}-targets
  FILE ${PROJECT_NAME}Targets.cmake
  NAMESPACE ${PROJECT_NAME}::
  DESTINATION "${FDICT_INSTALL_CMAKECONFIG_DIR}"
)

# Export a cmake configuration for the targets if used as a sub-project
export(EXPORT ${PROJECT_NAME}-targets
  NAMESPACE ${PROJECT_NAME}::
  FILE "${PROJECT_NAME}Targets.cmake"
)

list(POP_BACK CMAKE_MESSAGE_CONTEXT)

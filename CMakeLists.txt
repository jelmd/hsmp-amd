#
# Minimum version of cmake required
#
cmake_minimum_required(VERSION 3.5.0)

set(CMAKE_SKIP_BUILD_RPATH true)
set(CMAKE_SKIP_RPATH true)
#
#   cmake command line options:
#
#   1) Set ENABLE_STATIC_LIB to either "1" or "0".
#      If not set, the default value is "disbaled"
#
#      example #cmake -DENABLE_STATIC_LIB=1 ..

## Set default module path if not already set
if(NOT DEFINED CMAKE_MODULE_PATH)
    set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules/")
endif()
## Include common cmake modules
include(utils)

set(ENABLE_STATIC_LIB OFF CACHE STRING
    "Whether to build as a Static Library. Set 1 to Enable, default is Disabled.")

set(E_SMI "e_smi")
set (REAL_NAME "hsmp-amd")
set(E_SMI_COMPONENT "lib${REAL_NAME}")
set(E_SMI_TARGET "${E_SMI}64")
set(E_SMI_LIB "${REAL_NAME}")
set(E_SMI_STATIC "${REAL_NAME}_static")
set(CMAKE_C_FLAGS "-Wall")

if(${USE_CLANG})
	set(CMAKE_C_COMPILER "/usr/bin/clang")
	set(CMAKE_CXX_COMPILER "/usr/bin/clang++")
	set(CMAKE_C_FLAGS "-O3 -march=native -flto -Wall")
endif()

################# Determine the library version #########################
## Setup the package version based on git tags.
set(PKG_VERSION_GIT_TAG_PREFIX "esmi_pkg_ver")

set(ENV{ESMI_BUILD_ID} "${ESMI_BUILD_ID}")

# provide a version fallback if Git or default version info is n/a.
if (NOT DEFINED FB_VERSION)
	set (FB_VERSION "1.0.0.0")
endif()
get_package_version_number("${FB_VERSION}" ${PKG_VERSION_GIT_TAG_PREFIX})
message("Package version: ${PKG_VERSION_STR}")

# Debian package specific variables
# Set a default value for the package version

# VERSION_* variables should be set by get_package_version_number
if (${VERSION_PATCH})
    set (${E_SMI}_VERSION_PATCH "${VERSION_PATCH}")
else()
    set(${E_SMI}_VERSION_PATCH "0")
endif ()
set(SO_VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")
set (${E_SMI}_VERSION_BUILD "${VERSION_ID}")
set(${E_SMI}_VERSION_MAJOR "${VERSION_MAJOR}")
set(${E_SMI}_VERSION_MINOR "${VERSION_MINOR}")
message("SOVERSION: ${SO_VERSION_STRING}")

set(DEB_INC "/usr/include/x86_64-linux-gnu/asm/amd_hsmp.h")
set(RHEL_INC "/usr/include/asm/amd_hsmp.h")
string(ASCII 27 Esc)
set(Magenta "${Esc}[35m")

## Define default variable and variables for the optional build target
##  e_smi_lib-dev
set(SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}
	CACHE STRING "Location of E-SMI source code.")
set(CMAKE_INSTALL_PREFIX "/usr"
                                CACHE STRING "Default installation directory.")
set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/e-sms"
                                      CACHE STRING "Default packaging prefix.")

project(${REAL_NAME})
include(GNUInstallDirs)
message("LD_RUN_PATH=${CMAKE_LIBRARY_ARCHITECTURE}")
SET(CMAKE_EXE_LINKER_FLAGS
	"${CMAKE_EXE_LINKER_FLAGS} -Wl,-rpath -Wl,\$ORIGIN:\$ORIGIN/../lib/${CMAKE_LIBRARY_ARCHITECTURE}")

set(E_SMI_HSMP_INC "${PROJECT_SOURCE_DIR}/include/asm/amd_hsmp.h")

if (NOT EXISTS ${E_SMI_HSMP_INC})
	if (NOT EXISTS ${DEB_INC} AND NOT EXISTS ${RHEL_INC})
		message(FATAL_ERROR "amd_hsmp.h is missing. Its needed for E-smi compilation.")
	else()
		message(${Magenta} "amd_hsmp.h is not available locally, its used from standard installation path.")
	endif()
endif()

# Create a configure file to get version info from within library
configure_file(
  "${PROJECT_SOURCE_DIR}/src/${E_SMI_TARGET}Config.in"
  "${PROJECT_SOURCE_DIR}/include/e_smi/${E_SMI_TARGET}Config.h")

if (NOT DEFINED CPACK_PACKAGE_VENDOR)
    set(CPACK_PACKAGE_VENDOR "AMD")
endif()

if (NOT DEFINED CPACK_PACKAGE_CONTACT)
    set(CPACK_PACKAGE_CONTACT "Advanced Micro Devices Inc.")
endif()

if (NOT DEFINED CPACK_PACKAGE_DESCRIPTION_SUMMARY)
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY
		"EPYC™ System Management Interface library")
endif()

if (NOT E_SMI_PACKAGE)
    set(E_SMI_PACKAGE ${REAL_NAME})
endif()

set(CPACK_PACKAGE_FILE_NAME "${E_SMI_PACKAGE}-${PKG_VERSION_STR}")
## Verbose output.
set(CMAKE_VERBOSE_MAKEFILE on)

## Compiler flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -fno-rtti -m64")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse -msse2 -std=c++11 ")
# Use this instead of above for 32 bit
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")

if ("${CMAKE_BUILD_TYPE}" STREQUAL Release)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")
else ()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ggdb -O0 -DDEBUG")
endif ()

set(SRC_DIR "src")
set(INC_DIR "include/e_smi")

include_directories([BEFORE] [SYSTEM] ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(SMI_SRC_LIST ${SMI_SRC_LIST} "${SRC_DIR}/e_smi.c")
set(SMI_SRC_LIST ${SMI_SRC_LIST} "${SRC_DIR}/e_smi_monitor.c")
set(SMI_SRC_LIST ${SMI_SRC_LIST} "${SRC_DIR}/e_smi_utils.c")
set(SMI_SRC_LIST ${SMI_SRC_LIST} "${SRC_DIR}/e_smi_plat.c")

set(SMI_TOOL "e_smi_tool")
set(SMI_TOOL_STATIC "e_smi_tool_static")

add_executable(${SMI_TOOL} "tools/e_smi_tool.c")
set_target_properties(${SMI_TOOL} PROPERTIES OUTPUT_NAME "${REAL_NAME}")
target_link_libraries(${SMI_TOOL} ${E_SMI_LIB})

## If the tool to be linked with Static library
if ("${ENABLE_STATIC_LIB}" STREQUAL 1)
	add_executable(${SMI_TOOL_STATIC} "tools/e_smi_tool.c")
		target_link_libraries(${SMI_TOOL_STATIC} ${E_SMI_STATIC})
	set_target_properties(${SMI_TOOL_STATIC} PROPERTIES OUTPUT_NAME "${REAL_NAME}_static")
endif ()

add_library(${E_SMI_LIB} SHARED ${SMI_SRC_LIST} ${SMI_INC_LIST})
target_link_libraries(${E_SMI_LIB} pthread rt m)

## Set the VERSION and SOVERSION values
set_property(TARGET ${E_SMI_LIB} PROPERTY
                SOVERSION "${VERSION_MAJOR}")
set_property(TARGET ${E_SMI_LIB} PROPERTY
                VERSION "${SO_VERSION_STRING}")

## If the library to be build as a Static
if ("${ENABLE_STATIC_LIB}" STREQUAL 1)
    add_library(${E_SMI_STATIC} STATIC ${SMI_SRC_LIST} ${SMI_INC_LIST})
    target_link_libraries(${E_SMI_STATIC} pthread rt m)
	set_target_properties(${E_SMI_STATIC} PROPERTIES OUTPUT_NAME ${E_SMI_LIB})
    install(TARGETS ${E_SMI_STATIC}
          ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT ${E_SMI_COMPONENT})
endif ()

## Add the install directives for the runtime library.
get_target_property(PROG_NAME ${SMI_TOOL} OUTPUT_NAME)
get_target_property(PROG_NAME_STATIC ${SMI_TOOL_STATIC} OUTPUT_NAME)
install(TARGETS ${E_SMI_LIB}
          LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT ${E_SMI_COMPONENT})
install(FILES ${SOURCE_DIR}/include/e_smi/e_smi.h TYPE INCLUDE
	RENAME "${E_SMI_LIB}.h")
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/${PROG_NAME} TYPE BIN)
if ("${ENABLE_STATIC_LIB}" STREQUAL 1)
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/${PROG_NAME_STATIC} TYPE BIN)
endif()

# Generate Doxygen documentation
find_package(Doxygen)
if (DOXYGEN_FOUND)
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/docs/esmi_doxygen.cfg
			${CMAKE_CURRENT_BINARY_DIR}/Doxyfile @ONLY)

  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/latex/refman.tex
       COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
       DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/docs/esmi_doxygen.cfg
       WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/latex/refman.pdf
       COMMAND make  > /dev/null
       COMMAND cp  ${CMAKE_CURRENT_BINARY_DIR}/latex/refman.pdf
              ${CMAKE_CURRENT_SOURCE_DIR}/ESMI_Manual.pdf
       DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/latex/refman.tex
       WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/latex)

  # To create directory "rel" to contain seprate latex, html, etc.
  set(folder "rel")
  add_custom_command(OUTPUT ${folder}
	COMMAND mkdir ${folder}
  )
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/docs/release_notes_doxygen.cfg
                        ${CMAKE_CURRENT_BINARY_DIR}/rel/Doxyfile @ONLY)
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/rel/latex/refman.tex
        COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/rel/Doxyfile
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/docs/release_notes_doxygen.cfg
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/rel)
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/rel/latex/refman.pdf
        COMMAND make  > /dev/null
        COMMAND cp  ${CMAKE_CURRENT_BINARY_DIR}/rel/latex/refman.pdf
                ${CMAKE_CURRENT_SOURCE_DIR}/ESMI_IB_Release_Notes.pdf
        DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/rel/latex/refman.tex
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/rel/latex)

  add_custom_target(doc DEPENDS ${folder} ${CMAKE_CURRENT_BINARY_DIR}/latex/refman.pdf
			${CMAKE_CURRENT_BINARY_DIR}/rel/latex/refman.pdf)

else()
  message("Doxygen is not found. Will not generate documents.")
endif(DOXYGEN_FOUND)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/ESMI_Manual.pdf TYPE DOC
	RENAME "manual.pdf")
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/docs/README.md TYPE DOC
	RENAME "README.md")
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/docs/RELEASENOTES.md TYPE DOC
	RENAME "release-notes.md")

# Install license file with documentation
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/COPYING TYPE DOC
	RENAME "copyright")

# General package specific variables
set(CPACK_GENERATOR "DEB;RPM"  CACHE STRING "Default packaging generators.")
set(CPACK_PACKAGE_NAME ${E_SMI_PACKAGE})
set(CPACK_PACKAGE_VERSION ${PKG_VERSION_STR})
set(CPACK_PROJECT_CONFIG_FILE ${CMAKE_SOURCE_DIR}/package.txt)

# Package metadata: point CPack to the license file and set RPM License field
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/COPYING")
set(CPACK_RPM_PACKAGE_LICENSE "NCSA")

# DEB package specific variables
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
set(CPACK_DEBIAN_PACKAGE_NAME  ${E_SMI_PACKAGE})
set(CPACK_DEBIAN_PACKAGE_VERSION ${PKG_VERSION_STR})

# RPM package specific variables
set(CPACK_RPM_PACKAGE_ARCHITECTURE "x86_64")
set(CPACK_RPM_PACKAGE_AUTOREQ "no")
set(CPACK_RPM_PACKAGE_NAME  ${E_SMI_PACKAGE})
set(CPACK_RPM_PACKAGE_VERSION ${PKG_VERSION_STR})

include (CPack)

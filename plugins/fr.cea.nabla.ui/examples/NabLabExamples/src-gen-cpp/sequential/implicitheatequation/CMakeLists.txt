### GENERATED FILE - DO NOT OVERWRITE ###

cmake_minimum_required(VERSION 3.10)
set(CMAKE_VERBOSE_MAKEFILE FALSE)

# SET VARIABLES
set(CMAKE_CXX_COMPILER /usr/bin/g++ CACHE STRING "")
set(N_WS_PATH /ccc/dsku/nfs-server/temp_user/cont001/ocre/martinm/WORKSPACE_NABLAB/runtime-EclipseApplication)
set(LINEARALGEBRASTL_PATH ${N_WS_PATH}/.nablab/linearalgebra/linearalgebrastl)

# CHECK VARIABLES
if (NOT DEFINED N_WS_PATH)
	message(FATAL_ERROR "N_WS_PATH variable must be set")
endif()

# PROJECT, don't specify language to set CXX and C
project(ImplicitHeatEquationProject)

# CHECK CXX VERSION: must be done after the project() (CMAKE_CXX_COMPILER_ID not defined before)
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
	if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "9.1.0")
		message(FATAL_ERROR "GCC minimum required version is 9.1.0. Please upgrade.")
	endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
	if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "9.0.0")
		message(FATAL_ERROR "Clang minimum required version is 9.0.0. Please upgrade.")
	endif()
endif()

# SUB_DIRECTORIES
if(NOT TARGET nablalib)
	add_subdirectory(${N_WS_PATH}/.nablab/nablalib ${CMAKE_BINARY_DIR}/nablalib)
endif()
if(NOT TARGET linearalgebrastl)
	add_subdirectory(${LINEARALGEBRASTL_PATH} ${CMAKE_BINARY_DIR}/linearalgebrastl)
endif()

# EXECUTABLE implicitheatequation
add_executable(implicitheatequation ImplicitHeatEquation.cc)
target_link_libraries(implicitheatequation PUBLIC nablalib linearalgebrastl)

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
	target_compile_options(implicitheatequation PRIVATE -fdiagnostics-color=always)
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
	target_compile_options(implicitheatequation PRIVATE -fcolor-diagnostics)
endif()

# OPTIONAL USER OPTIONS IN Project.cmake
if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/Project.cmake)
	include(${CMAKE_CURRENT_SOURCE_DIR}/Project.cmake)
endif()

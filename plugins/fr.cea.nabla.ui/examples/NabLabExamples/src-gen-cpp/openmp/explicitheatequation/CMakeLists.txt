### GENERATED FILE - DO NOT OVERWRITE ###

cmake_minimum_required(VERSION 3.10)
set(CMAKE_VERBOSE_MAKEFILE FALSE)

# SET VARIABLES
set(CMAKE_CXX_COMPILER /usr/bin/g++ CACHE STRING "")
set(N_WS_PATH /ccc/dsku/nfs-server/temp_user/cont001/ocre/martinm/WORKSPACE_NABLAB/runtime-EclipseApplication)

# CHECK VARIABLES
if (NOT DEFINED N_WS_PATH)
	message(FATAL_ERROR "N_WS_PATH variable must be set")
endif()

# PROJECT, don't specify language to set CXX and C
project(ExplicitHeatEquationProject)

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

# FIND PACKAGES
find_package(OpenMP REQUIRED)
set(CMAKE_FIND_ROOT_PATH $ENV{HOME}/leveldb/leveldb-install)
find_package(leveldb REQUIRED)
find_package(Threads REQUIRED)

# SUB_DIRECTORIES
if(NOT TARGET nablalib)
	add_subdirectory(${N_WS_PATH}/.nablab/nablalib ${CMAKE_BINARY_DIR}/nablalib)
endif()

# EXECUTABLE explicitheatequation
add_executable(explicitheatequation ExplicitHeatEquation.cc)
target_link_libraries(explicitheatequation PUBLIC nablalib OpenMP::OpenMP_CXX leveldb::leveldb Threads::Threads)

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
	target_compile_options(explicitheatequation PRIVATE -fdiagnostics-color=always)
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
	target_compile_options(explicitheatequation PRIVATE -fcolor-diagnostics)
endif()

# OPTIONAL USER OPTIONS IN Project.cmake
if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/Project.cmake)
	include(${CMAKE_CURRENT_SOURCE_DIR}/Project.cmake)
endif()

###############################################################################
# Copyright (c) 2020 CEA
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# SPDX-License-Identifier: EPL-2.0
# Contributors: see AUTHORS file
###############################################################################

# This file is in a cmake sub_directory and is called by a root CMakeLists.txt

# LIBRARY nablalib
find_package(OpenMP REQUIRED)
add_subdirectory(metis-5.1.0 ${CMAKE_BINARY_DIR}/metis-5.1.0)
add_library(nablalib
    nablalib/mesh/CartesianMesh2D.cc nablalib/mesh/CartesianMesh2DFactory.cc nablalib/mesh/PvdFileWriter2D.cc
    nablalib/types/MultiArray.cc
    nablalib/utils/Timer.cc nablalib/utils/Utils.cc)
add_library(pnm
    nablalib/utils/pnm/pnm.c)
set_property(TARGET nablalib PROPERTY POSITION_INDEPENDENT_CODE ON)
set_property(TARGET pnm PROPERTY POSITION_INDEPENDENT_CODE ON)
target_link_libraries(nablalib PUBLIC metis)
target_link_libraries(nablalib PUBLIC pnm)
target_link_libraries(nablalib PUBLIC OpenMP::OpenMP_CXX)
target_compile_options(nablalib PUBLIC -g -Wall -Wno-missing-braces -O3 --std=c++17 -mtune=native)
target_compile_options(pnm PRIVATE -g -Wall -Wno-missing-braces -O3 --std=c17 -mtune=native)
target_include_directories(nablalib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(pnm PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
# no need since clang++ 9.0 and g++ 9.1
#target_link_libraries(nablalib PUBLIC stdc++fs)

# OPTIONAL USER OPTIONS IN Project.cmake
if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/Project.cmake)
	include(${CMAKE_CURRENT_SOURCE_DIR}/Project.cmake)
endif()

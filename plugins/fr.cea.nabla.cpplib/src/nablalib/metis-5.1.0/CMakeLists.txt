set(GKLIB_PATH "${CMAKE_CURRENT_SOURCE_DIR}/GKlib" CACHE PATH "path to GKlib")

include(${GKLIB_PATH}/GKlibSystem.cmake)

# Add include directories.
include_directories(${GKLIB_PATH})
include_directories(include)
include_directories(libmetis)

file(GLOB metis_sources libmetis/*.c)
add_library(metis STATIC ${GKlib_sources} ${metis_sources})
set_property(TARGET metis PROPERTY POSITION_INDEPENDENT_CODE ON)
target_compile_options(metis PUBLIC -g -Wall -O3 -mtune=native)
target_link_libraries(metis m)

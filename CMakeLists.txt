cmake_minimum_required(VERSION 3.0)
project(libcrc LANGUAGES C)
set(CMAKE_PROJECT_VERSION 2.1)

include(GNUInstallDirs)

if(WIN32 AND (MSYS OR MINGW))
	set(CMAKE_INSTALL_PREFIX /usr)
endif()

set(SOURCE_FILES
	src/crcccitt32.c
	src/crcccitt.c
	src/crc8.c
	src/crc16.c
	src/crc32.c
	src/crc64.c
	src/crcsick.c
	src/crckrmit.c
	src/crcdnp.c
	src/nmea-chk.c
)

set(INCLUDE_FILES
	include/libcrc/checksum.h
)

set(EXAMPLE_SOURCE_FILES
	examples/tstcrc.c
)

set(PRECALC_SOURCE_FILES
	precalc/crc32_table.c
	precalc/crc64_table.c
	precalc/precalc.c
)

# libcrc library
add_library( crc SHARED ${SOURCE_FILES} ${INCLUDE_FILES})
target_include_directories(crc PUBLIC
			$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
			$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/libcrc>
			)
set_target_properties(crc PROPERTIES PUBLIC_HEADER ${INCLUDE_FILES})

# prc executable
add_executable( prc ${PRECALC_SOURCE_FILES} ${INCLUDE_FILES})
target_link_libraries( prc PRIVATE crc )

# tstsrc example
add_executable( tstsrc ${EXAMPLE_SOURCE_FILES} ${INCLUDE_FILES})
target_link_libraries( tstsrc PRIVATE crc )
add_test(tstsrc tstsrc)

install(TARGETS crc tstsrc prc
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
	ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
	PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/libcrc
	)





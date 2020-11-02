cmake_minimum_required(VERSION 3.0)
project(libcrc LANGUAGES C)

set(PROJECT_VERSION 2.1)
set(PROJECT_DESCRIPTION Multi platform MIT licensed CRC library in C)

include(GNUInstallDirs)

if(WIN32 AND (MSYS OR MINGW))
	execute_process(COMMAND cygpath -ma /usr OUTPUT_VARIABLE CMAKE_INSTALL_PREFIX)
	string(STRIP ${CMAKE_INSTALL_PREFIX} CMAKE_INSTALL_PREFIX)
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

set(TAB_FILES
        tab/gentab32.inc
        tab/gentab64.inc
)

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
	${TAB_FILES}
)

set(INCLUDE_FILES
	include/libcrc/checksum.h
)

set(TAB32_FILES
	tab/gentab32.inc
   )
set(TAB64_FILES
	tab/gentab64.inc
   )

set(EXAMPLE_SOURCE_FILES
	examples/tstcrc.c
)

set(PRECALC_SOURCE_FILES
	precalc/crc32_table.c
	precalc/crc64_table.c
	precalc/precalc.c
	precalc/precalc.h
)

# prc executable
add_executable( prc ${PRECALC_SOURCE_FILES} )
target_include_directories(prc PUBLIC
			$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
			$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/precalc>
			$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}>
			)
add_custom_command( OUTPUT ${TAB32_FILES} COMMAND prc --crc32 ${TAB32_FILES} DEPENDS prc ) 
add_custom_command( OUTPUT ${TAB64_FILES} COMMAND prc --crc64 ${TAB64_FILES} DEPENDS prc )

# libcrc library
add_library( crc SHARED ${SOURCE_FILES} ${INCLUDE_FILES} ${TAB_FILES} )
target_include_directories(crc PUBLIC
			$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
			$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}>
			)
set_target_properties(crc PROPERTIES PUBLIC_HEADER ${INCLUDE_FILES} ) 

# tstsrc example
add_executable( tstsrc ${EXAMPLE_SOURCE_FILES} ${INCLUDE_FILES} )
target_link_libraries( tstsrc PRIVATE crc )
add_test(tstsrc tstsrc)

set(install_prefix "${CMAKE_INSTALL_PREFIX}")
configure_file(libcrc.pc.in ${PROJECT_BINARY_DIR}/${PROJECT_NAME}.pc @ONLY)

set(ENV{PKG_CONFIG_PATH} "${PROJECT_BINARY_DIR}:$ENV{PKG_CONFIG_PATH}")

install(TARGETS prc crc tstsrc EXPORT ${PROJECT_NAME}Config
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
	ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
	PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
	)

install(FILES ${PROJECT_NAME}.pc DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig/)

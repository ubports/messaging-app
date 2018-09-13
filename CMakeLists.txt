project(messaging-app)
cmake_minimum_required(VERSION 2.8)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

option(ENABLE_TESTS "Build test programs" ON)

# Standard install paths
include(GNUInstallDirs)

find_program(INTLTOOL_MERGE intltool-merge)
find_program(INTLTOOL_EXTRACT intltool-extract)

# Check for include files
include(CheckIncludeFileCXX)
include(CheckIncludeFile)

include(EnableCoverageReport)
#####################################################################
# Enable code coverage calculation with gcov/gcovr/lcov
# Usage:
#  * Switch build type to coverage (use ccmake or cmake-gui)
#  * Invoke make, make test, make coverage
#  * Find html report in subdir coveragereport
#  * Find xml report feasible for jenkins in coverage.xml
#####################################################################
IF(CMAKE_BUILD_TYPE MATCHES [cC][oO][vV][eE][rR][aA][gG][eE])
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ftest-coverage -fprofile-arcs" )
  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ftest-coverage -fprofile-arcs" )
  SET(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -coverage" )
  SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -coverage" )
  ENABLE_COVERAGE_REPORT(TARGETS ${MESSAGING_APP})
ENDIF(CMAKE_BUILD_TYPE MATCHES [cC][oO][vV][eE][rR][aA][gG][eE])
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DQT_QML_DEBUG")

set(MESSAGING_APP_DIR ${CMAKE_INSTALL_DATADIR}/messaging-app)

# Instruct CMake to run moc automatically when needed.
set(CMAKE_AUTOMOC ON)

find_package(Qt5DBus)
find_package(Qt5Qml)
find_package(Qt5Quick)
find_package(Qt5Test)
find_package(Qt5Versit)

include(qt5)

find_package(PkgConfig REQUIRED)
pkg_check_modules(NOTIFY REQUIRED libnotify)

#find unity8 qml libraries
set(UNITY8_QML_PATH /usr/lib/${CMAKE_C_LIBRARY_ARCHITECTURE}/unity8/qml/)
find_path(LIB_UNITY_QML_EXISTS  NAMES libUnity-qml.so
    HINTS "${UNITY8_QML_PATH}"
    NO_CMAKE_PATH
    NO_CMAKE_ENVIRONMENT_PATH
    NO_SYSTEM_ENVIRONMENT_PATH
)
if(!LIB_UNITY_QML_EXISTS)
    MESSAGE(FATAL_ERROR "unity8 private package not-found")
endif()

add_definitions(-DQT_NO_KEYWORDS)

configure_file(config.h.in ${CMAKE_CURRENT_BINARY_DIR}/config.h @ONLY)

include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
    )

enable_testing()

add_subdirectory(po)
add_subdirectory(src)
add_subdirectory(accounts)
if (ENABLE_TESTS AND NOT ("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "aarch64") AND (NOT ("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "ppc64el")) AND (NOT ("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "ppc64le")))
    add_subdirectory(tests)
endif()

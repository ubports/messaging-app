find_package(Qt5Core REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Network REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5QuickTest REQUIRED)
find_package(Qt5Sql REQUIRED)

set(XVFB_COMMAND)
find_program(XVFBRUN xvfb-run)
if(XVFBRUN)
  set(XVFB_COMMAND ${XVFBRUN} -s "-screen 0 1024x768x24" -a)
else()
  message(WARNING "Cannot find xvfb-run.")
endif()

set(TEST tst_QmlTests)
set(SOURCES
    ${messaging-app_SOURCE_DIR}/src/stickers-history-model.cpp
    tst_QmlTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(
    ${messaging-app_SOURCE_DIR}/src/
)
target_link_libraries(${TEST}
    Qt5::Core
    Qt5::Gui
    Qt5::Network
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickTest
    Qt5::Sql
)
add_test(${TEST} ${XVFB_COMMAND} ${CMAKE_CURRENT_BINARY_DIR}/${TEST}
         -input ${CMAKE_CURRENT_SOURCE_DIR}
         -import ${CMAKE_BINARY_DIR}/src)

# make qml files visible in QtCreator
file(GLOB_RECURSE NON_COMPILED_FILES *.qml)
add_custom_target(NON_COMPILED_TARGET ALL SOURCES ${NON_COMPILED_FILES})

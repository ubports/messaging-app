find_package(Qt5Core REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5QuickTest REQUIRED)

set(XVFB_COMMAND)

find_program(XVFB_RUN_BIN
    NAMES xvfb-run
)

if(XVFB_RUN_BIN)
    set(XVFB_COMMAND ${XVFB_RUN_BIN} -s "-screen 0 1024x768x24" -a)
else()
    message(WARNING "Qml tests disabled: xvfb-run not found")
endif()

set(TEST tst_QmlTests)

set(SOURCES
    ${messaging-app_SOURCE_DIR}/src/fileoperations.cpp
    tst_QmlTests.cpp
)

add_executable(${TEST} ${SOURCES})

include_directories(
    ${messaging-app_SOURCE_DIR}/src
)

target_link_libraries(${TEST}
    Qt5::Core
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickTest
)

add_test(${TEST} ${XVFB_COMMAND} ${CMAKE_CURRENT_BINARY_DIR}/${TEST}
         -input ${CMAKE_CURRENT_SOURCE_DIR}
         -import ${CMAKE_BINARY_DIR}/src)

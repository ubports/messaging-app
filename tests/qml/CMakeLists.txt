find_package(Qt5Core REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5QuickTest REQUIRED)
find_package(Qt5Sql REQUIRED)

set(TEST tst_QmlTests)

set(XVFB_COMMAND)

find_program(XVFB_RUN_BIN
    NAMES xvfb-run
)

if(XVFB_RUN_BIN)
    set(XVFB_COMMAND ${XVFB_RUN_BIN} -s "-screen 0 1024x768x24" -a)
else()
    message(WARNING "Qml tests disabled: xvfb-run not found")
endif()

set(SOURCES
    ${messaging-app_SOURCE_DIR}/src/audiorecorder.cpp
    ${messaging-app_SOURCE_DIR}/src/fileoperations.cpp
    ${messaging-app_SOURCE_DIR}/src/stickers-history-model.cpp
    ${messaging-app_SOURCE_DIR}/src/stickers-pack-model.cpp
    tst_QmlTests.cpp
)

add_executable(${TEST} ${SOURCES})
qt5_use_modules(${TEST} Core Multimedia Qml Quick QuickTest Sql)

set(TEST_COMMAND ${XVFB_COMMAND} ${CMAKE_CURRENT_BINARY_DIR}/${TEST}
                 -import ${CMAKE_BINARY_DIR}/src
                 -import ${UNITY8_QML_PATH})

include_directories(
    ${messaging-app_SOURCE_DIR}/src
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# FIXME: fix the test and re-enable
#add_test(DualSim ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_DualSim.qml)
add_test(SingleSim ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_SingleSim.qml)
set_tests_properties(SingleSim PROPERTIES ENVIRONMENT "HOME=/tmp/tests-singlesim")
add_test(MessageBubble ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_MessageBubble.qml)
add_test(MessagesView ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_MessagesView.qml)
set_tests_properties(MessagesView PROPERTIES ENVIRONMENT "HOME=/tmp/tests-messagesview")
add_test(AttachmentsDelegate ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_AttachmentsDelegate.qml)
add_test(StickersHistoryModel ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_StickersHistoryModel.qml)
add_test(StickersPackModel ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_StickersPackModel.qml)

# make qml files visible in QtCreator
file(GLOB_RECURSE NON_COMPILED_FILES *.qml)
add_custom_target(NON_COMPILED_TARGET ALL SOURCES ${NON_COMPILED_FILES})

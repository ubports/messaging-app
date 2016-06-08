find_package(Qt5Core REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5QuickTest REQUIRED)
find_package(Qt5Sql REQUIRED)

set(TEST tst_QmlTests)

set(SOURCES
    ${messaging-app_SOURCE_DIR}/src/audiorecorder.cpp
    ${messaging-app_SOURCE_DIR}/src/fileoperations.cpp
    ${messaging-app_SOURCE_DIR}/src/stickers-history-model.cpp
    tst_QmlTests.cpp
)

add_executable(${TEST} ${SOURCES})
qt5_use_modules(${TEST} Core Multimedia Qml Quick QuickTest Sql)

set(TEST_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/${TEST}
                 -import ${CMAKE_BINARY_DIR}/src
                 -import ${UNITY8_QML_PATH}
                 -platform offscreen)

include_directories(
    ${messaging-app_SOURCE_DIR}/src
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
)

add_test(DualSim ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_DualSim.qml)
add_test(SingleSim ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_SingleSim.qml)
add_test(MessageBubble ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_MessageBubble.qml)
add_test(MessagesView ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_MessagesView.qml)
add_test(MMSDelegate ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_MMSDelegate.qml)
add_test(StickersHistoryModel ${TEST_COMMAND} -input ${CMAKE_CURRENT_SOURCE_DIR}/tst_StickersHistoryModel.qml)

# make qml files visible in QtCreator
file(GLOB_RECURSE NON_COMPILED_FILES *.qml)
add_custom_target(NON_COMPILED_TARGET ALL SOURCES ${NON_COMPILED_FILES})

find_program(QMLTESTRUNNER_BIN
    NAMES qmltestrunner
    PATHS /usr/lib/*/qt5/bin
    NO_DEFAULT_PATH
)

find_program(XVFB_RUN_BIN
    NAMES xvfb-run
)

macro(DECLARE_QML_TEST TST_NAME TST_QML_FILE)
    add_test(NAME ${TST_NAME}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMAND ${XVFB_RUN_BIN} -a -s "-screen 0 1024x768x24" ${QMLTESTRUNNER_BIN} -import ${qml_BINARY_DIR} -input ${CMAKE_CURRENT_SOURCE_DIR}/${TST_QML_FILE}
    )
endmacro()

if(QMLTESTRUNNER_BIN AND XVFB_RUN_BIN)
    declare_qml_test("message_bubble" tst_MessageBubble.qml)
else()
    if (NOT QMLTESTRUNNER_BIN)
        message(WARNING "Qml tests disabled: qmltestrunner not found")
    else()
        message(WARNING "Qml tests disabled: xvfb-run not found")
    endif()
endif()

set(QML_TST_FILES
    tst_MessageBubble.qml
)
add_custom_target(tst_QmlFiles ALL SOURCES ${QML_TST_FILES})

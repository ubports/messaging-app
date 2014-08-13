file(GLOB DIALOGS_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(messaging_dialogs_QMlFiles ALL SOURCES ${DIALOGS_QML_JS_FILES})

install(FILES ${DIALOGS_QML_JS_FILES} DESTINATION ${MESSAGING_APP_DIR}/Dialogs)


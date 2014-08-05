file(GLOB MMS_QML_JS_FILES *.qml *.js)

add_custom_target(messaging_app_MMS_QMlFiles ALL SOURCES ${MMS_QML_JS_FILES})
install(FILES ${MMS_QML_JS_FILES} DESTINATION ${MESSAGING_APP_DIR}/MMS)

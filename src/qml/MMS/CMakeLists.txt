file(GLOB QML_JS_FILES *.qml *.js)

add_custom_target(messaging_app_MMS_QMlFiles ALL SOURCES ${QML_JS_FILES})


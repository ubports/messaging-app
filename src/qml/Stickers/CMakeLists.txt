file(GLOB STICKERS_QML_FILES *.qml)

add_custom_target(messaging_app_Stickers_QMlFiles ALL SOURCES ${STICKERS_QML_FILES})
install(FILES ${STICKERS_QML_FILES} DESTINATION ${MESSAGING_APP_DIR}/Stickers)

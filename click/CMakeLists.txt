# Components PATH
execute_process(
    COMMAND dpkg-architecture -qDEB_HOST_MULTIARCH
    OUTPUT_VARIABLE ARCH_TRIPLET
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
# This command figures out the target architecture for use in the manifest file
execute_process(
    COMMAND dpkg-architecture -qDEB_HOST_ARCH
    OUTPUT_VARIABLE CLICK_ARCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

set(PROJECT_NAME "messaging-app")
set(FULL_PROJECT_NAME "messaging-app.ubports")
set(DATA_DIR /)
set(DESKTOP_FILE_NAME ${PROJECT_NAME}.desktop)

configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json DESTINATION ${DATA_DIR})
install(FILES ${PROJECT_NAME}.apparmor DESTINATION ${DATA_DIR})
install(FILES ${DESKTOP_FILE_NAME} DESTINATION ${DATA_DIR})

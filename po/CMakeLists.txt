project(messaging-app-translations)

# for dh_translations to extract the domain
# (regarding syntax consistency, see http://pad.lv/1181187)
set (GETTEXT_PACKAGE "messaging-app")

include(FindGettext)

set(DOMAIN messaging-app)
set(POT_FILE ${DOMAIN}.pot)
set(DESKTOP_FILE ${DOMAIN}.desktop)
file(GLOB PO_FILES *.po)
file(GLOB_RECURSE I18N_SRCS RELATIVE ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src/*.qml
    ${CMAKE_SOURCE_DIR}/src/*.js
    ${CMAKE_SOURCE_DIR}/src/*.cpp
)
list(APPEND I18N_SRCS src/${DESKTOP_FILE}.in.in)
list(SORT I18N_SRCS)
message("Found ${I18N_SRCS}")

foreach(PO_FILE ${PO_FILES})
    get_filename_component(LANG ${PO_FILE} NAME_WE)
    gettext_process_po_files(${LANG} ALL PO_FILES ${PO_FILE})
    set(INSTALL_DIR ${CMAKE_INSTALL_LOCALEDIR}/${LANG}/LC_MESSAGES)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${LANG}.gmo
            DESTINATION ${INSTALL_DIR}
            RENAME ${DOMAIN}.mo)
endforeach(PO_FILE)

find_program(XGETTEXT_EXECUTABLE xgettext)
if(XGETTEXT_EXECUTABLE)
    add_custom_target(${POT_FILE} ALL
        COMMENT "Generating translation template"
        COMMAND ${INTLTOOL_EXTRACT} --update --type=gettext/ini
                --srcdir=${CMAKE_SOURCE_DIR} src/${DESKTOP_FILE}.in.in
        COMMAND ${XGETTEXT_EXECUTABLE} --c++ --qt --add-comments=TRANSLATORS --keyword=tr --keyword=tr:1,2 -D ${CMAKE_SOURCE_DIR} -s -p ${CMAKE_CURRENT_SOURCE_DIR} -o ${POT_FILE} ${I18N_SRCS}
    )
    foreach(PO_FILE ${PO_FILES})
       add_custom_command(TARGET ${POT_FILE}
            COMMAND ${GETTEXT_MSGMERGE_EXECUTABLE} ${PO_FILE} ${CMAKE_CURRENT_SOURCE_DIR}/${POT_FILE} -o ${PO_FILE}
       )
    endforeach(PO_FILE)
endif()

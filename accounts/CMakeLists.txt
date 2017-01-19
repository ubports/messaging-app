file(GLOB APPLICATION_FILES *.application)
install(FILES ${APPLICATION_FILES} DESTINATION share/accounts/applications/)

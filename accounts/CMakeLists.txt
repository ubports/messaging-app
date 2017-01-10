file(GLOB APPLICATION_FILES *.application)
install(FILES ${APPLICATION_FILES} DESTINATION share/accounts/applications/)

file(GLOB SERVICE_FILES *.service)
install(FILES ${SERVICE_FILES} DESTINATION share/accounts/services/)

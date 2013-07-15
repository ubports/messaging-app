set(AUTOPILOT_DIR autopilot/messaging_app)
set(CONNECTED_AUTOPILOT_DIR autopilot/connected_tests)

execute_process(COMMAND python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()"
    OUTPUT_VARIABLE PYTHON_PACKAGE_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)

install(DIRECTORY ${AUTOPILOT_DIR}
    DESTINATION ${PYTHON_PACKAGE_DIR}
    )

install(DIRECTORY ${CONNECTED_AUTOPILOT_DIR}
    DESTINATION ${PYTHON_PACKAGE_DIR}
    )

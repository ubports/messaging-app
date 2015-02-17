add_subdirectory(qml)

set(AUTOPILOT_DIR autopilot/messaging_app)

file(GLOB AUTOPILOT_PY_FILES ${AUTOPILOT_DIR}/*.py ${AUTOPILOT_DIR}/tests/*.py)

# custom target to get autopilot files visible on QtCreator
add_custom_target(messaging_app_AUTOPILOT_PY_FILES ALL SOURCES ${AUTOPILOT_PY_FILES})

execute_process(COMMAND python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"
    OUTPUT_VARIABLE PYTHON_PACKAGE_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)

install(DIRECTORY ${AUTOPILOT_DIR}
    DESTINATION ${PYTHON_PACKAGE_DIR}
    )

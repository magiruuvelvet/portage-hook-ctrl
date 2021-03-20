# unit testing framework
CreateTargetFromPath(libtests-undead "dunit/undead/src" STATIC "libtests-undead" D 2)
CreateTargetFromPath(libtests-dunit "dunit/dunit/src" STATIC "libtests-dunit" D 2)
target_link_libraries(libtests-dunit PUBLIC libs::libtests-undead)

# unit tests
CreateTargetFromPath(tests "tests" EXECUTABLE "tests" D 2)
target_link_libraries(tests PRIVATE libs::libtests-dunit libs::libportage-hook-ctrl)
d_install_injectors(tests)

# configure unit test variables
set(TESTS_ASSET_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/assets/")
ProjectConfigureFile(tests "tests/config.d")

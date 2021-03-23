CreateTarget(app EXECUTABLE "portage-hook-ctrl" D 2)
d_install_injectors(app)

target_link_libraries(app PRIVATE
    libs::libportage-hook-ctrl
    libs::argparse
)

set(APPLICATION_VERSION "0.3" CACHE STRING "")
set(PORTAGE_HOOK_DIR "/etc/portage/hooks" CACHE STRING "Directory where to look for hooks.")

ProjectConfigureFile(app "config.d")

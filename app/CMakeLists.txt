CreateTarget(app EXECUTABLE "portage-hook-ctrl" D 2)

target_link_libraries(app PRIVATE libs::libportage-hook-ctrl)

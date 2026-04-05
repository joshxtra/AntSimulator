# Called as a CMake script: cmake -P embed_dylibs.cmake
# Arguments passed via -D:
#   BUNDLE_DIR       - path to MyApp.app
#   EXE_PATH         - path to the executable inside the bundle
#   SFML_GRAPHICS    - path to sfml-graphics dylib
#   SFML_WINDOW      - path to sfml-window dylib
#   SFML_SYSTEM      - path to sfml-system dylib

set(FRAMEWORKS_DIR "${BUNDLE_DIR}/Contents/Frameworks")
file(MAKE_DIRECTORY "${FRAMEWORKS_DIR}")

# Copy a dylib (dereferencing symlinks) and fix its install names.
# Also returns any non-system dependencies it has for recursive processing.
function(embed_dylib lib_path)
    get_filename_component(lib_name "${lib_path}" NAME)

    # Resolve the real file path through symlinks
    execute_process(COMMAND readlink -f "${lib_path}" OUTPUT_VARIABLE real_path OUTPUT_STRIP_TRAILING_WHITESPACE)
    get_filename_component(real_name "${real_path}" NAME)

    # Copy the real file
    if(NOT EXISTS "${FRAMEWORKS_DIR}/${real_name}")
        execute_process(COMMAND cp -f "${real_path}" "${FRAMEWORKS_DIR}/${real_name}")
        execute_process(COMMAND chmod 644 "${FRAMEWORKS_DIR}/${real_name}")
        message(STATUS "Copied: ${real_name}")
    endif()

    # Symlink the install name -> real file if different
    if(NOT "${lib_name}" STREQUAL "${real_name}")
        if(NOT EXISTS "${FRAMEWORKS_DIR}/${lib_name}")
            execute_process(COMMAND ln -sf "${real_name}" "${FRAMEWORKS_DIR}/${lib_name}")
            message(STATUS "Symlinked: ${lib_name} -> ${real_name}")
        endif()
    endif()

    set(dest "${FRAMEWORKS_DIR}/${real_name}")

    # Fix the dylib's own install name (LC_ID_DYLIB)
    execute_process(COMMAND install_name_tool -id "@rpath/${lib_name}" "${dest}")

    # Fix all non-system dependencies recorded in this dylib
    execute_process(COMMAND otool -L "${dest}" OUTPUT_VARIABLE otool_out)
    string(REPLACE "\n" ";" otool_lines "${otool_out}")
    foreach(line IN LISTS otool_lines)
        string(STRIP "${line}" line)
        if(line MATCHES "^(/opt/homebrew[^ ]+\\.dylib)")
            set(dep_path "${CMAKE_MATCH_1}")
            get_filename_component(dep_name "${dep_path}" NAME)
            # Rewrite the load command in this dylib
            execute_process(COMMAND install_name_tool -change "${dep_path}" "@rpath/${dep_name}" "${dest}")
            # Recurse: embed the dependency too
            if(NOT EXISTS "${FRAMEWORKS_DIR}/${dep_name}")
                embed_dylib("${dep_path}")
            endif()
        endif()
    endforeach()
endfunction()

# Embed the three SFML libs (and their transitive Homebrew dependencies)
foreach(lib IN ITEMS "${SFML_GRAPHICS}" "${SFML_WINDOW}" "${SFML_SYSTEM}")
    embed_dylib("${lib}")
endforeach()

# Add rpath to the executable
execute_process(COMMAND install_name_tool -add_rpath "@executable_path/../Frameworks" "${EXE_PATH}")

# Rewrite SFML load commands in the executable itself
execute_process(COMMAND otool -L "${EXE_PATH}" OUTPUT_VARIABLE otool_out)
string(REPLACE "\n" ";" otool_lines "${otool_out}")
foreach(line IN LISTS otool_lines)
    string(STRIP "${line}" line)
    if(line MATCHES "^(/opt/homebrew[^ ]+\\.dylib)")
        set(dep_path "${CMAKE_MATCH_1}")
        get_filename_component(dep_name "${dep_path}" NAME)
        execute_process(COMMAND install_name_tool -change "${dep_path}" "@rpath/${dep_name}" "${EXE_PATH}")
        message(STATUS "Rewrote in exe: ${dep_path} -> @rpath/${dep_name}")
    endif()
endforeach()

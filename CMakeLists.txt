cmake_minimum_required(VERSION 3.10)
project(AntSimulator VERSION 1.0.0 LANGUAGES CXX)

# Default to release builds
if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE Release)
endif()

find_package(SFML 2 REQUIRED COMPONENTS graphics system window)
find_package(Threads REQUIRED)

set(SFML_LIBS sfml-system sfml-window sfml-graphics)

file(GLOB SOURCES src/*.cpp)
add_executable(${PROJECT_NAME} ${WIN32_GUI} ${SOURCES})
target_include_directories(${PROJECT_NAME} PRIVATE "include" "lib")
target_link_libraries(${PROJECT_NAME} ${SFML_LIBS})
set_property(TARGET ${PROJECT_NAME} PROPERTY CXX_STANDARD 17)
if (UNIX)
   target_link_libraries(${PROJECT_NAME} pthread)
endif (UNIX)

if(APPLE)
   # Build as a .app bundle
   set_target_properties(${PROJECT_NAME} PROPERTIES
      MACOSX_BUNDLE TRUE
      MACOSX_BUNDLE_BUNDLE_NAME "AntSimulator"
      MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
      MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
   )

   # Link CoreFoundation for bundle resource path resolution
   target_link_libraries(${PROJECT_NAME} "-framework CoreFoundation")

   # Copy res/ into the bundle's Resources folder at build time
   add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_directory
         ${CMAKE_CURRENT_SOURCE_DIR}/res
         $<TARGET_BUNDLE_CONTENT_DIR:${PROJECT_NAME}>/Resources/res
   )

   # Copy conf.txt into Resources if it exists next to CMakeLists.txt
   if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/conf.txt)
      add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
         COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_CURRENT_SOURCE_DIR}/conf.txt
            $<TARGET_BUNDLE_CONTENT_DIR:${PROJECT_NAME}>/Resources/conf.txt
      )
   endif()

   # Embed SFML dylibs into the bundle and fix their install names
   add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND}
         -DBUNDLE_DIR=$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>
         -DEXE_PATH=$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>/Contents/MacOS/${PROJECT_NAME}
         -DSFML_GRAPHICS=$<TARGET_FILE:sfml-graphics>
         -DSFML_WINDOW=$<TARGET_FILE:sfml-window>
         -DSFML_SYSTEM=$<TARGET_FILE:sfml-system>
         -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/embed_dylibs.cmake
      COMMENT "Embedding SFML dylibs into bundle"
   )
else()
   # Non-Apple: copy res/ next to the executable as before
   file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/res DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
endif()

if(MSVC)
   foreach(lib ${SFML_LIBS})
      get_target_property(lib_path ${lib} LOCATION)
      file(COPY ${lib_path} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
   endforeach()
endif()

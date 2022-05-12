cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX C) # Added C lang

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)
apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
add_dependencies(${BINARY_NAME} flutter_assemble)

## New code for the API library
add_library(api
   SHARED
   ../../libs/api.cpp
   ../../libs/exports.def

   #../../libs/include/dart_api_dl.h
   #../../libs/include/internal/dart_api_dl_impl.h
   ../../libs/include/dart_api_dl.c
   #../../libs/include/dart_api.h
   #../../libs/include/dart_native_api.h
)

# Find headers during the build
target_include_directories(api 
    PRIVATE
    ../../libs/include/
    ../../libs/include/internal/
)

target_link_libraries(api) # link in the dart runtime, otherwise we get unresolved external symbol errors
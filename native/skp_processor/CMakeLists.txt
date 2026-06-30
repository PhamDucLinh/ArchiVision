cmake_minimum_required(VERSION 3.20)

project(skp_processor LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(SKP_PROCESSOR_COPY_SKETCHUP_DLLS "Copy SketchUp SDK runtime libraries next to the executable." ON)

if(NOT DEFINED SKETCHUP_SDK_ROOT)
  if(DEFINED ENV{SKETCHUP_SDK_ROOT})
    set(SKETCHUP_SDK_ROOT "$ENV{SKETCHUP_SDK_ROOT}")
  else()
    message(FATAL_ERROR "Set SKETCHUP_SDK_ROOT to the SketchUp C API SDK directory.")
  endif()
endif()

set(SKETCHUP_SDK_ROOT "${SKETCHUP_SDK_ROOT}" CACHE PATH "SketchUp C API SDK root")

find_path(
  SKETCHUP_INCLUDE_DIR
  NAMES SketchUpAPI/sketchup.h
  PATHS "${SKETCHUP_SDK_ROOT}" "${SKETCHUP_SDK_ROOT}/headers" "${SKETCHUP_SDK_ROOT}/include"
  NO_DEFAULT_PATH
)

if(NOT SKETCHUP_INCLUDE_DIR)
  message(FATAL_ERROR "Could not find SketchUpAPI/sketchup.h under ${SKETCHUP_SDK_ROOT}")
endif()

if(WIN32)
  find_library(
    SKETCHUP_API_LIBRARY
    NAMES SketchUpAPI
    PATHS
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/x64"
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/windows/x64"
      "${SKETCHUP_SDK_ROOT}/lib"
    NO_DEFAULT_PATH
  )
elseif(APPLE)
  find_library(
    SKETCHUP_API_LIBRARY
    NAMES SketchUpAPI
    PATHS
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/macos"
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/macos/universal"
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/mac"
      "${SKETCHUP_SDK_ROOT}/lib"
    NO_DEFAULT_PATH
  )
else()
  message(FATAL_ERROR "This sample supports Windows and macOS.")
endif()

if(NOT SKETCHUP_API_LIBRARY)
  message(FATAL_ERROR "Could not find SketchUpAPI runtime library under ${SKETCHUP_SDK_ROOT}")
endif()

add_executable(skp_processor
  src/main.cpp
  src/sketchup_api_guard.cpp
  src/skp_thumbnail.cpp
  src/skp_render_stub.cpp
)

target_include_directories(skp_processor PRIVATE
  "${SKETCHUP_INCLUDE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
)

target_link_libraries(skp_processor PRIVATE "${SKETCHUP_API_LIBRARY}")

if(APPLE)
  set_target_properties(skp_processor PROPERTIES
    BUILD_RPATH "@executable_path"
    INSTALL_RPATH "@executable_path"
  )
endif()

if(SKP_PROCESSOR_COPY_SKETCHUP_DLLS)
  if(WIN32)
    file(GLOB SKETCHUP_RUNTIME_FILES
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/x64/*.dll"
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/windows/x64/*.dll"
    )
  elseif(APPLE)
    file(GLOB SKETCHUP_RUNTIME_FILES
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/macos/*.dylib"
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/macos/*.framework"
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/macos/universal/*.dylib"
      "${SKETCHUP_SDK_ROOT}/binaries/sketchup/mac/*.dylib"
    )
  endif()

  foreach(runtime_file IN LISTS SKETCHUP_RUNTIME_FILES)
    get_filename_component(runtime_name "${runtime_file}" NAME)
    if(IS_DIRECTORY "${runtime_file}")
      add_custom_command(TARGET skp_processor POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_directory
          "${runtime_file}"
          "$<TARGET_FILE_DIR:skp_processor>/${runtime_name}"
      )
    else()
      add_custom_command(TARGET skp_processor POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
          "${runtime_file}"
          "$<TARGET_FILE_DIR:skp_processor>"
      )
    endif()
  endforeach()
endif()

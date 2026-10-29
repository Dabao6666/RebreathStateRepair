cmake_minimum_required(VERSION 3.21)

# Use the MSVC runtime library selection mechanism.
cmake_policy(SET CMP0091 NEW)

# Match the static MSVC runtime used by x64-windows-static.
# Release: /MT
# Debug:   /MTd
set(CMAKE_MSVC_RUNTIME_LIBRARY
    "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)

project(RebreathStateRepair VERSION 1.0.0 LANGUAGES CXX)

find_package(CommonLibSSE CONFIG REQUIRED)

add_commonlibsse_plugin(${PROJECT_NAME}
    SOURCES
        src/plugin.cpp
)

# Enforce the same runtime library on the plugin target.
set_property(
    TARGET ${PROJECT_NAME}
    PROPERTY MSVC_RUNTIME_LIBRARY
    "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)

# Use C++23.
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_23)

# Enable UTF-8 source and execution character sets.
if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /utf-8)
endif()

# Allow src/plugin.cpp to find headers in the project root.
target_include_directories(${PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
)

# Precompiled header.
target_precompile_headers(${PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/PCH.h"
)

# Optional deployment: set SKYRIM_FOLDER or SKYRIM_MODS_FOLDER before configuring.
if(DEFINED ENV{SKYRIM_FOLDER} AND
   IS_DIRECTORY "$ENV{SKYRIM_FOLDER}/Data")

    set(OUTPUT_FOLDER "$ENV{SKYRIM_FOLDER}/Data")

elseif(DEFINED ENV{SKYRIM_MODS_FOLDER} AND
       IS_DIRECTORY "$ENV{SKYRIM_MODS_FOLDER}")

    set(OUTPUT_FOLDER "$ENV{SKYRIM_MODS_FOLDER}/${PROJECT_NAME}")

endif()

# Copy the compiled DLL to the selected Skyrim or mod folder.
if(DEFINED OUTPUT_FOLDER)
    set(DLL_FOLDER "${OUTPUT_FOLDER}/SKSE/Plugins")

    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E make_directory
            "${DLL_FOLDER}"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "$<TARGET_FILE:${PROJECT_NAME}>"
            "${DLL_FOLDER}/$<TARGET_FILE_NAME:${PROJECT_NAME}>"
        VERBATIM
    )
endif()
#!/usr/bin/env bash
#
# ==================================================
# BUILD SCRIPT — c++23 MODULES (SINGLE-STEP)
# ==================================================
#

set -eou pipefail

BUILD="./build"
mkdir -p "$BUILD"

MOD1="./src/mod1"

# 🔥 REMOVE -fmodules-cache-path when using -fmodule-output
CXXFLAGS=(
	-std=c++23
	-Wall
	-Wextra
	-fprebuilt-module-path="$BUILD" # Where to find .pcm files
)

printf "Compiling modules (generating .o and .pcm in one step)\n\n"

# ---- Compile PRIMARY MODULE INTERFACES first ----

# Build A first (B depends on it)
printf "Compiling A.o and A.pcm\n\n"
clang++ "${CXXFLAGS[@]}" -c "$MOD1/A.cppm" -o "$BUILD/A.o" -fmodule-output

# Now B can find A.pcm in the build directory
printf "Compiling B.o and B.pcm\n\n"
clang++ "${CXXFLAGS[@]}" -c "$MOD1/B.cppm" -o "$BUILD/B.o" -fmodule-output

# For .cxx files: -x c++-module MUST come BEFORE the input file
printf "Compiling C interface\n\n"
clang++ "${CXXFLAGS[@]}" -x c++-module -c "$MOD1/C.cxx" -o "$BUILD/C.o" -fmodule-output

printf "Compiling D interface\n\n"
clang++ "${CXXFLAGS[@]}" -x c++-module -c "$MOD1/D.cxx" -o "$BUILD/D.o" -fmodule-output

# ---- Compile MODULE IMPLEMENTATIONS ----
printf "Compiling C implementation\n\n"
clang++ "${CXXFLAGS[@]}" -c "$MOD1/C.cpp" -o "$BUILD/C_impl.o"

printf "Compiling D implementation\n\n"
clang++ "${CXXFLAGS[@]}" -c "$MOD1/D.cpp" -o "$BUILD/D_impl.o"

# ---- Compile MAIN files ----
printf "Compiling Main.cpp\n\n"
clang++ "${CXXFLAGS[@]}" -c src/Main.cpp -o "$BUILD/Main_cpp.o"

printf "Compiling Main.c\n\n"
clang -std=c23 -c src/Main.c -o "$BUILD/Main.o"

# ---- Linking ----
printf "Linking program\n\n"
clang++ \
	"$BUILD"/Main.o \
	"$BUILD"/Main_cpp.o \
	"$BUILD"/A.o "$BUILD"/B.o \
	"$BUILD"/C_api.o "$BUILD"/C_impl.o \
	"$BUILD"/D_api.o "$BUILD"/D_impl.o \
	-o ./program

# ---- Run ----
printf "Running program\n\n"
./program

echo "✅ Build successful!"

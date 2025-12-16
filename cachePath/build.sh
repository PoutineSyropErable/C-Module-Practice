#!/usr/bin/env bash
#
# ==================================================
# BUILD SCRIPT — C++23 MODULES (SINGLE-STEP)
# ==================================================
#
# Core invariants:
#   -fmodule-output creates .o and .pcm in one step
#   .pcm files are created with same basename as .o files
#   Module implementations find .pcm via -fprebuilt-module-path
#

# --------------------------------------------------
# Output directory
# --------------------------------------------------

set -eou pipefail

BUILD="./build"
mkdir -p "$BUILD"

MOD1="./src/mod1"

CXXFLAGS=(
	-std=c++23
	-Wall
	-Wextra
	-fprebuilt-module-path="$BUILD" # Where to find compiled .pcm files
)

# ==================================================
# PHASE 1 — MODULE INTERFACES → .o + .pcm
# ==================================================
#
# Single-step compilation generates both artifacts.
# .o contains object code for inline/template definitions.
# .pcm contains module interface for imports.
#

printf "Phase 1: Compiling module interfaces (.o + .pcm)\n\n"

# ---- merged module A ----
# A.cppm exports a module and contains all code.
# Generates A.o (object code) and A.pcm (interface).
printf "Compiling module A (merged)\n\n"
clang++ "${CXXFLAGS[@]}" -c "$MOD1/A.cppm" -o "$BUILD/A.o" -fmodule-output

# ---- merged module B ----
# B.cppm imports A, contains all code.
# Finds A.pcm via -fprebuilt-module-path.
printf "Compiling module B (merged)\n\n"
clang++ "${CXXFLAGS[@]}" -c "$MOD1/B.cppm" -o "$BUILD/B.o" -fmodule-output

# ---- split module C (interface only) ----
# -x c++-module marks .cxx as module interface unit.
printf "Compiling module C interface\n\n"
clang++ "${CXXFLAGS[@]}" -x c++-module -c "$MOD1/C.cxx" -o "$BUILD/C.o" -fmodule-output

# ---- split module D (interface only) ----
# -x c++-module marks .cxx as module interface unit.
printf "Compiling module D interface\n\n"
clang++ "${CXXFLAGS[@]}" -x c++-module -c "$MOD1/D.cxx" -o "$BUILD/D.o" -fmodule-output

# ==================================================
# PHASE 2 — MODULE IMPLEMENTATIONS → .o
# ==================================================
#
# Implementation files contain definitions only.
# They import their own module via compiled .pcm.
# No .pcm files are generated here.
#

printf "\nPhase 2: Compiling module implementations (.o only)\n\n"

# ---- split module C implementation ----
# C.cpp implements functions declared in C.cxx.
# Finds C.pcm via -fprebuilt-module-path.

printf "Compiling module C implementation\n\n"
clang++ "${CXXFLAGS[@]}" -c "$MOD1/C.cpp" -o "$BUILD/C_impl.o"

# ---- split module D implementation ----

printf "Compiling module D implementation\n\n"
clang++ "${CXXFLAGS[@]}" -c "$MOD1/D.cpp" -o "$BUILD/D_impl.o"

# ==================================================
# PHASE 3 — CONSUMER FILES → .o
# ==================================================
#
# Regular translation units that import modules.
# Can also include traditional headers.
#

printf "\nPhase 3: Compiling consumer files\n\n"

# ---- C++ consumer (imports modules) ----

printf "Compiling Main.cpp (C++ consumer)\n\n"
clang++ "${CXXFLAGS[@]}" -c src/Main.cpp -o "$BUILD/Main_cpp.o"

# ---- C entry point (no modules) ----

printf "Compiling Main.c (C entry point)\n\n"
clang -std=c23 -c src/Main.c -o "$BUILD/Main.o"

# ==================================================
# PHASE 4 — LINKING
# ==================================================
#
# The linker sees only object files (.o).
# .pcm files are compile-time artifacts only.
#

printf "\nPhase 4: Linking executable\n\n"

clang++ \
	"$BUILD"/Main.o \
	"$BUILD"/Main_cpp.o \
	"$BUILD"/A.o \
	"$BUILD"/B.o \
	"$BUILD"/C.o \
	"$BUILD"/C_impl.o \
	"$BUILD"/D.o \
	"$BUILD"/D_impl.o \
	-o ./program

# ==================================================
# PHASE 5 — EXECUTION
# ==================================================
#

printf "\nPhase 5: Running program\n\n"

./program

printf "\n✅ Build and execution successful!\n"

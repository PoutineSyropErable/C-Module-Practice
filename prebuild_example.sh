#!/bin/bash

# =======================================
# Clang modular C++ build script
# Using cache path approach (split modules)
# =======================================

CXX=clang++
CXXFLAGS="-std=gnu23 -ffreestanding -O0 -ggdb3 -fno-exceptions -fno-rtti"

# Directories
CACHE_DIR=build/ppms
OBJ_DIR=build/objects

mkdir -p "$CACHE_DIR"
mkdir -p "$OBJ_DIR"

# ------------------------------
# Compile main.cpp first
# - main.cpp imports dep
# - Clang auto-generates dep.pcm in cache
# ------------------------------
echo "Compiling main.cpp (may auto-build dep.pcm)..."
$CXX $CXXFLAGS \
	-fmodules-cache-path=$CACHE_DIR \
	-c src/main.cpp \
	-o $OBJ_DIR/main.o

# ------------------------------
# Compile module interface (dep.ixx)
# - Produces dep.pcm in cache (if not already generated)
# - Produces dep.o for linker
# ------------------------------
echo "Compiling dep module interface..."
$CXX $CXXFLAGS \
	-fmodules-cache-path=$CACHE_DIR \
	-c src/mod/dep.ixx \
	-o $OBJ_DIR/dep.o

# ------------------------------
# Compile module implementation (dep.cpp)
# ------------------------------
echo "Compiling dep module implementation..."
$CXX $CXXFLAGS \
	-fmodules-cache-path=$CACHE_DIR \
	-c src/mod/dep.cpp \
	-o $OBJ_DIR/dep_impl.o

# ------------------------------
# Link everything
# ------------------------------
echo "Linking kernel..."
$CXX -ffreestanding -nostdlib \
	$OBJ_DIR/main.o \
	$OBJ_DIR/dep.o \
	$OBJ_DIR/dep_impl.o \
	-o build/kernel.bin \
	-T linker.ld

echo "Build complete!"

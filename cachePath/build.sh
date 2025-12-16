#!/bin/bash

# Set flags
CXX=clang++
CXXFLAGS="-std=gnu++23 -I./src -fmodules-cache-path=build/ppms"

# Create build directories if they don't exist
mkdir -p build/objects
mkdir -p build/ppms

# ---------------------------
# 1. Compile Main.cpp first (shuffled order)
# ---------------------------
# Main.cpp imports Mage, which in turn imports Fireball
# Even though Fireball and Mage have not been compiled yet,
# the compiler will automatically generate Fireball.ppm and Mage.ppm
$CXX $CXXFLAGS -c src/Main.cpp -o build/objects/Main.o

# ---------------------------
# 2. Compile Mage.cppm (shuffled order)
# ---------------------------
# Mage.cppm imports Fireball
# Fireball.ppm may already exist from previous step in cache
$CXX $CXXFLAGS -c src/Mage.cppm -o build/objects/Mage.o

# ---------------------------
# 3. Compile Fireball.cppm (shuffled order)
# ---------------------------
# Fireball is the leaf module
# If Fireball.ppm already exists from step 1, this will be fast / skipped
$CXX $CXXFLAGS -c src/Fireball.cppm -o build/objects/Fireball.o

# ---------------------------
# 4. Link all object files
# ---------------------------
$CXX build/objects/Main.o build/objects/Mage.o build/objects/Fireball.o -o build/mygame

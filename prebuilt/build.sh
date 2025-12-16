#!/usr/bin/env sh
#
# ==================================================
# BUILD SCRIPT — c++23 MODULES (RULE-EXPLICIT)
# ==================================================
#
# Naming rules enforced:
#   .cxx   -> module interface ONLY (API)
#   .cpp   -> module implementation ONLY
#   .cppm  -> merged interface + implementation
#
# Core invariants:
#   - Every module interface produces a .ppm
#   - Every source file that contains code produces a .o
#   - No grouping of modules into a single .o
#   - Linker only consumes .o files
#

# --------------------------------------------------
# Output directories
# --------------------------------------------------

set -eou pipefail

PCM="./build/pcm"
OBJ="./build/obj"

mkdir -p "$PCM"
mkdir -p "$OBJ"

MOD1="./src/mod1"

# ==================================================
# PHASE 1 — MODULE INTERFACES → .pcm
# ==================================================
#
# This phase creates *compile-time only* artifacts.
# No executable code is generated here.
#

# ---- merged module A ----
# A.cppm exports a module and contains code.
# First pass: extract its interface into a .pcm.

printf "Precompiling a.cppm\n\n"
clang++ -std=c++23 \
	--precompile \
	"$MOD1/A.cppm" \
	-o "$PCM/A.pcm"

# ---- merged module B ----

printf "Precompiling b.cppm\n\n"
clang++ -std=c++23 \
	--precompile \
	"$MOD1/B.cppm" \
	-o "$PCM/B.pcm" \
	-fprebuilt-module-path="$PCM" \
	-I"$MOD1"
# -fmodules-cache-path=$pcm

# ---- split module C (API only) ----
# C.cxx contains ONLY `export module C;` and exports.

printf "Precompiling C.cxx \n\n"
clang++ -std=c++23 \
	--precompile \
	-x c++-module \
	"$MOD1/C.cxx" \
	-o "$PCM/C.pcm" \
	-fprebuilt-module-path="$PCM"

# ---- split module D (API only) ----

printf "Precompiling D.cxx \n\n"
clang++ -std=c++23 \
	--precompile \
	-x c++-module \
	"$MOD1/D.cxx" \
	-o "$PCM/D.pcm" \
	-fprebuilt-module-path="$PCM"

# ==================================================
# PHASE 2 — MODULE INTERFACES → .o
# ==================================================
#
# Interfaces are compiled *again* to emit object code.
# This includes inline functions, constants, templates, etc.
#

# ---- merged module A (.cppm → .o) ----

printf "Compiling interface and implementation A.cppm \n\n"
clang++ -std=c++23 \
	-c "$PCM/A.pcm" \
	-o "$OBJ"/A.o

# ---- merged module B ----

printf "Compiling interface and implementation B.cppm \n\n"
clang++ -std=c++23 \
	-c "$PCM/B.pcm" \
	-o "$OBJ"/B.o \
	-fprebuilt-module-path="$PCM"

if true; then
	# ---- split module C API (.pcm → .o) ----

	# This is a clangd specific methods
	printf "Compiling interface C.cpm \n\n"
	clang++ -std=c++23 \
		-c "$PCM/C.pcm" \
		-o "$OBJ"/C_api.o \
		-fprebuilt-module-path="$PCM"

	# ---- split module D API (.pcm → .o) ----
	printf "Compiling interface D.cpm \n\n"
	clang++ -std=c++23 \
		-c "$PCM/D.pcm" \
		-o "$OBJ/D_api.o" \
		-fprebuilt-module-path="$PCM"
else
	# ---- This will work with every compiler.
	# But

	# ---- split module C API (.cxx → .o) ----
	printf "Compiling interface C.cpm \n\n"
	clang++ -std=c++23 \
		-c "$MOD1/C.cxx" \
		-o "$OBJ/C_api.o" \
		-fprebuilt-module-path="$PCM"

	# ---- split module D API (.cxx → .o) ----
	printf "Compiling interface D.cpm \n\n"
	clang++ -std=c++23 \
		-c "$MOD1/D.cxx" \
		-o "$OBJ/D_api.o" \
		-fprebuilt-module-path="$PCM"

fi

# ==================================================
# PHASE 3 — MODULE IMPLEMENTATIONS → .o
# ==================================================
#
# Implementation files never generate .pcm files.
# They consume module interfaces and emit code only.
#

# ---- split module C implementation (.cpp) ----

printf "Compiling implementation C.cpp \n\n"
clang++ -std=c++23 \
	-c "$MOD1"/C.cpp \
	-o "$OBJ"/C_impl.o \
	-fprebuilt-module-path="$PCM"

# ---- split module D implementation ----

printf "Compiling implementation D.cpp \n\n"
clang++ -std=c++23 \
	-c "$MOD1"/D.cpp \
	-o "$OBJ"/D_impl.o \
	-fprebuilt-module-path="$PCM"

# ==================================================
# PHASE 4 — NON-MODULE FILES → .o
# ==================================================
#
# These may import modules, include headers, or both.
#

# ---- C++ TU that may import modules ----

printf "Compiling Main.cpp \n\n"
clang++ -std=c++23 \
	-c src/Main.cpp \
	-fprebuilt-module-path="$PCM" \
	-o "$OBJ"/Main_cpp.o

# ---- C entry point ----

printf "Compiling Main.c \n\n"
clang -c src/Main.c \
	-o "$OBJ"/Main.o

# ==================================================
# PHASE 5 — LINKING
# ==================================================
#
# The linker sees *only* object files.
# Modules no longer exist at this stage.
#

clang++ \
	"$OBJ"/Main.o \
	"$OBJ"/Main_cpp.o \
	"$OBJ"/A.o \
	"$OBJ"/B.o \
	"$OBJ"/C_impl.o \
	"$OBJ"/D_impl.o \
	"$OBJ"/C_api.o \
	"$OBJ"/D_api.o \
	-o build/program

printf -- "\n\n======Start of program========\n\n"

./build/program

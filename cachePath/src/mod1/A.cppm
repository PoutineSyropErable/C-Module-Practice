// src/mod1/A.cppm
module; // Global module fragment for legacy headers

#include <iostream>
#include <string>

export module A; // Module declaration

export void greetA() { std::cout << "Hello from module A!" << std::endl; }

void internalA() { std::cout << "Internal function in A" << std::endl; }

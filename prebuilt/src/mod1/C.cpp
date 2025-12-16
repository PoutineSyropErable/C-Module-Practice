// src/mod1/C.cpp
#include <iostream>
module C;

export void greetC() { std::cout << "Hello from module C!" << std::endl; }

export int add(int a, int b) { return a + b; }

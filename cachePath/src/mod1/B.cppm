// src/mod1/B.cppm
module;

#include <iostream>

export module B;

import A; // B depends on A

export void greetB() {
    greetA();
    std::cout << "Hello from merged module B!" << std::endl;
}

void internalB() { std::cout << "Internal function in B" << std::endl; }

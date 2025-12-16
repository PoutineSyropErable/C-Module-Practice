// src/Main.cpp
// module;
#include "main_cpp.h"
#include <iostream>
#include <print>
// export module MainBridge; // Optional: export a module if you want

import A;
import B;
import C;
import D;

extern "C" int main_cpp() {
    std::print("Start of greet A, {}\n", 1);
    greetA();
    std::print("\nStart of greet B, {}\n", 1.5);
    greetB();
    std::print("\nStart of greet C, {}\n", -1);
    greetC();
    std::print("\nStart of greet D, {}\n", -2.65);
    greetD();
    [[maybe_unused]] int x = FUNNY_NUMBER;

    int c = lolc();
    float d = lol_d();
    std::print("\n C result: {}\n", c);
    std::print("\n D result: {}\n", d);
    return 0;
}

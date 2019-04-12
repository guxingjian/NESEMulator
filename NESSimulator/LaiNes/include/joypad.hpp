#pragma once
#include "common.hpp"

namespace Joypad {


u8 read_state(int n);
void write_strobe(bool v);
void registeJoypadCallback(void* obj, u8 (*callBack)(void* obj, int n));
    
}

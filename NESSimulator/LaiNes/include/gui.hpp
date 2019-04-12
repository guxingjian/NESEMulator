#pragma once
#include "Nes_Apu.h"
#include "common.hpp"

namespace GUI {


const int TEXT_CENTER  = -1;
const int TEXT_RIGHT   = -2;
const unsigned FONT_SZ = 15;
    
u8 get_joypad_state(int n);

}

#pragma once
#include "common.hpp"
#include "Nes_Apu.h"

namespace APU {


template <bool write> u8 access(int elapsed, u16 addr, u8 v = 0);
void run_frame(int elapsed);
void reset();
void init();
void registeSoundCallback(void* obj, void (*callBack)(void* obj, const blip_sample_t* samples, long int count));

}

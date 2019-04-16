#include "common.hpp"

namespace Joypad {

static void* joypad_callback_obj;
static u8 (*joypad_callback_func)(void* obj, int n);
u8 joypad_bits[2];  // Joypad shift registers.
bool strobe;        // Joypad strobe latch.

/* Read joypad state (NES register format) */
u8 read_state(int n)
{
    // When strobe is high, it keeps reading A:
    if (strobe){
        if(joypad_callback_func){
            return 0x40 | (joypad_callback_func(joypad_callback_obj, n) & 1);
        }else{
            return 0x40;
        }
    }
    

    // Get the status of a button and shift the register:
    u8 j = 0x40 | (joypad_bits[n] & 1);
    joypad_bits[n] = 0x80 | (joypad_bits[n] >> 1);
    return j;
}

void write_strobe(bool v)
{
    // Read the joypad data on strobe's transition 1 -> 0.
    if (strobe and !v)
        for (int i = 0; i < 2; i++){
            if(joypad_callback_func){
                joypad_bits[i] = joypad_callback_func(joypad_callback_obj, i);
            }
        }

    strobe = v;
}

void registeJoypadCallback(void* obj, u8 (*callBack)(void* obj, int n)){
    joypad_callback_obj = obj;
    joypad_callback_func = callBack;
}

}

// Copyright (c) 2019, Frank Buss
// All rights reserved.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// YM2151 audio demo

#include <stdint.h>

#include "test.inc"

struct YM2151_t {
    uint8_t data;
    uint8_t reg;
};

#define YM2151 (*(volatile struct YM2151_t*) 0x9fe0)

void wait(uint16_t samples)
{
    uint16_t i;
    for (i = 0; i < samples; i++) {
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
        __asm__("nop");
    }
}

int main(void)
{
    // switch back to uppercase character set
    __asm__("lda #$8e");
    __asm__("jsr BSOUT");
    
    // disable interrupts
    __asm__("sei");

    // bad hack: redefine CC65 stack to $0xa800-0xafff, should be a proper x16 custom target
    *((uint16_t*) 0x02) = 0xb000;
    
    // simple VGM player
    {
        uint16_t i = 0x40;
        uint8_t run = 1;
        while (run) {
            uint8_t cmd = test[i++];
            switch (cmd) {
                case 0x54:
                {
                    YM2151.reg = test[i++];
                    YM2151.data = test[i++];
                    break;
                }
                case 0x61:
                {
                    uint16_t n = test[i++];
                    n += test[i++] << 8;
                    wait(n);
                    break;
                }
                case 0x62:
                {
                    wait(735);
                    break;
                }
                case 0x63:
                {
                    wait(882);
                    break;
                }
                case 0x66:
                {
                    //printf("end\n");
                    run = 0;
                    break;
                }
                default:
                {
                    if (cmd >= 0x70 && cmd <= 0x7f) {
                        wait(cmd & 0xf);
                    } else {
                        //printf("unknown command: %i\n", cmd);
                    }
                    break;
                }
            }
        }
    }
    
	return 0;
}

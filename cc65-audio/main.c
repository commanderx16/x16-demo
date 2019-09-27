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

// YM2151 VGM player

#include <stdint.h>
#include <stdio.h>
#include <conio.h>
#include <6502.h>

#include "vgm.inc"

struct YM2151_t {
    uint8_t reg;
    uint8_t data;
};

#define YM2151 (*(volatile struct YM2151_t*) 0x9fe0)

static uint8_t run;
static uint16_t ofs, start;

static void wait(uint16_t samples)
{
    // assumes 60 Hz VGM files
    uint16_t frames = samples / 735;
    
    while (frames--) waitvsync();
}

static void resetYM2151()
{
    uint16_t i;
    for (i = 0; i < 256; i++) {
        YM2151.reg = i;
        YM2151.data = 0;
    }
}

char* readWideString(uint16_t* pos)
{
    static uint8_t buf[256];
    uint8_t i = 0;
    while (1) {
        uint16_t wc = vgmData[*pos];
        (*pos)++;
        wc |= vgmData[*pos];
        (*pos)++;
        if (wc >= 65 && wc <= 90) {
            wc += 32;
        } else if (wc >= 97 && wc <= 122) {
            wc -= 32;
        }
        buf[i++] = wc;
        if (wc == 0) break;
    }
    return buf;
}

void play()
{
    while (1) {
        ofs = start;
        run = 1;
        while (run) {
            uint8_t cmd = vgmData[ofs++];
            switch (cmd) {
                case 0x54:
                {
                    YM2151.reg = vgmData[ofs++];
                    YM2151.data = vgmData[ofs++];
                    break;
                }
                case 0x61:
                {
                    uint16_t n = vgmData[ofs++];
                    n += vgmData[ofs++] << 8;
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
                    run = 0;
                    break;
                }
                case 0xc0:
                {
                    // ignore Sega PCM write
                    ofs += 3;
                    break;
                }
                default:
                {
                    if (cmd >= 0x70 && cmd <= 0x7f) {
                        wait(cmd & 0xf);
                    } else {
                        printf("unknown command: $%02x\n", cmd);
                    }
                    break;
                }
            }
            if (kbhit()) {
                cgetc();
                return;
            }
        }
    }
}

int main()
{
    uint16_t gd3;
    
    resetYM2151();
    clrscr();
    printf("\nVGM player by Frank Buss\n\n");

    // calculate absolute data offset
    start = vgmData[0x34];
    start |= vgmData[0x35] << 8;
    start += 0x34;
    
    // calculate GD3 offset
    gd3 = vgmData[0x14];
    gd3 |= vgmData[0x15] << 8;
    
    // parse GD3 info
    if (gd3) {
        gd3 += 29;
        readWideString(&gd3);
        printf(" Song title : %s\n", readWideString(&gd3));
        readWideString(&gd3);
        readWideString(&gd3);
        readWideString(&gd3);
        readWideString(&gd3);
        readWideString(&gd3);
        printf(" Author name: %s\n", readWideString(&gd3));
    }
    
    // play song until key press
    printf("\npress any key to stop\n");
    play();
    resetYM2151();

    return 0;
}

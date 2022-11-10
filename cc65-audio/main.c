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

//note: YM2151 struct is defined by cc65 in cx16.h
//since commit a5e69e7.

static uint8_t run;
static uint16_t ofs, start;

static void startWrite()
{
    vpoke(0, 0x01fa0c);
}

static void endWrite()
{
    vpoke(15, 0x01fa0c);
}

static void wait(uint16_t samples)
{
    // assumes 60 Hz VGM files
    uint16_t frames = samples / 735;
    
    while (frames--) waitvsync();
}

static void writeYM2151Reg(uint8_t reg, uint8_t value)
{
    uint8_t i;
    YM2151.reg = reg;
    YM2151.data = value;
    
    // delay between writes must be at least 64 YM2151 cyclces, which is
    // 224 cyckes if tge 6502, if it runs at 14 MHz, and the YM2151 at 4 MHz.
    // The function and call needs about 50 cycles. One loop 22 cycles.
    // Add some reserve in case CC65 optimizes it better in future versions.
    for (i = 0; i < 10; i++) {
        asm("nop");
    }
}

static void resetYM2151()
{
    uint16_t i;
    for (i = 0; i < 256; i++) {
        writeYM2151Reg(i, 0);
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
    return (char*) buf;
}

void play()
{
    while (1) {
        ofs = start;
        run = 1;
        while (run) {
            uint8_t cmd = vgmData[ofs++];
            startWrite();
            switch (cmd) {
                case 0x54:
                {
                    uint8_t reg = vgmData[ofs++];
                    uint8_t value = vgmData[ofs++];
                    writeYM2151Reg(reg, value);
                    break;
                }
                case 0x61:
                {
                    uint16_t n = vgmData[ofs++];
                    n += vgmData[ofs++] << 8;
                    endWrite();
                    wait(n);
                    break;
                }
                case 0x62:
                {
                    endWrite();
                    wait(735);
                    break;
                }
                case 0x63:
                {
                    endWrite();
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
                        endWrite();
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
    endWrite();
    resetYM2151();

    return 0;
}

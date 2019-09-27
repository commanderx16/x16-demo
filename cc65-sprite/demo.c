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


// Demonstrates how to initialize and move sprites with cc65, synchronized
// to the VSync interrupt.
// Tested with cc65 V2.18.
//
// Generate assembler listing to demo.txt:
// cl65 -t c64 -O -l demo.txt demo.c
//
// See Makefile how to compile it and how to convert a PNG image to a C array.

#include <stdint.h>
#include <stdio.h>
#include <conio.h>
#include <6502.h>

#include "balloon.inc"

#define SPRITE_COUNT 16

/*
Python script to generate the table:
import math
cycle=100
ampl=50.0
[int(math.sin(float(i)/cycle*2.0*math.pi)*ampl+0.5) for i in range(cycle)]
*/
static int sin[] = {
    0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 29, 32, 34, 36, 39, 40, 42,
    44, 45, 46, 48, 48, 49, 50, 50, 50, 50, 50, 49, 48, 48, 46, 45,
    44, 42, 40, 39, 36, 34, 32, 29, 27, 24, 21, 18, 15, 12, 9, 6, 3,
    0, -2, -5, -8, -11, -14, -17, -20, -23, -26, -28, -31, -33, -35,
    -38, -39, -41, -43, -44, -45, -47, -47, -48, -49, -49, -49, -49,
    -49, -48, -47, -47, -45, -44, -43, -41, -39, -38, -35, -33, -31,
    -28, -26, -23, -20, -17, -14, -11, -8, -5, -2
};

static uint8_t ofs = 0;

static void vpoke(uint8_t bank, uint16_t address, uint8_t data)
{
    // address selection 0
    VERA.control = 0;
    // set address
    VERA.address_hi = bank;
    VERA.address = address;
    // store data with data port 0
    VERA.data0 = data;
}

static unsigned char irq()
{
    uint8_t j = ofs;
    uint8_t i;

    // update sprite y coordinate
    for (i = 0; i < SPRITE_COUNT; i++) {
        uint16_t adr = i * 8;
        vpoke(0xf, 0x5004 + adr, 80 + sin[j]);
        j += 4;
        if (j > 99) j -= 100;
    }
    
    // update start offset
    ofs++;
    if (ofs == 100) ofs = 0;
    
    // return from interrupt
    return IRQ_HANDLED;
}

int main()
{
    uint16_t i = 0;

    // switch back to uppercase character set
    __asm__("lda #$8e");
    __asm__("jsr BSOUT");
    
    // initialize sprite information
    for (i = 0; i < SPRITE_COUNT; i++) {
        uint16_t adr = i * 8;
        uint16_t x = i * 30 + 20;

        // address 12:5
        vpoke(0xf, 0x5000 + adr, 0);

        // address 16:13 (starting at 0x10000) and 8 bpp mode
        vpoke(0xf, 0x5001 + adr, 0x88);

        // x coordinate 7:0
        vpoke(0xf, 0x5002 + adr, (x & 0xff));

        // x coordinate 9:8
        vpoke(0xf, 0x5003 + adr, x >> 8);

        // y coordinate 7:0
        vpoke(0xf, 0x5004 + adr, 0);

        // y coordinate 9:8
        vpoke(0xf, 0x5005 + adr, 0);

        // z-depth: in front of layer 2
        vpoke(0xf, 0x5006 + adr, 0x0c);

        // 64 pixels for width and height
        vpoke(0xf, 0x5007 + adr, 0xf0);
    }
    
    // copy balloon sprite data to video RAM
    for (i = 0; i < 64*64; i++) vpoke(1, i, balloon[i]);

    // enable sprites
    vpoke(0xf, 0x4000, 1);
    
    // set new interrupt function
    // needs different local stack from 0xa000 to 0xa7ff, because the stack functions are not reentrant
    set_irq(irq, (void*) 0xa800, 0x0800);
    
    // the rest runs in the interrupt
    printf("press any key to stop\n");
    while (!kbhit());
    cgetc();
    
    // disable sprites
    vpoke(0xf, 0x4000, 0);
    
	return 0;
}

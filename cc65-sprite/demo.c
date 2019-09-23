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

#include "balloon.inc"

#define SPRITE_COUNT 16

/*
import math
cycle=56
ampl=50
[int(math.sin(i/cycle*2*math.pi)*ampl+0.5) for i in range(cycle)]
*/
int sin[] = {
	0, 6, 11, 17, 22, 27, 31, 35, 39, 42, 45, 47, 49, 50, 50,
	50, 49, 47, 45, 42, 39, 35, 31, 27, 22, 17, 11, 6, 0, -5,
	-10, -16, -21, -26, -30, -34, -38, -41, -44, -46, -48, -49,
	-49, -49, -48, -46, -44, -41, -38, -34, -30, -26, -21, -16,
	-10, -5
};

struct VERA_t {
    uint8_t lo;
    uint8_t mid;
    uint8_t hi;
    uint8_t data1;
    uint8_t data2;
    uint8_t ctrl;
    uint8_t ien;
    uint8_t isr;
};

#define VERA (*(volatile struct VERA_t*) 0x9f20)

static uint8_t ofs = 0;

static void vpoke(uint8_t bank, uint16_t address, uint8_t data)
{
    // address selection 0
    VERA.ctrl = 0;
    // set address
    VERA.hi = bank;
    VERA.mid = address >> 8;
    VERA.lo = address & 0xff;
    // store data with data port 1
    VERA.data1 = data;
}

static void irq()
{
    uint8_t j = ofs;
    uint8_t i;

    // clear interrupt flags
    VERA.isr = 1;

    // update sprite y coordinate
    for (i = 0; i < SPRITE_COUNT; i++) {
        uint16_t adr = i * 8;
        vpoke(0xf, 0x5004 + adr, 80 + sin[j]);
        j += 4;
        if (j > 55) j -= 56;
    }
    
    // update start offset
    ofs++;
    if (ofs == 56) ofs = 0;
    
    // return from interrupt
    __asm__("PLA");
    __asm__("TAY");
    __asm__("PLA");
    __asm__("TAX");
    __asm__("PLA");
    __asm__("RTI");
}

int main(void)
{
    uint16_t i = 0;
    
    // switch back to uppercase character set
    __asm__("lda #$8e");
    __asm__("jsr BSOUT");
    
    // disable interrupts
    __asm__("sei");

    // bad hack: redefine CC65 stack to $0xa800-0xafff, should be a proper x16 custom target
    *((uint16_t*) 0x02) = 0xb000;
    
    // set new interrupt function
    *((uint16_t*) 0x0314) = (uint16_t) irq;
    
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
    
    // enable interrupts
    __asm__("cli");

    // the rest runs in the interrupt
    while (1);
    
	return 0;
}

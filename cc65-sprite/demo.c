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
// Tested with the latest unreleased cc65, V2.18 - Git 18afc7c7
//
// Generate an assembler listing into demo.txt:
// cl65 -t cx16 -O -l demo.txt demo.c
//
// See Makefile how to compile it, and how to convert a PNG image to a C array.

#include <stdint.h>
#include <stdio.h>
#include <conio.h>
#include <cbm.h>

static const
#include "balloon.inc"

#define SPRITE_COUNT 16
#define SPRITE_X_SPACING 30
#define SPRITE_X_START 20

/*
Python script to generate the table:
import math
cycle=100
ampl=50.0
[int(math.sin(float(i)/cycle*2.0*math.pi)*ampl+0.5) for i in range(cycle)]
*/
static const int sin[] = {
    0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 29, 32, 34, 36, 39, 40, 42,
    44, 45, 46, 48, 48, 49, 50, 50, 50, 50, 50, 49, 48, 48, 46, 45,
    44, 42, 40, 39, 36, 34, 32, 29, 27, 24, 21, 18, 15, 12, 9, 6, 3,
    0, -2, -5, -8, -11, -14, -17, -20, -23, -26, -28, -31, -33, -35,
    -38, -39, -41, -43, -44, -45, -47, -47, -48, -49, -49, -49, -49,
    -49, -48, -47, -47, -45, -44, -43, -41, -39, -38, -35, -33, -31,
    -28, -26, -23, -20, -17, -14, -11, -8, -5, -2
};

static void vpoke(uint8_t bank, uint16_t address, uint8_t data)
{
    // Set port 0's address.
    VERA.control = 0;
    VERA.address_hi = bank;
    VERA.address = address;
    // Store data through port 0.
    VERA.data0 = data;
}

void main(void)
{
    uint16_t i, x;
    uint8_t j, ofs = 0;

    // Switch back to the uppercase character set.
    cbm_k_bsout(CH_FONT_UPPER);

    // Initialize the sprite information.
    for (i = 0; i < SPRITE_COUNT; i++) {
        x = i * SPRITE_X_SPACING + SPRITE_X_START;

        // Set the address to increment with each access.
        // Address bits 12:5
        vpoke(0x1F, 0x5000 + i * 8, (0x010000 >> 5) & 0xFF);

        // Address bits 16:13 (starting at 0x010000) and 8 BPP mode
        VERA.data0 = (1 << 7) | (0x010000 >> 13);

        // x co-ordinate, bits 7:0
        VERA.data0 = x & 0xFF;

        // x co-ordinate, bits 9:8
        VERA.data0 = x >> 8;

        // y co-ordinate, bits 7:0
        VERA.data0 = 0 & 0xFF;

        // y co-ordinate, bits 9:8
        VERA.data0 = 0 >> 8;

        // z-depth: in front of layer 1
        VERA.data0 = (3 << 2);

        // 64 pixels for width and height
        VERA.data0 = (3 << 6) | (3 << 4);
    }

    // Copy the balloon sprite data into the video RAM.
    // Set the address to increment with each access.
    vpoke(0x11, 0x0000, balloon[0]);
    for (i = 0; ++i < 64*64; )
        VERA.data0 = balloon[i];

    // Enable the sprites.
    vpoke(0x0F, 0x4000, 0x01);

    // Animate those sprites.
    puts("\npress any key to stop.");
    do {
        j = ofs;

        // Wait until the start of the next video frame.
        waitvsync();

        // Update the sprites' y co-ordinates.
        for (i = 0; i < SPRITE_COUNT * 8; i += 8) {
            vpoke(0x0F, 0x5004 + i, 80 + sin[j]);
            j += 4;
            if (j > 99)
                j -= 100;
        }

        // Update the start offset.
        if (++ofs == 100)
            ofs = 0;
    } while (!kbhit());
    cgetc();

    // Disable the sprites.
    vpoke(0x0F, 0x4000, 0x00);
}

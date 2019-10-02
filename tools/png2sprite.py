#!/usr/bin/env python3

# Copyright (c) 2019, Frank Buss
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# Converts a PNG image to a C style array to be used as a sprite with Commander X16

from PIL import Image
import numpy as np
import math
import sys
import argparse

# parse arguments
parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
    description='Converts a PNG file to Commander X16 sprite data.\n\n'
    'Examples:\n\n'
    'png2sprite.py -n balloon.png balloon.c balloon.inc\n'
    'Read the PNG image balloon.png and create a file with a C array named "balloon".\n\n'
    'png2sprite.py -c ffffff mini.png test.bas\n'
    'Read the PNG image mini.png and create a file test.bas with a BASIC file with\n'
    'DATA statements starting at line 10000, using white for transparent color.\n\n'
    'Note: the PNG file must have a fully transparent background, which is then used for index 0.')
parser.add_argument('input', help='the PNG input file name')
parser.add_argument('output', help='the output file name')
parser.add_argument('-f', default='c', choices=['c','basic','acme'], help='output format: c for C array, basic for BASIC, acme for ACME assembler, default: c')
parser.add_argument('-n', default='', help='array / label / start line number for C / assembler / BASIC, default: sprite/10000')
args = parser.parse_args()
if args.n == '':
    if args.f == 'c' or args.f =='acme':
        args.n = 'sprite'
    if args.f == 'basic':
        args.n = '10000'

# default x16 palette
default_palette = [
0x0000,0xfff,0x800,0xafe,0xc4c,0x0c5,0x00a,0xee7,0xd85,0x640,0xf77,0x333,0x777,0xaf6,0x08f,0xbbb,0x000,0x111,0x222,0x333,0x444,0x555,0x666,0x777,0x888,0x999,0xaaa,0xbbb,0xccc,0xddd,0xeee,0xfff,0x211,0x433,0x644,0x866,0xa88,0xc99,0xfbb,0x211,0x422,0x633,0x844,0xa55,0xc66,0xf77,0x200,0x411,0x611,0x822,0xa22,0xc33,0xf33,0x200,0x400,0x600,0x800,0xa00,0xc00,0xf00,0x221,0x443,0x664,0x886,0xaa8,0xcc9,0xfeb,0x211,0x432,0x653,0x874,0xa95,0xcb6,0xfd7,0x210,0x431,0x651,0x862,0xa82,0xca3,0xfc3,0x210,0x430,0x640,0x860,0xa80,0xc90,0xfb0,0x121,0x343,0x564,0x786,0x9a8,0xbc9,0xdfb,0x121,0x342,0x463,0x684,0x8a5,0x9c6,0xbf7,0x120,0x241,0x461,0x582,0x6a2,0x8c3,0x9f3,0x120,0x240,0x360,0x480,0x5a0,0x6c0,0x7f0,0x121,0x343,0x465,0x686,0x8a8,0x9ca,0xbfc,0x121,0x242,0x364,0x485,0x5a6,0x6c8,0x7f9,0x020,0x141,0x162,0x283,0x2a4,0x3c5,0x3f6,0x020,0x041,0x061,0x082,0x0a2,0x0c3,0x0f3,0x122,0x344,0x466,0x688,0x8aa,0x9cc,0xbff,0x122,0x244,0x366,0x488,0x5aa,0x6cc,0x7ff,0x022,0x144,0x166,0x288,0x2aa,0x3cc,0x3ff,0x022,0x044,0x066,0x088,0x0aa,0x0cc,0x0ff,0x112,0x334,0x456,0x668,0x88a,0x9ac,0xbcf,0x112,0x224,0x346,0x458,0x56a,0x68c,0x79f,0x002,0x114,0x126,0x238,0x24a,0x35c,0x36f,0x002,0x014,0x016,0x028,0x02a,0x03c,0x03f,0x112,0x334,0x546,0x768,0x98a,0xb9c,0xdbf,0x112,0x324,0x436,0x648,0x85a,0x96c,0xb7f,0x102,0x214,0x416,0x528,0x62a,0x83c,0x93f,0x102,0x204,0x306,0x408,0x50a,0x60c,0x70f,0x212,0x434,0x646,0x868,0xa8a,0xc9c,0xfbe,0x211,0x423,0x635,0x847,0xa59,0xc6b,0xf7d,0x201,0x413,0x615,0x826,0xa28,0xc3a,0xf3c,0x201,0x403,0x604,0x806,0xa08,0xc09,0xf0b
]
default_palette.reverse()

# load image
im = Image.open(args.input)
im = im.convert('RGBA')
p = np.array(im)

# convert to sprite data
i = 0
with open(args.output, "w") as file:
    if args.f == 'c':
        file.write("uint8_t %s[] = {\n" % args.n)
    if args.f == 'acme':
        file.write("%s:\n" % args.n)
    if args.f == 'basic':
        line = int(args.n)
    for y in range(im.height):
        for x in range(im.width):
            if i == 0:
                if args.f == 'acme':
                    file.write("    !byte ")
                if args.f == 'basic':
                    file.write("%i DATA " % line)
                    line = line + 1

            # get pixel color
            r, g, b, a = p[y][x]

            # use index 0 for transparent color
            if a == 0:
                best = 0
            else:
                # find best palette match, start searching from top to allow index 16 for black color
                d = 1e9
                best = 0
                j = 255
                for entry in default_palette:
                    rp = ((entry >> 8) & 0xf) << 4
                    gp = ((entry >> 4) & 0xf) << 4
                    bp = (entry & 0xf) << 4
                    dr = r - rp
                    dg = g - gp
                    db = b - bp
                    d0 = dr * dr + dg * dg + db * db
                    if d0 < d:
                        best = j
                        d = d0
                    j = j - 1
                
            # write palette index
            if args.f == 'c':
                file.write("0x%02x," % best)
            if args.f == 'acme' or args.f == 'basic':
                file.write("$%02x" % best)
                if i < 15:
                    file.write(",")
            i = i + 1
            if i == 16:
                file.write("\n")
                i = 0
    if i != 0:
        file.write("\n")
    if args.f == 'c':
        file.write("};")

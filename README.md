C, Asssembly and B.A.S.I.C. v2 examples for commander-x16

Basic examples are collected from Facebook group

1. basic - A set of simple example. Start from here
2. basic-sprite - How to use VERA chip to make a sprite. Needs python3 to convert png to "DATA"
3. layer demo - More complex demo showing VERA "layers"
4. cc65-sprite - C-language sprite demo with CC65
5. petdraw - Petdraw Commander X16 version by David Murray

The tools/ directory contains:

+ bas2prg.py - Convert a basic program to binary png calling the emulator. Used internally during release building
+ png2sprite.py - A PNG2Sprite converter. Launch with "-h" to get usage examples
+ renumber.py - Renumber a basic program (.bas) Launch with --help to get usage.
+ bin2c.py - Converts any bin file to a C array
+ requirements.txt - Python requirements for the tools. Use with "pip3 install -r requirements.txt"


# How to compile asm files
The Makefile need the acme compiler.

Install the acme compiler from 
wget https://github.com/meonwax/acme/archive/master.zip
and the cc65 toolchain (needed for some files)

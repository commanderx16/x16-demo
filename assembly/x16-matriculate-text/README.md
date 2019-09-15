# x16-matriculate-text

A Matrix-inspired text crawl that totally took me to school.

*This code works with Vera 0.8*. For Vera 0.7 code, as released in r30 and prior, see [the r30 release](https://github.com/indigodarkwolf/x16-matriculate-text/releases/tag/r30).

## ma·tric·u·late

/məˈtrikyəˌlāt/ (_verb_)

1. be enrolled at a college or university.
"he matriculated at the University of Vermont"

## Building this demo

`ACME -f cbm -DMACHINE_C64=0 -o matriculate.prg matriculate.asm`

## What this does, in order

* Perform a table-based decrement of each palette index once per frame until all palette colors have been set to black ($0000).

* Assign a random character to each screen position

* Assign a random palette index to each character in the top row

* Set each subsequent row's character palette indices to "whatever it is directly above me, plus 1". There's 256 colors in the X16's palette, and I can use 255 of them (I have to leave color 0 black for the background, so that means if I'm about to assign palette index "0" to a character, I instead assign "1").

* Perform a palette-cycling trick, which is to say I've got an array of colors in program memory from white-green to black, and I just write them to a chunk of the system palette, and then increment my starting point by 1 each frame. The Vera's hardware does the rest, choosing what colors to draw based on that palette.

## Getting started with assembly on the X16

For the X16, the basic tools you need are any text editor and a 6502 assembler program.

For a text editor, I used Visual Studio Code:

<https://code.visualstudio.com/>

For the assembler, I used Acme 0.96.4:

<https://sourceforge.net/projects/acme-crossass/files/win32/>

If you're completely new to assembly and the 6502, I feel like this resource is a good starting point:

<http://skilldrick.github.io/easy6502/>

I made frequent use of this portion, in particular, to experiment with small assembly samples to try and isolate bugs in my code:

<https://skilldrick.github.io/easy6502/simulator.html>

After that, you just need some documentation. Well, a fair bit of documentation. For a reference of 6502 instructions, I liked this page:

<http://www.6502.org/tutorials/6502opcodes.html>

And the X16 official documentation is crucial when it comes to understanding what memory you can use, for what purposes:

<https://github.com/commanderx16/x16-docs>

If the Vera documentation feels a bit over your head, maybe you'd prefer my version on Google docs, just keep in mind that it's not "authoritative" in any sense:

<https://docs.google.com/document/d/1pFlevjsf_PRcOb0QLJp9IGihgYsVtUIxEW5ZZqtu0z0/edit?usp=sharing>

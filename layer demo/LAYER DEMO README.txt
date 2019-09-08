This program uses dual tile layers to scroll a pair of animated "electricity" beams
down the screen in front of a grid of scrolling circles in parallax.

The background is filled using a macine language routine at 11000, loaded in
BASIC lines 400-499. This same loop in BASIC took over 10 seconds to fill the
background with the circle tile. The program could run even faster if the
electricity tile data load were converted to machine language, but I'm not doing that
right now. Feel free to modify that for your own learning exercise.

The electricity tiles use color index $FF, which is randomly changed on each "frame"
The squares use tile index 24 and color $50 (yellow)
All empty tiles are transparent so you see the original display beneath on layer 0.

For each frame, the VSCROLL register for layer 1 is lowered by 3, looping back to $FFF.
The VERA chip automatically loops the displayed graphics through the 64 rows of the
tile map area, so there's no need to limit the range of the scroll value to 64*8

The tile animation is done by moving the TILE_BASE pointer for layr 1. This is much
faster than having to update every tile in video memory which needs to animate.

Example:
If screen memory has a string ABCDEFG, this would be screen codes 1 2 3 4 5 6 7.
code 1 looks like an A because the TILE_DATA in slot 1 contains the arrangement of
pixels which look like an A.

If you move the TILE_BASE forward by 8 bytes in vram, the screen would now show
the string BCDEFGH. The screen codes are still 1 2 3 4 5 6 7, but the pixel data is
now off by one slot so they're each drawn as the next letter in the alphabet.

If you moved the TILE_BASE forward another 8 bytes, the screen would show CDEFGHI
etc.

This demo does not update TILE_BASE by 8, but by 32. This is because it was
originally designed to have 4 tiles with which to draw the electric beams.
Tile 0 is a blank space.
Tiles 1-3 are electricity.
4 tiles of 8 bytes each = 32 bytes.

So the first 32 bytes of tile memory contain the frame 0 pixel data for tiles 0-3.
The next 32 bytes contain the frame 1 pixel data for tiles 0-3.
Since the blank space shouldn't animate, it's drawn the same way again, but
tiles 1-3 are updated with the look they need for frame 1 of the animation cycle.

The electricity's animation cycle is a left rotation of the pixels A<-B<-C
with the pixels looping back to the right of C. 3 tiles = 24 pixels, moving 4px per
frame. Thus it takes 6 frames to complete the cycle.
6 frames * 4 tiles means there are 24 tiles' worth of pixel data for the animation.

Here is how it would look if arranged on the screen in a grid:
id: 0  1  2  3
    __,AA,BB,CC (frame0)
    __,AB,BC,CA (frame1)
    __,BB,CC,AA (frame2)
    __,BC,CA,AB (frame3)
    __,CC,AA,BB (frame4)
    __,CA,AB,BC (frame5)

Note that the space char is the same for all 6 frames, but has to be repeated 
in memory for all 6 frames as well. 

I then decided to add the solid squares at the ends of the electricity beams.
Since the first 24 characters' worth of space is already taken up by the animation
frames for the first 4 tiles, I had to use tile ID 24 to represent the square.
Like the space, it has to be copied into all 6 frames' locations, so it's in the
graphics locations for 24, 28, 32, 36, 40, and 44.
You could make tile 25 also be a non-animated tile by putting the same data in
tile locations 25, 29, 33, 37, 41, and 45. Etc.

This works for this demo, but the better way to do this for larger programs needing
more tiles would be to move the TILE_BASE pointer by, say 64 tiles' worth of space
instead of 4 tiles' worth. Then you would have 64 non-overlapping tiles. It's also more
common in retro console dev to use power-of-two numbers for the frame count as well,
since this dovetails easily with bitmasks and bit shifts.
So in a game, I would use a 4-frame cycle and spend more time drawing an animation cycle
that looked good in 4 frames.

This would also save 2 copies of tile data from memory.

Anyway, I hope this demo is useful. Sorry for the convoluted animation logic, but I
wanted to have something that looked kind of cool.


!symbollist "matriculate.sym"

;=================================================
;=================================================
; 
;   Headers
;
;-------------------------------------------------

!src "vera.inc"
!src "system.inc"

;=================================================
; Macros
;
;-------------------------------------------------

DEFAULT_SCREEN_ADDR = 0
DEFAULT_SCREEN_SIZE = (128*64)*2

;=================================================
; MOD
;   Module the accumulator by a value.
;-------------------------------------------------
; INPUTS:   .v  Divisor of the modulo
;
;-------------------------------------------------
; MODIFIES: A
; 
!macro MOD .v {
-   sec
    sbc #.v
    bcs -
    adc #.v
}

    +SYS_HEADER_0801

;=================================================
;=================================================
; 
;   main code
;
;-------------------------------------------------
start:
    +SYS_RAND_SEED $34, $56, $fe

.decrement_palette:
    ; This is an optimistic flag: have we cleared the entire palette? 
    ; We'll falsify if not.
    lda #1
    sta All_palettes_cleared

    ; Let's assume the system is starting in Mode 0 with the default palette.
    ; And fade out the screen because we can.
    +VERA_SELECT_ADDR 0
    +VERA_SET_PALETTE 0
    +VERA_SELECT_ADDR 1
    +VERA_SET_PALETTE 0

    ldy #0 ; 256 colors in the palette

.decrement_palette_entry:
    lda VERA_data
    ; Don't need to decrement if already #0 (black)
    cmp #0
    beq +

    ; The first byte is %0000rrrr, which means we could get away just a
    ; decrement. But the second is %ggggbbbb, so we need to decrement 
    ; each half if not 0. Instead of complex assembly to do that, I'm just 
    ; going to precompute to a table and do a lookup of the next value.
    ; And since I did it that way for the second byte, do it the same
    ; way for the first as well since that answer is good for both.
    tax

    lda #0
    sta All_palettes_cleared

    lda Palette_decrement_table, X
+   sta VERA_data2

    lda VERA_data

    ; Still don't need to decrement 0.
    cmp #0
    beq +

    tax

    lda #0
    sta All_palettes_cleared

    lda Palette_decrement_table, X
+   sta VERA_data2

    dey
    bne .decrement_palette_entry

    +SYS_SET_IRQ inc_new_frame
    cli
    ; Tight loop until next frame
-   lda New_frame
    cmp #$01
    bne -

    sei

__start__is_palette_fade_done:
    lda #0
    sta New_frame

    lda All_palettes_cleared
    cmp #0
    beq .decrement_palette

    ;
    ; Palette memory should now be all 0s, or a black screen.
    ; If only the composer gave us a brightness setting, I could
    ; have used that. Mei banfa.
    ;

    +VERA_SELECT_ADDR 0

    +VERA_SET_ADDR VRAM_layer1
    +VERA_WRITE ($01 << 5) | $01            ; Mode 1 (256-color text), enabled
    +VERA_WRITE %00000110                   ; 8x8 tiles, 128x64 map
    +VERA_WRITE <(DEFAULT_SCREEN_ADDR >> 2) ; Map indices at VRAM address 0
    +VERA_WRITE >(DEFAULT_SCREEN_ADDR >> 2) ; 
    +VERA_WRITE <(VROM_petscii >> 2)        ; Tile data immediately after map indices
    +VERA_WRITE >(VROM_petscii >> 2)        ; Tile data immediately after map indices
    +VERA_WRITE 0, 0, 0, 0                  ; Hscroll and VScroll to 0

!zn __start__fill_text_buffer_with_random_chars {
__start__fill_text_buffer_with_random_chars:
    +VERA_SET_ADDR DEFAULT_SCREEN_ADDR, 2

    ldx #128
    ldy #64

.yloop:
    tya
    pha
.xloop:
    txa

    jsr sys_rand
    and #$7F
    tay

    lda Petscii_table,Y
    sta VERA_data

    tax
    dex
    bne .xloop

    pla
    tay
    dey
    bne .yloop
}

!zn __start__offset_palette_of_each_column {
__start__offset_palette_of_each_column:
    +VERA_SET_ADDR DEFAULT_SCREEN_ADDR+1, 2

    lda #128

.xloop:
    pha

    jsr sys_rand
    ; If we're about to assign palette index 0 (background), increment to 1
    cmp #0
    beq +
    clc
    adc #1
+   sta VERA_data

    pla
    sec
    sbc #1
    bne .xloop
}

!zn __start__fill_palette_of_remaining_chars {
__start__fill_palette_of_remaining_chars:
    +VERA_SET_ADDR DEFAULT_SCREEN_ADDR+1, 2
    +VERA_SELECT_ADDR 1
    +VERA_SET_ADDR DEFAULT_SCREEN_ADDR+257, 2
    +VERA_SELECT_ADDR 0

    ldx #127
    ldy #64

.yloop:
    tya
    pha
.xloop:
    txa
    pha

    lda VERA_data
    clc
    adc #1
    ; If we're about to assign palette index 0 (background), increment to 1
    cmp #0
    bne +
    clc
    adc #1
+   sta VERA_data2

    pla
    tax
    dex
    bne .xloop

    pla
    tay
    dey
    bne .yloop
}

    +SYS_SET_IRQ irq_handler
    cli

    jmp *

    ; +VERA_RESET

;=================================================
;=================================================
; 
;   IRQ Handlers
;
;-------------------------------------------------

;=================================================
; irq_handler
;   This is essentially my "do_frame". Several others have been doing this as well.
;   Since the IRQ is triggered at the beginning of the VGA/NTSA front porch, we don't
;   get the benefit of the entire VBLANK, but it's still useful as a "do this code
;   once per frame" function.
;-------------------------------------------------
; INPUTS: (none)
;
;-------------------------------------------------
; MODIFIES: A, X, Y, VRAM_palette
; 
irq_handler:
    ; Increment which palette index we're starting at
    lda Palette_cycle_index
    clc
    adc #1
    ; Skip index zero, that's the background, we want to leave it black.
    adc #0
    sta Palette_cycle_index

;
; Palette cycle for the letters glowing and stuff
;

    ; Set the starting address of the VRAM palette we're going to cycle
    asl ; Palette_cycle_index * 2 == Address offset into palette memory
    ; adc #<(VRAM_palette) ; We happen to know that #<(VRAM_palette) is 0. Being able to skip this also preserves Carry in case it was set
    sta VERA_addr_low
    lda #<(VRAM_palette >> 8)
    adc #0  ; Add carry bit for indices 128-255
    sta VERA_addr_high
    lda #<(VRAM_palette >> 16) | (1 << 4)
    sta VERA_addr_bank

    lda #<Matrix_palette
    sta $FB
    lda #>Matrix_palette
    sta $FC

NUM_MATRIX_PALETTE_ENTRIES = ((Matrix_palette_end - Matrix_palette) >> 1)

    ldx Palette_cycle_index
    ldy #0

-   lda ($FB),Y
    sta VERA_data
    iny
    lda ($FB),Y
    sta VERA_data
    iny
    inx
    bne +
    +VERA_SET_PALETTE 0, 1
+   cpy #(Matrix_palette_end - Matrix_palette)
    bne -

;
; Palette cycle (redux) for double-density!
;
    lda Palette_cycle_index
    adc #127
    clc

    ; Set the starting address of the VRAM palette we're going to cycle
    asl ; Palette_cycle_index * 2 == Address offset into palette memory
    ; adc #<(VRAM_palette) ; We happen to know that #<(VRAM_palette) is 0. Being able to skip this also preserves Carry in case it was set
    sta VERA_addr_low
    lda #<(VRAM_palette >> 8)
    adc #0  ; Add carry bit for indices 128-255
    sta VERA_addr_high
    lda #<(VRAM_palette >> 16) | (1 << 4)
    sta VERA_addr_bank

    lda #<Matrix_palette
    sta $FB
    lda #>Matrix_palette
    sta $FC

NUM_MATRIX_PALETTE_ENTRIES = ((Matrix_palette_end - Matrix_palette) >> 1)

    lda Palette_cycle_index
    adc #128    ; "But you did `adc #127` above." Yes, and it created a sneaky off-by-one bug. So this is a sneaky off-by-one fix.
    clc
    tax
    ldy #0

-   lda ($FB),Y
    sta VERA_data
    iny
    lda ($FB),Y
    sta VERA_data
    iny
    inx
    bne +
    +VERA_SET_PALETTE 0, 1
+   cpy #(Matrix_palette_end - Matrix_palette)
    bne -
    +VERA_END_IRQ
    +SYS_END_IRQ

;=================================================
; inc_new_frame
;   This is essentially my "do_frame". Several others have been doing this as well.
;   Since the IRQ is triggered at the beginning of the VGA/NTSA front porch, we don't
;   get the benefit of the entire VBLANK, but it's still useful as a "do this code
;   once per frame" function.
;-------------------------------------------------
; INPUTS:   Sys_rand_mem
;
;-------------------------------------------------
; MODIFIES: A, X, Sys_rand_mem
; 
inc_new_frame:
    inc New_frame
    +VERA_END_IRQ
    +SYS_END_IRQ

;=================================================
;=================================================
; 
;   Miscellaneous data copying
;
;-------------------------------------------------
;
; I wasn't sure what to do with this. I already have
; SYS_STREAM_OUT, but I basically needed it for 
; a source address and quantity of data that can
; only be determined at run-time. I'm I'll eventually
; convert this into some kind of other 
; SYS_STREAM_OUT-like macro, so that I can
; easily declare function definitions for a variety
; of fixed destinations, and then come back and do 
; the same for fixed sources with runtime destinations
; and of course a function to just handle everything
; being runtime data.
;

;==============================================
; VERA_stream_out_data
; Stream out a block of memory to VERA_data
;----------------------------------------------
; INPUT: X   - number of pages to stream
;        Y   - number of bytes to stream
;        $FB - low byte of starting address
;        $FC - high byte of starting address
;----------------------------------------------
; Modifies: A, X, Y, $FC
;
VERA_stream_out_data:
    tya
    pha
    ; If no pages to copy, skip to bytes
    txa
    cmp #0
    tax
    beq .no_blocks

    ; Copy X pages to VERA_data
    ldy #0
.loop:
    lda ($FB),Y
    sta VERA_data
    iny
    bne .loop

    inc $FC
    dex
    bne .loop

.no_blocks:
    ; Copy X bytes to VERA_data
    pla
    tax
    ldy #0
.loop2:
    lda ($FB),Y
    sta VERA_data
    iny
    dex
    bne .loop2
    rts

;=================================================
;=================================================
; 
;   Libs
;
;-------------------------------------------------
!src "system.asm"

;=================================================
;=================================================
; 
;   Data
;
;-------------------------------------------------
Petscii_table:
    !for i,1,$60 {
        !byte i
    }
    !for i,0,$20 {
        !byte i+$A0
    }

Matrix_palette:
    !le16 $0000, $0000, $0020, $0020, $0030, $0030, $0040, $0040
    !le16 $0050, $0050, $0060, $0060, $0070, $0070, $0080, $0080
    !le16 $0090, $0090, $00A0, $00A0, $00B0, $00B0, $00C0, $00C0
    !le16 $00D0, $00D0, $00E0, $00E0, $00F0, $00F0, $08FC
Matrix_palette_end:
Matrix_palette_rev:
    !le16 $0000, $0000, $08FC, $00F0, $00F0, $00E0, $00E0, $00D0
    !le16 $00D0, $00C0, $00C0, $00B0, $00B0, $00A0, $00A0, $0090
    !le16 $0090, $0080, $0080, $0070, $0070, $0060, $0060, $0050
    !le16 $0050, $0040, $0040, $0030, $0030, $0020, $0020
Matrix_palette_rev_end:

Palette_decrement_table:
    ;     $X0, $X1, $X2, $X3, $X4, $X5, $X6, $X7, $X8, $X9, $XA, $XB, $XC, $XD, $XE, $XF
    !byte $00, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E    ; $0X
    !byte $00, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E    ; $1X
    !byte $10, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E    ; $2X
    !byte $20, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E    ; $3X
    !byte $30, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $3E    ; $4X
    !byte $40, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E    ; $5X
    !byte $50, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E    ; $6X
    !byte $60, $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E    ; $7X
    !byte $70, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79, $7A, $7B, $7C, $7D, $7E    ; $8X
    !byte $80, $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8A, $8B, $8C, $8D, $8E    ; $9X
    !byte $90, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $9B, $9C, $9D, $9E    ; $AX
    !byte $A0, $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $A9, $AA, $AB, $AC, $AD, $AE    ; $BX
    !byte $B0, $B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $BB, $BC, $BD, $BE    ; $CX
    !byte $C0, $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE    ; $DX
    !byte $D0, $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE    ; $EX
    !byte $E0, $E0, $E1, $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $EB, $EC, $ED, $EE    ; $FX

;=================================================
;=================================================
;
;   Variables
;
;-------------------------------------------------
!src "matriculate_vars.asm"
!src "system_vars.asm"

    +SYS_FOOTER
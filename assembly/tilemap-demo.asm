!src "vera.inc"

*=$0801

	!byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00

	+video_init VERA_EN_LAYER0

	+vset $00000 | VERA_AUTO_INC_1 ; VRAM bank 0

	ldx #8
	ldy #0
	lda #<tilemap
	sta 2
	lda #>tilemap
	sta 3
loop1:	lda (2),y
	sta VERA_DATA
	iny
	bne loop1
	inc 3
	dex
	bne loop1

	+vset $10000 | VERA_AUTO_INC_1 ; VRAM bank 1

	ldx #14
	ldy #0
	lda #<tiles
	sta 2
	lda #>tiles
	sta 3
loop2:	lda (2),y
	sta VERA_DATA
	iny
	bne loop2
	inc 3
	dex
	bne loop2

	+vset VERA_PALETTE_BASE | VERA_AUTO_INC_1

	ldx #2
	ldy #0
	lda #<palette
	sta 2
	lda #>palette
	sta 3
loop3:	lda (2),y
	sta VERA_DATA
	iny
	bne loop3
	inc 3
	dex
	bne loop3

	lda #$03 ; 8bpp 32x32 tilemap
	sta VERA_L0_CONFIG
	lda #$00 ; map base = $00000
	sta VERA_L0_MAPBASE
	lda #$83 ; 16x16 tiles, tile base = $10000
	sta VERA_L0_TILEBASE
	lda #0 ; zero-fill scroll registers
	sta VERA_L0_HSCROLL_L
	sta VERA_L0_HSCROLL_H
	sta VERA_L0_VSCROLL_L
	sta VERA_L0_VSCROLL_H

	jmp *

tilemap:
!bin "tilemap-tilemap.bin"
tiles:
!bin "tilemap-tiles.bin"
palette:
!bin "tilemap-palette.bin"

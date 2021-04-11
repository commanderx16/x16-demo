!src "vera.inc"

*=$0801

	!byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00

	+video_init VERA_EN_LAYER0

	+vset $00000 | VERA_AUTO_INC_1

	ldx #$88
	ldy #0
	lda #<bitmap
	sta 2
	lda #>bitmap
	sta 3
loop1:	lda (2),y
	sta VERA_DATA
	iny
	bne loop1
	inc 3
	dex
	bne loop1

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

	lda #$07 ; 8bpp bitmap
	sta VERA_L0_CONFIG
	lda #$00 ; tile base = $00000 (320px wide)
	sta VERA_L0_TILEBASE
	lda #0 ; zero-fill palette offset
	sta VERA_L0_HSCROLL_H

	lda #$40
	sta VERA_DC_HSCALE ; hscale=2x
	sta VERA_DC_VSCALE ; vscale=2x

	jmp *

bitmap:
!bin "mode7-bitmap-cut.bin"
palette:
!bin "mode7-palette.bin"

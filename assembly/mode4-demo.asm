!src "vera.inc"

*=$0801

	!byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00

	+video_init

	+vset $00000 | AUTO_INC_1 ; VRAM bank 0

	ldx #8
	ldy #0
	lda #<tilemap
	sta 2
	lda #>tilemap
	sta 3
loop1:	lda (2),y
	sta veradat
	iny
	bne loop1
	inc 3
	dex
	bne loop1

	+vset $10000 | AUTO_INC_1 ; VRAM bank 1

	ldx #14
	ldy #0
	lda #<tiles
	sta 2
	lda #>tiles
	sta 3
loop2:	lda (2),y
	sta veradat
	iny
	bne loop2
	inc 3
	dex
	bne loop2

	+vset vreg_pal | AUTO_INC_1

	ldx #2
	ldy #0
	lda #<palette
	sta 2
	lda #>palette
	sta 3
loop3:	lda (2),y
	sta veradat
	iny
	bne loop3
	inc 3
	dex
	bne loop3

	+vset vreg_lay1 | AUTO_INC_1

	lda #4 << 5 | 1; mode=4, enabled=1
	sta veradat
	lda #1 << 5 | 1 << 4; // tileh=1, tilew=1
	sta veradat
	lda #(0 >> 2) & 0xff; // map_base
	sta veradat
	lda #0 >> 10;
	sta veradat
	lda #(0x10000 >> 2) & 0xff; // tile_base
	sta veradat
	lda #0x10000 >> 10;
	sta veradat

	jmp *

tilemap:
!bin "mode4-tilemap.bin"
tiles:
!bin "mode4-tiles.bin"
palette:
!bin "mode4-palette.bin"

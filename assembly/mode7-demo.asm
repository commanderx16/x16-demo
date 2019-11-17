!src "vera.inc"

*=$0801

	!byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00

	+video_init

	+vset 0 | AUTO_INC_1

	ldx #$88
	ldy #0
	lda #<bitmap
	sta 2
	lda #>bitmap
	sta 3
loop1:	lda (2),y
	sta veradat
	iny
	bne loop1
	inc 3
	dex
	bne loop1

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

	+vset vreg_lay2 | AUTO_INC_1

	lda #0 ; disabled
	sta veradat ; 0

	+vset vreg_lay1 | AUTO_INC_1

	lda #7 << 5 | 1; // mode=7, enabled=1
	sta veradat ; 0
	; ignore
	sta veradat ; 1
	; ignore
	sta veradat ; 2
	; ignore
	sta veradat ; 3
	lda #(0 >> 2) & 0xff; // map_base
	sta veradat; 4
	lda #0 >> 10;
	sta veradat ; 5

	+vset vreg_cmp + 1 | AUTO_INC_1

	lda #64
	sta veradat ; hscale=2x
	sta veradat ; vscale=2x

	jmp *

bitmap:
!bin "mode7-bitmap-cut.bin"
palette:
!bin "mode7-palette.bin"

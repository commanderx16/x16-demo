!if MACHINE_C64 = 1 {
	verareg =$df00
} else {
	verareg =$9f20
}
verahi  = verareg+0
veramid = verareg+1
veralo  = verareg+2
veradat = verareg+3
veradat2= verareg+4
veractl = verareg+5
veraien = verareg+6
veraisr = verareg+7

*=$0801

	!byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00

	jsr initv

	lda #$10
	sta verahi
	lda #0
	sta veramid
	sta veralo

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

	lda #$14
	sta verahi
	lda #$02
	sta veramid
	lda #0
	sta veralo

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

	lda #$14
	sta verahi
	lda #0
	sta veramid
	sta veralo

	lda #7 << 5 | 1 << 3 | 1 << 1 | 1; // mode=7, vscale=1, hscale=1, enabled=1
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
	lda #320/4
	sta veradat ; 6

	jmp *

;init video
;
initv
	lda #0
	sta veractl     ;set ADDR1 active

	lda #$14        ;$40000: layer 1 registers
	sta verahi
	lda #0
	sta veramid
	sta veralo

	ldx #0
px4	lda tvera,x
	sta veradat
	inx
	cpx #tverend-tvera
	bne px4

	lda #$40
	sta veralo
	lda #1
	sta veradat ; VGA output

	rts

mapbas	=0
tilbas	=$20000

tvera:
	!byte 0 << 5 | 1  ;mode=0, enabled=1
	!byte 1 << 2 | 2  ;maph=64, mapw=128
	!word mapbas >> 2 ;map_base
	!word tilbas >> 2 ;tile_base
	!word 0, 0        ;hscroll, vscroll
tverend

bitmap:
!bin "mode7-bitmap-cut.bin"
palette:
!bin "mode7-palette.bin"

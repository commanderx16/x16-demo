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

	jsr video_init

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

	lda #$41
	sta veralo
	lda #64
	sta veradat ; hscale=2x
	sta veradat ; vscale=2x

	jmp *

video_init:
	lda #0
	sta veractl ; set ADDR1 active
	sta veramid
	lda #$14    ; $40040
	sta verahi
	lda #$40
	sta veralo
	lda #1
	sta veradat ; VGA output
	rts

bitmap:
!bin "mode7-bitmap-cut.bin"
palette:
!bin "mode7-palette.bin"

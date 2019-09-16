!src "vera.inc"

*=$0801

	!byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00

	+video_init

; enable sprites
	lda #1
	+vstore vreg_spr

MAX_SPRITES = 16
MAX_X = 640
MIN_X = $10000-16
MAX_Y = 480
MIN_Y = $10000-32

spr_data = $10000

; configure sprites

	ldx #0
setup:
	txa                  ; palette offset in bits 0-3
	ora #2 << 6 | 1 << 4 ; height=32px, width=16px
	+sprstore 7
	lda #3 << 2          ; z-depth=3
	+sprstore 6
	lda #<(spr_data >> 5)
	+sprstore 0
	lda #>(spr_data >> 5) | 1 << 7 ; mode=1
	+sprstore 1
	inx
	cpx #MAX_SPRITES
	beq setup_done
	jmp setup
setup_done:

; set up sprite shape
	+vset spr_data

	ldy #1 ; white

	ldx #0
l1:	lda sprite,x
	jsr convert_color
	sta veradat
	inx
	bne l1
l2:	lda sprite + $100,x
	jsr convert_color
	sta veradat
	inx
	bne l2
l3:	lda sprite + $200,x
	jsr convert_color
	sta veradat
	inx
	bne l3
l4:	lda sprite + $300,x
	jsr convert_color
	sta veradat
	inx
	bne l4

loop:
	ldx #0
lo2:

; set x pos
	lda sprx_lo,x
	+sprstore 2
	lda sprx_hi,x
	+sprstore 3
	lda spry_lo,x
	+sprstore 4
	lda spry_hi,x
	+sprstore 5

; update x pos
	lda sprx_lo,x
	clc
	adc speed_x,x
	sta sprx_lo,x
	lda #0
	adc sprx_hi,x
	sta sprx_hi,x
ll1:	lda sprx_hi,x
	bmi ll2
	lda sprx_lo,x
	sec
	sbc #<MAX_X
	lda sprx_hi,x
	sbc #>MAX_X
	bcc ll2
	lda #<MIN_X
	sta sprx_lo,x
	lda #>MIN_X
	sta sprx_hi,x
ll2:

; update y pos
	lda spry_lo,x
	sec
	sbc speed_y,x
	sta spry_lo,x
	lda spry_hi,x
	sbc #0
	sta spry_hi,x

	lda spry_hi,x
	bpl ll4
	lda spry_lo,x
	sec
	sbc #<MIN_Y
	lda spry_hi,x
	sbc #>MIN_Y
	bcs ll4
	lda #<MAX_Y
	sta spry_lo,x
	lda #>MAX_Y
	sta spry_hi,x
ll4:
	inx
	cpx #MAX_SPRITES
	beq nlo2
	jmp lo2
nlo2:

	lda #10 
	ldy #0
delay:	dey
	bne delay
	sec
	sbc #1
	bne delay

	jmp loop

convert_color:
	cmp #'.'
	bne cc1
	lda #0
	rts
cc1:	tya
	rts

sprite:
!text "....*******....."
!text "..***********..."
!text ".***.*****.***.."
!text ".****.***.****.."
!text "******.*.******."
!text "******.*.******."
!text "******.*.******."
!text ".****.***.****.."
!text ".***.*****.***.."
!text ".*************.."
!text ".*.*********.*.."
!text "..*.*******.*..."
!text "..*..*****..*..."
!text "...*..***..*...."
!text "...*..***..*...."
!text "....*..*..*....."
!text "....*..*..*....."
!text ".....*****......"
!text ".....*****......"
!text ".....*****......"
!text "......***......."
!text "................"
!text "................"
!text "................"
!text "................"
!text "................"
!text "................"
!text "................"
!text "................"
!text "................"
!text "................"
!text "................"

sprx_lo:
	!byte 216, 47, 111, 171, 118, 34, 129, 97, 164, 168, 41, 29, 228, 207, 140, 17
sprx_hi:
	!byte 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0
spry_lo:
	!byte 221, 223, 182, 216, 50, 181, 147, 234, 164, 219, 251, 168, 14, 155, 141, 83
spry_hi:
	!byte 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1

speed_x:
	!byte 2, 0, 2, 1, 2, 1, 3, 3, 4, 3, 0, 2, 2, 2, 4, 0

speed_y:
	!byte 4, 3, 4, 4, 2, 2, 1, 4, 0, 3, 0, 2, 3, 2, 3, 1




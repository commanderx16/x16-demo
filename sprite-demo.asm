!src "vera.inc"

*=$0801

	!byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00

	+video_init

	+vstore $048000

; enable sprites
	lda #1
	+vstore vreg_spr

spr_data = $10000

; configure sprite #0

	lda #1 << 4
	+vstore vreg_sprd + 1

	lda #3 << 2 | 1 << 1 ; z-depth=3, mode=1
	+vstore vreg_sprd + 3

	lda #<spr_data
	+vstore vreg_sprd + 4
	lda #8 | 1 << 4 | 2 << 6 | >spr_data
	+vstore vreg_sprd + 5

; set up sprite #0 shape
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

	ldx #0

loop:	txa
	+vstore vreg_sprd
;	+vload vreg_sprd + 1
;	and #%11111100
;	ora #0
;	+vstore vreg_sprd + 1
	txa
	+vstore vreg_sprd + 2
	+vload vreg_sprd + 3
	and #%11111110
	+vstore vreg_sprd + 3

	lda #20
	ldy #0
delay:	dey
	bne delay
	sec
	sbc #1
	bne delay

	inx
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
!text ".*************.."
!text ".*****..******.."
!text "*****.**..*****."
!text "*****.*********."
!text "*****.**..*****."
!text ".*****..******.."
!text ".*************.."
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

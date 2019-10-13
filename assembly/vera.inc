; License: Public Domain

!if MACHINE_C64 = 1 {
	verareg =$df00
} else {
	verareg =$9f20
}
veralo  = verareg+0
veramid = verareg+1
verahi  = verareg+2
veradat = verareg+3
veradat2= verareg+4
veractl = verareg+5
veraien = verareg+6
veraisr = verareg+7

vreg_cmp  = $F0000
vreg_pal  = $F1000
vreg_lay1 = $F2000
vreg_lay2 = $F3000
vreg_spr  = $F4000
vreg_sprd = $F5000

AUTO_INC_1 = $100000

!macro vset .addr {
	lda #<(.addr >> 16) | $10
	sta verahi
	lda #<(.addr >> 8)
	sta veramid
	lda #<(.addr)
	sta veralo
}

!macro vstore .addr {
	pha
	+vset .addr
	pla
	sta veradat
}

!macro vload .addr {
	+vset .addr
	lda veradat
}

!macro sprset .offset {
	lda #<(vreg_sprd >> 16) | $10
	sta verahi
	txa
	lsr
	lsr
	lsr
	lsr
	lsr
	clc
	adc #<(vreg_sprd + .offset >> 8)
	sta veramid
	txa
	asl
	asl
	asl
	clc
	adc #<((vreg_sprd + .offset))
	sta veralo
}

!macro sprload .offset {
	+sprset .offset
	lda veradat
}

!macro sprstore .offset {
	pha
	+sprset .offset
	pla
	sta veradat
}

!macro video_init {
	lda #0
	sta veractl ; set ADDR1 active
	sta veramid
	lda #$1F    ; $F0000 increment 1
	sta verahi
	lda #$00
	sta veralo
	lda #1
	sta veradat ; VGA output
}

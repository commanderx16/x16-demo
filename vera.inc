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

vreg_lay1 = $40000
vreg_lay2 = $40010
vreg_spr  = $40020
vreg_cmp  = $40040
vreg_pal  = $40200
vreg_sprd = $40800

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

!macro video_init {
	lda #0
	sta veractl ; set ADDR1 active
	sta veramid
	lda #$14    ; $40040
	sta verahi
	lda #$40
	sta veralo
	lda #1
	sta veradat ; VGA output
}

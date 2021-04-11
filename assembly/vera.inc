; License: Public Domain

!if MACHINE_C64 = 1 {
	VERA_BASE = $DF00
} else {
	VERA_BASE = $9F20
}

VERA_ADDR_L       = (VERA_BASE + $00)
VERA_ADDR_M       = (VERA_BASE + $01)
VERA_ADDR_H       = (VERA_BASE + $02)
VERA_DATA0        = (VERA_BASE + $03)
VERA_DATA1        = (VERA_BASE + $04)
VERA_CTRL         = (VERA_BASE + $05)

VERA_IEN          = (VERA_BASE + $06)
VERA_ISR          = (VERA_BASE + $07)
VERA_IRQ_LINE_L   = (VERA_BASE + $08)

; DCSEL=0
VERA_DC_VIDEO     = (VERA_BASE + $09)
VERA_DC_HSCALE    = (VERA_BASE + $0A)
VERA_DC_VSCALE    = (VERA_BASE + $0B)
VERA_DC_BORDER    = (VERA_BASE + $0C)

; DCSEL=1
VERA_DC_HSTART    = (VERA_BASE + $09)
VERA_DC_HSTOP     = (VERA_BASE + $0A)
VERA_DC_VSTART    = (VERA_BASE + $0B)
VERA_DC_VSTOP     = (VERA_BASE + $0C)

VERA_L0_CONFIG    = (VERA_BASE + $0D)
VERA_L0_MAPBASE   = (VERA_BASE + $0E)
VERA_L0_TILEBASE  = (VERA_BASE + $0F)
VERA_L0_HSCROLL_L = (VERA_BASE + $10)
VERA_L0_HSCROLL_H = (VERA_BASE + $11)
VERA_L0_VSCROLL_L = (VERA_BASE + $12)
VERA_L0_VSCROLL_H = (VERA_BASE + $13)

VERA_L1_CONFIG    = (VERA_BASE + $14)
VERA_L1_MAPBASE   = (VERA_BASE + $15)
VERA_L1_TILEBASE  = (VERA_BASE + $16)
VERA_L1_HSCROLL_L = (VERA_BASE + $17)
VERA_L1_HSCROLL_H = (VERA_BASE + $18)
VERA_L1_VSCROLL_L = (VERA_BASE + $19)
VERA_L1_VSCROLL_H = (VERA_BASE + $1A)

VERA_AUDIO_CTRL   = (VERA_BASE + $1B)
VERA_AUDIO_RATE   = (VERA_BASE + $1C)
VERA_AUDIO_DATA   = (VERA_BASE + $1D)

VERA_SPI_DATA     = (VERA_BASE + $1E)
VERA_SPI_CTRL     = (VERA_BASE + $1F)

VERA_PSG_BASE     = $1F9C0
VERA_PALETTE_BASE = $1FA00
VERA_SPRITES_BASE = $1FC00

VERA_DATA = VERA_DATA0
VERA_AUTO_INC_1 = $100000

VERA_EN_LAYER0 = 1
VERA_EN_LAYER1 = 2
VERA_EN_SPRITE = 4

!macro vset .addr {
	lda #<(.addr >> 16)
	sta VERA_ADDR_H
	lda #<(.addr >> 8)
	sta VERA_ADDR_M
	lda #<(.addr)
	sta VERA_ADDR_L
}

!macro vstore .addr {
	pha
	+vset .addr
	pla
	sta VERA_DATA
}

!macro vload .addr {
	+vset .addr
	lda VERA_DATA
}

!macro sprset .offset {
	lda #<(VERA_SPRITES_BASE >> 16) | (.offset >> 16)
	sta VERA_ADDR_H
	txa
	!for I, 1, 5 { lsr }
	clc
	adc #<(VERA_SPRITES_BASE + .offset >> 8)
	sta VERA_ADDR_M
	txa
	!for I, 1, 3 { asl }
	clc
	adc #<(VERA_SPRITES_BASE + .offset)
	sta VERA_ADDR_L
}

!macro sprload .offset {
	+sprset .offset
	lda VERA_DATA
}

!macro sprstore .offset {
	pha
	+sprset .offset
	pla
	sta VERA_DATA
}

!macro video_init .layers {
	lda #0
	sta VERA_CTRL ; set ADDRSEL=0 and DCSEL=0
	lda #$01 | (.layers << 4) ; VGA
	sta VERA_DC_VIDEO
}

!macro video_overlay .layers {
	lda #0
	sta VERA_CTRL ; set ADDRSEL=0 and DCSEL=0
	; fetch already-enabled layers
	lda VERA_DC_VIDEO
	and #$70
	ora #$01 | (.layers << 4) ; VGA
	sta VERA_DC_VIDEO
}

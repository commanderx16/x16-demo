!ifdef VERA_INC !eof
VERA_INC=1

;=================================================
;=================================================
;
;   Memory-mapped registers
;
;-------------------------------------------------

!addr {
	!if MACHINE_C64 = 1 {
		VERA_base = $df00
	} else {
		VERA_base = $9f20
	}
	VERA_addr_low   = VERA_base+0
	VERA_addr_high  = VERA_base+1
	VERA_addr_bank  = VERA_base+2
	VERA_data       = VERA_base+3
	VERA_data2      = VERA_base+4
	VERA_ctrl       = VERA_base+5
	VERA_irq_ctrl   = VERA_base+6
	VERA_irq        = VERA_base+7

	VRAM_composer = $F0000
	VRAM_palette  = $F1000
	VRAM_layer1   = $F2000
	VRAM_layer2   = $F3000
	VRAM_sprinfo  = $F4000
	VRAM_sprdata  = $F5000

	VROM_petscii = $1F000
}

;=================================================
;=================================================
;
;   Macros
;
;-------------------------------------------------

;=================================================
; VERA_SELECT_ADDR
;   Select which address channel to configure (VERA_data vs. VERA_data2)
;-------------------------------------------------
; INPUTS:   .addr	0 for VERA_data
;					1 for VERA_data2
;
;-------------------------------------------------
; MODIFIES: A
; 
!macro VERA_SELECT_ADDR .addr {
	lda #.addr
	sta VERA_ctrl
}

;=================================================
; VERA_SET_ADDR (multiple)
;   Set the current address channel's address
;-------------------------------------------------
; INPUTS:   .addr			VRAM address to set to
;			[.stride = 1]	Address stride/auto-increment
;								value: 	increment
;									0: 	disabled
;									1: 	1 byte
;									2: 	2 byte
;									3: 	4 byte
;									4: 	8 byte
;									5: 	16 byte
;									6: 	32 byte
;									7: 	64 byte
;									8: 	128 byte
;									9: 	256 byte
;								   10: 	512 byte
;								   11: 	1024 byte
;								   12: 	2048 byte
;								   13: 	4096 byte
;								   14: 	8192 byte
;								   15: 	16384 byte
;
;-------------------------------------------------
; MODIFIES: A
; 
!macro VERA_SET_ADDR .addr, .stride {
	lda #<(.addr)
	sta VERA_addr_low
	lda #<(.addr >> 8)
	sta VERA_addr_high
	lda #<(.addr >> 16) | (.stride << 4)
	sta VERA_addr_bank
}

!macro VERA_SET_ADDR .addr {
	+VERA_SET_ADDR .addr, 1
}

;=================================================
; VERA_WRITE (multiple)
;   Write values to VERA_data.
;	If more than 8 values are needed, consider 
;	the SYS_STREAM_* family.
;-------------------------------------------------
; INPUTS:   .v0 - .v7	Values to write
;
;-------------------------------------------------
; MODIFIES: A
; 
!macro VERA_WRITE .v0 {
	lda #.v0
	sta VERA_data
}

!macro VERA_WRITE .v0, .v1 {
	+VERA_WRITE .v0
	+VERA_WRITE .v1
}

!macro VERA_WRITE .v0, .v1, .v2 {
	+VERA_WRITE .v0, .v1
	+VERA_WRITE .v2
}

!macro VERA_WRITE .v0, .v1, .v2, .v3 {
	+VERA_WRITE .v0, .v1
	+VERA_WRITE .v2, .v3
}

!macro VERA_WRITE .v0, .v1, .v2, .v3, .v4, .v5, .v6, .v7 {
	+VERA_WRITE .v0, .v1, .v2, .v3
	+VERA_WRITE .v4, .v5, .v6, .v7
}

;=================================================
; VPEEK
;   It's... VPEEK(), but in assembly.
;-------------------------------------------------
; INPUTS:   .addr	VRAM address to read from.
;
;-------------------------------------------------
; MODIFIES: A
; 
!macro VPEEK .addr {
	+VERA_SET_ADDR .addr
	lda VERA_data
}

;=================================================
; VERA_SET_SPRITE
;   Set the current address channel to target
;	an indexed sprite_data entry in VRAM_sprdata
;-------------------------------------------------
; INPUTS:   .sprite_index	Sprite index to target
;
;-------------------------------------------------
; MODIFIES: A
; 
!macro VERA_SET_SPRITE .sprite_index {
	+VERA_SET_ADDR (VRAM_sprdata + (.sprite_index << 3))
}

;=================================================
; VERA_SET_PALETTE
;   Set the current address channel to target
;	an indexed palette  entry in VRAM_palette
;-------------------------------------------------
; INPUTS:   .palette_index		Palette index to target
;			[.color_offset = 0]	Which color within the palette to target
;
;-------------------------------------------------
; MODIFIES: A
; 
!macro VERA_SET_PALETTE .palette_index {
	+VERA_SET_ADDR (VRAM_palette + (.palette_index << 5))
}

!macro VERA_SET_PALETTE .palette_index, .color_offset {
	+VERA_SET_ADDR (VRAM_palette + (.palette_index << 5) + (.color_offset << 1))
}

;=================================================
; VERA_RESET
;   Reset the Vera to its default settings.
;	See official documentation for specifics.
;-------------------------------------------------
; INPUTS:   (none)
;
;-------------------------------------------------
; MODIFIES: A
; 
!macro VERA_RESET {
	lda #$80
	sta VERA_ctrl
}

;=================================================
; VERA_END_IRQ
;   Reset the Vera IRQ flag so that it generates interrupts.
;-------------------------------------------------
; INPUTS:   (none)
;
;-------------------------------------------------
; MODIFIES: A
; 
!macro VERA_END_IRQ {
	lda #$1
	sta VERA_irq
}

;=================================================
; VIDEO_INIT
;   Turn on the video display.
;-------------------------------------------------
; INPUTS:   (none)
;
;-------------------------------------------------
; MODIFIES: A
; 
!macro VIDEO_INIT {
	lda #0
	sta VERA_ctrl ; set ADDR1 active
	sta VERA_addr_high
	lda #$14    ; $40040 - Composer output mode and chroma toggle
	sta VERA_addr_bank
	lda #$40
	sta VERA_addr_low
	lda #1
	sta VERA_data ; VGA output
}

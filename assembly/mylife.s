;
; mylife.s  v0.2
; codewar65
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

veralo          =       $9f20
veramid         =       veralo + 1
verahi          =       veralo + 2
veradata0       =       veralo + 3
veradata1       =       veralo + 4
veractrl        =       veralo + 5
veraien         =       veralo + 6
veraisr         =       veralo + 7

rambank         =     	$9f61		; ram bank number

; vectors, etc.

chrin           =       $ffe4

; zero page addresses

r0              =       $50             ; general purpose 'registers'.
 r0l            =       $50
 r0h            =       $51
r1              =       $52
 r1l            =       $52
 r1h            =       $53
r2              =       $54
 r2l            =       $54
 r2h            =       $55
r3              =       $56
 r3l            =       $56
 r3h            =       $57
r4              =       $58
 r4l            =       $58
 r4h            =       $59

curbank         =       $5a

dnw             =       $5b             ; bit data from sliding window
dn              =       $5c             ; of buffer data.
dne             =       $5d             ; (9 bytes total)
dw              =       $5e
d               =       $5f
de              =       $60
dsw             =       $61
ds              =       $62
dse             =       $63

                .org    $0801

                .byte   $0b,$08,$e3,$07 ; cx16 basic sys call.
                .byte   $9e,"2061"
                .byte   $00,$00,$00


                ldx     #<$f0001        ; display composer/hscale addr.
                ldy     #>$f0001
                lda     #^$f0001
                jsr     veraset
                lda     #$80
                sta     veradata0       ; reset hscale/vscale to 1:1.
                sta     veradata0
                ldx     #<$f2000        ; layer 0 off.
                ldy     #>$f2000
                lda     #^$f2000
                jsr     veraset
                stz     veradata0
                ldx     #<$f3000        ; layer 1 on.
                ldy     #>$f3000
                lda     #^$f3000
                jsr     veraset
                lda     #$01            ; mode 0, enabled
                sta     veradata0
                lda     #$06            ; 80x60
                sta     veradata0
                stz     veradata0       ; map = $0000
                stz     veradata0
                ldx     #<($f800 >> 2)  ; tiles = $f800
                ldy     #>($f800 >> 2)
                stx     veradata0
                sty     veradata0
                ldy     #59             ; clear screen 80x60 with $00,$0d.
                ldx     #$00
:               jsr     verasetxy       ; set row/col address.
                ldx     #80
:               stz     veradata0
                lda     #$0d            ; lt green on black.
                sta     veradata0
                dex
                bne     :-
                dey                     ; up a row, x already 0.
                bpl     :--
                ldx     #<$0f800        ; overwrite vera char tiles 0-15 for
                ldy     #>$0f800        ; easy access and speed.
                lda     #^$0f800
                jsr     veraset

                ldx     #<chrdef
                ldy     #>chrdef
                stx     r0l
                sty     r0h
                ldx     #<(chrdefend-chrdef)
                ldy     #>(chrdefend-chrdef)
                jsr     veralmov

                jsr     makelut         ; generate big lut in ram banks 0-7.

@mainloop:      sei
                ldx     #<buff0         ; send buff0 to screen.
                ldy     #>buff0
                jsr     buf2scr

                ldx     #<buff0         ; set source.
                ldy     #>buff0
                stx     r0l
                sty     r0h
                ldx     #<buff1         ; set destination.
                ldy     #>buff1
                stx     r1l
                sty     r1h
                jsr     generate

                ldx     #<buff1         ; send buff1 to screen.
                ldy     #>buff1
                jsr     buf2scr

                ldx     #<buff1         ; set source.
                ldy     #>buff1
                stx     r0l
                sty     r0h
                ldx     #<buff0         ; set destination.
                ldy     #>buff0
                stx     r1l
                sty     r1h
                jsr     generate
                cli

                jsr     chrin           ; loop until any key.
                ora     #$00
                beq     @mainloop
                rts


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; veralmov (large move) - write data to port 0.
;
; in:   r0=address, xy=len.
; out:  none.

veralmov:       cpx     #0              ; test for zero length.
                bne     @loop
                cpy     #0
                beq     @exit           ; nothing to move. exit.
@loop:          lda     (r0)            ; move byte
                sta     veradata0
                inc     r0l             ; next address
                bne     @declen
                inc     r0h
@declen:        dex                     ; decrease count.
                cpx     #$ff
                bne     veralmov
                dey
                bra     veralmov
@exit:          rts


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; makelut - generate look-up table in ram banks 0-7. index ($0000-$ffff) is
; the bit mask for all cells needed to compute the next cell.
;
;       -0-- 00-- 0---
;       -0-0 0000 0-0-  -> 0000
;       ---0 --00 --0-
;
;       nw | ne | sw | se       = 0000
;       c                       = 0000
;       w | e                   = 0000
;       n | s                   = 0000
;
;       ,___________________ >> 13 = ram bank
;       |||,________________ + $a000 = ram address
;       |||| |||| |||| ||||
;       0000 0000 0000 0000
;       |||| |||| |||| ||||_ c  1       this is the center 4 cells (a single
;       |||| |||| |||| |||__ c  2       characters on the screen)
;       |||| |||| |||| ||___ c  4
;       |||| |||| |||| |____ c  8
;       |||| |||| ||||______ sw 1
;       |||| |||| |||_______ se 2
;       |||| |||| ||________ nw 4
;       |||| |||| |_________ ne 8
;       |||| ||||___________ s  1
;       |||| |||____________ s  2
;       |||| ||_____________ n  4
;       |||| |______________ n  8
;       ||||________________ w  1
;       |||_________________ e  2
;       ||__________________ w  4
;       |___________________ e  8

makelut:        stz     r0l             ; count $0000 to $ffff
                stz     r0h
                stz     curbank         ; current ram bank.
                dec     curbank         ; set to $ff to force 1st set.

@mainloop:      stz     r2l             ; output for this index

                lda     r0l             ; neighbors around c8
                and     #%00010111      ; sw1,c4,c2,c1
                tax
                lda     hamlut, x
                sta     r1l
                lda     r0h
                and     #%01010011      ; w4,w1,s2,s1
                tax
                lda     hamlut, x
                clc
                adc     r1l
                tax                     ; x=neighbor count for c8
                lda     r0l
                and     #%00001000      ; check c8
                beq     @c8off
@c8on:          cpx     #2
                beq     @sc8
                cpx     #3
                beq     @sc8
@cc8:           clc
                bra     @set8
@c8off:         cpx     #3
                bne     @cc8
@sc8:           sec
@set8:          rol     r2l

                lda     r0l             ; neighbors around c4
                and     #%00101011      ; se2,c1,c2,c4
                tax
                lda     hamlut, x
                sta     r1l
                lda     r0h
                and     #%10100011      ; s1,s2,e8,e4
                tax
                lda     hamlut, x
                clc
                adc     r1l
                tax                     ; x=neighbor count for c4
                lda     r0l
                and     #%00000100      ; check c4
                beq     @c4off
@c4on:          cpx     #2
                beq     @sc4
                cpx     #3
                beq     @sc4
@cc4:           clc
                bra     @set4
@c4off:         cpx     #3
                bne     @cc4
@sc4:           sec
@set4:          rol     r2l

                lda     r0l             ; neighbors around c2
                and     #%01001101      ; nw4,c1,c4,c8
                tax
                lda     hamlut, x
                sta     r1l
                lda     r0h
                and     #%01011100      ; w1,w4,n8,n4
                tax
                lda     hamlut, x
                clc
                adc     r1l
                tax                     ; x=neighbor count for c2
                lda     r0l
                and     #%00000010      ; check c2
                beq     @c2off
@c2on:          cpx     #2
                beq     @sc2
                cpx     #3
                beq     @sc2
@cc2:           clc
                bra     @set2
@c2off:         cpx     #3
                bne     @cc2
@sc2:           sec
@set2:          rol     r2l

                lda     r0l             ; neighbors around c1
                and     #%10001110      ; ne8,c2,c4,c8
                tax
                lda     hamlut, x
                sta     r1l
                lda     r0h
                and     #%10101100      ; e8,e2,n4,n8
                tax
                lda     hamlut, x
                clc
                adc     r1l
                tax                     ; x=neighbor count for c1
                lda     r0l
                and     #%00000001      ; check c1
                beq     @c1off
@c1on:          cpx     #2
                beq     @sc1
                cpx     #3
                beq     @sc1
@cc1:           clc
                bra     @set1
@c1off:         cpx     #3
                bne     @cc1
@sc1:           sec
@set1:          rol     r2l

                ; index = r0, output byte = r2l
                lda     r0h             ; get bank number
                and     #$e0
                lsr     a
                lsr     a
                lsr     a
                lsr     a
                lsr     a
                cmp     curbank         ; current bank
                beq     :+              ; don't switch if same as last time.
                sta     curbank
                sta     rambank         ; switch ram bank (check address)
:               lda     r0h             ; r1 = $a000-$bfff
                and     #$1f
                ora     #$a0
                sta     r1h
                lda     r0l
                sta     r1l
                lda     r2l
                sta     (r1)

                inc     r0l
                bne     :+
                inc     r0h
                beq     :++
:               jmp     @mainloop
:               rts


; generate, r0=source, r1=destination
;
generate:       clc                     ; wrap around: copy first row to last
                lda     r0l             ; offscreen row
                adc     #83
                sta     r3l
                lda     r0h
                adc     #0
                sta     r3h
                clc
                lda     r0l
                adc     #<(82*61+1)
                sta     r4l
                lda     r0h
                adc     #>(82*61+1)
                sta     r4h
                ldy     #79
w1:             lda     (r3),y
                sta     (r4),y
                dey
                bpl     w1
                clc                     ; wrap around: copy last row to first
                lda     r0l             ; offscreen row.
                adc     #1
                sta     r3l
                lda     r0h
                adc     #0
                sta     r3h
                clc
                lda     r0l
                adc     #<(82*60+1)
                sta     r4l
                lda     r0h
                adc     #>(82*60+1)
                sta     r4h
                ldy     #79
w2:             lda     (r4),y
                sta     (r3),y
                dey
                bpl w2
                clc
                lda     r0l             ; wrap around: copy first column to
                adc     #82             ; last offscreen column and last column
                sta     r3l             ; to first offscreen column.
                lda     r0h
                adc     #0
                sta     r3h
                ldx     #60
w3:             ldy     #1
                lda     (r3),y
                ldy     #81
                sta     (r3),y
                ldy     #80
                lda     (r3),y
                ldy     #0
                sta     (r3),y
                clc
                lda     r3l
                adc     #82
                sta     r3l
                lda     r3h
                adc     #0
                sta     r3h
                dex
                bne     w3
                clc                     ; wrap around: 4 corners.
                lda     r0l
                adc     #<(82*60)
                sta     r4l
                lda     r0h
                adc     #>(82*60)
                sta     r4h
                ldy     #83
                lda     (r0),y
                ldy     #163
                sta     (r0),y
                ldy     #162
                lda     (r0),y
                ldy     #82
                sta     (r4),y
                ldy     #1
                lda     (r4),y
                ldy     #81
                sta     (r0),y
                ldy     #80
                lda     (r4),y
                ldy     #0
                sta     (r0),y

                clc                     ; r2=middle line addr
                lda     r0l
                adc     #82
                sta     r2l
                lda     r0h
                adc     #0
                sta     r2h
                clc                     ; r3=lower line addr
                lda     r0l
                adc     #164
                sta     r3l
                lda     r0h
                adc     #0
                sta     r3h
                clc
                lda     r1l             ; adj r1 to proper location
                adc     #82
                sta     r1l
                lda     r1h
                adc     #0
                sta     r1h
                ldx     #60
@lineloop:      ldy     #0

@charloop:      lda     (r0),y
                sta     dnw
                lda     (r2),y
                sta     dw
                lda     (r3),y
                sta     dsw
                iny
                lda     (r0),y
                sta     dn
                lda     (r2),y
                sta     d
                lda     (r3),y
                sta     ds
                iny
                lda     (r0),y
                sta     dne
                lda     (r2),y
                sta     de
                lda     (r3),y
                sta     dse
                dey

		; compute output byte based on data in dnw-dse
		lda     dne             ; r4 = index into banked ram
                and     #%1000
                sta     r4l
                lda     dnw
                and     #%0100
                ora     r4l
                sta     r4l
                lda     dse
                and     #%0010
                ora     r4l
                sta     r4l
                lda     dsw
                and     #%0001
                ora     r4l
		beq	:+
                asl     a
                asl     a
                asl     a
                asl     a
                sta     r4l
:               lda     d
                and     #%1111
                ora     r4l
                sta     r4l
                lda     de
                and     #%1010
                sta     r4h
                lda     dw
                and     #%0101
                ora     r4h
		beq	:+
                asl     a
                asl     a
                asl     a
                asl     a
                sta     r4h
:               lda     dn
                and     #%1100
                ora     r4h
                sta     r4h
                lda     ds
                and     #%0011
                ora     r4h
                sta     r4h
		
                lda     r4h             ; switch ram bank
                and     #$e0
                lsr     a
                lsr     a
                lsr     a
                lsr     a
                lsr     a
                cmp     curbank
                beq     :+
                sta     curbank
                sta     rambank
:               lda     r4h             ; adjust to $a000-$bfff
                and     #$1f
                ora     #$a0
                sta     r4h
                lda     (r4)            ; return new value.		
                sta     (r1),y          ; dnw-dse return in a.
                cpy     #80
		beq	:+
		jmp	@charloop
		
:		lda	r2l		; next line
		sta	r0l
		lda	r2h
		sta	r0h
		lda	r3l
		sta	r2l
		lda	r3h
		sta	r2h
                clc
                lda     r1l
                adc     #82
                sta     r1l 
                lda     r1h
                adc     #0
                sta     r1h
                clc
                lda     r3l
                adc     #82
                sta     r3l
                lda     r3h
                adc     #0
                sta     r3h

                dex
		beq	:+
		jmp	@lineloop
:		rts

; buf2scr - draw contents of buffer in x/y to screen.
;
buf2scr:        stx     r0l
                sty     r0h
                clc                     ; adjust to proper location
                lda     r0l
                adc     #83
                sta     r0l
                lda     r0h
                adc     #0
                sta     r0h
                ldy     #0
:               ldx     #0
                jsr     verasetxy2
:               lda     (r0)
                sta     veradata0
                inc     r0l
                bne     :+
                inc     r0h
:               inx
                cpx     #80
                bne     :--
                iny
                cpy     #60
                beq     :+
                clc
                lda     r0l
                adc     #2
                sta     r0l
                lda     r0h
                adc     #0
                sta     r0h
                bra     :---
:               rts

; set vera address to x/y (col/row).
verasetxy:      txa
                clc
                asl
                tax
                lda     #$00
                ; fallthrough to veraset

; save x/y/ainto veralo,veramid,verahi. $00 to veractrl. a is effected
veraset:        stx     veralo
                sty     veramid
                ora     #$10            ; increment 1
                sta     verahi
                stz     veractrl        ; port 0
                rts

; set vera address to x/y (col/row). with increment = 2
verasetxy2:     txa
                clc
                asl
                tax
                stx     veralo
                sty     veramid
                lda     #$20            ; increment 2
                sta     verahi
                stz     veractrl        ; port 0
                rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

buff0:		.res	(82*30)
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $e,$8,$7,$2,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $1,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0,$0,$0,$0,$0,$0,$0
                .byte   $0,$0
		.res	(82*30)
buff1:          .res    82*62

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

hamlut:         .byte   0,1,1,2,1,2,2,3 ; hammering weight lut. number of
                .byte   1,2,2,3,2,3,3,4 ; bits 'on' for values $00-$ff.
                .byte   1,2,2,3,2,3,3,4 ; (256 bytes)
                .byte   2,3,3,4,3,4,4,5
                .byte   1,2,2,3,2,3,3,4
                .byte   2,3,3,4,3,4,4,5
                .byte   2,3,3,4,3,4,4,5
                .byte   3,4,4,5,4,5,5,6
                .byte   1,2,2,3,2,3,3,4
                .byte   2,3,3,4,3,4,4,5
                .byte   2,3,3,4,3,4,4,5
                .byte   3,4,4,5,4,5,5,6
                .byte   2,3,3,4,3,4,4,5
                .byte   3,4,4,5,4,5,5,6
                .byte   3,4,4,5,4,5,5,6
                .byte   4,5,5,6,5,6,6,7
                .byte   1,2,2,3,2,3,3,4
                .byte   2,3,3,4,3,4,4,5
                .byte   2,3,3,4,3,4,4,5
                .byte   3,4,4,5,4,5,5,6
                .byte   2,3,3,4,3,4,4,5
                .byte   3,4,4,5,4,5,5,6
                .byte   3,4,4,5,4,5,5,6
                .byte   4,5,5,6,5,6,6,7
                .byte   2,3,3,4,3,4,4,5
                .byte   3,4,4,5,4,5,5,6
                .byte   3,4,4,5,4,5,5,6
                .byte   4,5,5,6,5,6,6,7
                .byte   3,4,4,5,4,5,5,6
                .byte   4,5,5,6,5,6,6,7
                .byte   4,5,5,6,5,6,6,7
                .byte   5,6,6,7,6,7,7,8

; character tile definitions. note: only characters 0-15 are used by this 
; program. the others are future use.
;
chrdef:         ; atari/namco grid set
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $0e,$0e,$0e,$00,$00,$00,$00,$00
                .byte   $e0,$e0,$e0,$00,$00,$00,$00,$00
                .byte   $ee,$ee,$ee,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$0e,$0e,$0e,$00
                .byte   $0e,$0e,$0e,$00,$0e,$0e,$0e,$00
                .byte   $e0,$e0,$e0,$00,$0e,$0e,$0e,$00
                .byte   $ee,$ee,$ee,$00,$0e,$0e,$0e,$00
                .byte   $00,$00,$00,$00,$e0,$e0,$e0,$00
                .byte   $0e,$0e,$0e,$00,$e0,$e0,$e0,$00
                .byte   $e0,$e0,$e0,$00,$e0,$e0,$e0,$00
                .byte   $ee,$ee,$ee,$00,$e0,$e0,$e0,$00
                .byte   $00,$00,$00,$00,$ee,$ee,$ee,$00
                .byte   $0e,$0e,$0e,$00,$ee,$ee,$ee,$00
                .byte   $e0,$e0,$e0,$00,$ee,$ee,$ee,$00
                .byte   $ee,$ee,$ee,$00,$ee,$ee,$ee,$00
                .byte   $00,$00,$00,$00,$00,$ff,$ff,$ff
                .byte   $ff,$ff,$ff,$00,$00,$00,$00,$00
                .byte   $07,$07,$07,$07,$07,$07,$07,$07
                .byte   $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
                .byte   $00,$00,$00,$00,$00,$01,$03,$07
                .byte   $00,$00,$00,$00,$00,$80,$c0,$e0
                .byte   $e0,$c0,$80,$00,$00,$00,$00,$00
                .byte   $07,$03,$01,$00,$00,$00,$00,$00
                .byte   $66,$33,$33,$33,$66,$cc,$cc,$cc
                .byte   $08,$0c,$fe,$ff,$fe,$0c,$08,$00
                .byte   $10,$30,$7f,$ff,$7f,$30,$10,$00
                .byte   $fe,$fe,$c6,$c6,$c6,$c6,$fe,$fe
                .byte   $00,$00,$00,$00,$00,$00,$fe,$fe
                .byte   $00,$7e,$7e,$66,$66,$7e,$7e,$00
                .byte   $00,$7e,$7e,$7e,$7e,$7e,$7e,$00
                .byte   $f0,$0f,$f0,$0f,$f0,$0f,$f0,$0f
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $1e,$1c,$38,$30,$00,$60,$60,$00
                .byte   $66,$cc,$88,$00,$00,$00,$00,$00
                .byte   $6c,$6c,$fe,$6c,$fe,$6c,$6c,$00
                .byte   $18,$3c,$60,$3c,$06,$7c,$18,$00
                .byte   $70,$76,$0c,$18,$30,$6e,$0e,$00
                .byte   $70,$d8,$d8,$70,$de,$cc,$7a,$00
                .byte   $30,$60,$40,$00,$00,$00,$00,$00
                .byte   $0c,$18,$30,$30,$30,$18,$0c,$00
                .byte   $30,$18,$0c,$0c,$0c,$18,$30,$00
                .byte   $02,$6c,$38,$fe,$38,$6c,$80,$00
                .byte   $00,$18,$18,$7e,$18,$18,$00,$00
                .byte   $00,$00,$00,$00,$00,$18,$18,$30
                .byte   $00,$00,$00,$7e,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$18,$18,$00
                .byte   $06,$0c,$18,$38,$30,$60,$e0,$00
                .byte   $38,$4c,$c6,$c6,$c6,$64,$38,$00
                .byte   $18,$38,$18,$18,$18,$18,$7e,$00
                .byte   $7c,$c6,$0e,$3c,$78,$c0,$fe,$00
                .byte   $7e,$0c,$18,$3c,$06,$c6,$7c,$00
                .byte   $1c,$3c,$6c,$cc,$fe,$0c,$0c,$00
                .byte   $fc,$c0,$fc,$06,$06,$c6,$7c,$00
                .byte   $3c,$60,$c0,$fc,$c6,$c6,$7c,$00
                .byte   $fe,$c6,$0c,$18,$30,$30,$30,$00
                .byte   $78,$c4,$e4,$78,$9e,$86,$7c,$00
                .byte   $7c,$c6,$c6,$7e,$06,$0c,$78,$00
                .byte   $00,$30,$30,$00,$30,$30,$00,$00
                .byte   $00,$30,$30,$00,$30,$30,$60,$00
                .byte   $00,$0e,$38,$e0,$38,$0e,$00,$00
                .byte   $00,$00,$fe,$00,$fe,$00,$00,$00
                .byte   $00,$e0,$38,$0e,$38,$e0,$00,$00
                .byte   $7c,$c6,$0e,$18,$00,$30,$30,$00
                .byte   $3c,$46,$de,$de,$cc,$60,$3c,$00
                .byte   $38,$6c,$c6,$c6,$fe,$c6,$c6,$00
                .byte   $fc,$c6,$c6,$fc,$c6,$c6,$fc,$00
                .byte   $3c,$66,$c0,$c0,$c0,$66,$3c,$00
                .byte   $f8,$cc,$c6,$c6,$c6,$cc,$f8,$00
                .byte   $fc,$c0,$c0,$f8,$c0,$c0,$fe,$00
                .byte   $fe,$c0,$c0,$fc,$c0,$c0,$c0,$00
                .byte   $3e,$60,$c0,$ce,$c6,$66,$3e,$00
                .byte   $c6,$c6,$c6,$fe,$c6,$c6,$c6,$00
                .byte   $7e,$18,$18,$18,$18,$18,$7e,$00
                .byte   $06,$06,$06,$06,$06,$c6,$7c,$00
                .byte   $c6,$cc,$d8,$f0,$f8,$dc,$ce,$00
                .byte   $60,$60,$60,$60,$60,$60,$7e,$00 ; L
                .byte   $c6,$ee,$fe,$fe,$d6,$c6,$c6,$00
                .byte   $c6,$e6,$f6,$fe,$de,$ce,$c6,$00
                .byte   $7c,$c6,$c6,$c6,$c6,$c6,$7c,$00
                .byte   $fc,$c6,$c6,$c6,$fc,$c0,$c0,$00
                .byte   $7c,$c6,$c6,$c6,$de,$cc,$7a,$00
                .byte   $fc,$c6,$c6,$ce,$f8,$dc,$ce,$00
                .byte   $78,$cc,$c0,$7c,$06,$c6,$7c,$00
                .byte   $7e,$18,$18,$18,$18,$18,$18,$00
                .byte   $c6,$c6,$c6,$c6,$c6,$c6,$7c,$00
                .byte   $c6,$c6,$c6,$c6,$6c,$38,$10,$00
                .byte   $c6,$c6,$d6,$fe,$fe,$ee,$c6,$00
                .byte   $c6,$ee,$7c,$38,$7c,$ee,$c6,$00
                .byte   $66,$66,$66,$3c,$18,$18,$18,$00
                .byte   $fe,$0e,$1c,$38,$70,$e0,$fe,$00
                .byte   $3c,$30,$30,$30,$30,$30,$3c,$00
                .byte   $c0,$60,$30,$38,$18,$0c,$0e,$00
                .byte   $78,$18,$18,$18,$18,$18,$78,$00
                .byte   $10,$38,$6c,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$fe
                .byte   $30,$18,$08,$00,$00,$00,$00,$00
                .byte   $00,$00,$3c,$06,$7e,$c6,$7a,$00
                .byte   $c0,$c0,$dc,$e6,$c6,$c6,$fc,$00
                .byte   $00,$00,$7c,$c6,$c0,$c2,$7c,$00
                .byte   $06,$06,$7e,$c6,$c6,$c6,$7a,$00
                .byte   $00,$00,$7c,$c6,$fe,$c0,$7c,$00
                .byte   $1c,$30,$7c,$30,$30,$30,$30,$00
                .byte   $00,$00,$7e,$c6,$ce,$76,$06,$7c
                .byte   $c0,$c0,$dc,$e6,$c6,$c6,$c6,$00
                .byte   $18,$00,$38,$18,$18,$18,$3c,$00
                .byte   $0c,$00,$1c,$0c,$0c,$0c,$0c,$78
                .byte   $c0,$c0,$c6,$cc,$f8,$cc,$c6,$00
                .byte   $38,$18,$18,$18,$18,$18,$18,$00
                .byte   $00,$00,$ac,$fe,$d6,$d6,$c6,$00
                .byte   $00,$00,$bc,$c6,$c6,$c6,$c6,$00
                .byte   $00,$00,$7c,$c6,$c6,$c6,$7c,$00
                .byte   $00,$00,$dc,$e6,$c6,$c6,$fc,$c0
                .byte   $00,$00,$7e,$c6,$c6,$ce,$76,$06
                .byte   $00,$00,$dc,$e6,$c0,$c0,$c0,$00
                .byte   $00,$00,$7c,$c0,$7c,$06,$fc,$00
                .byte   $10,$30,$7c,$30,$30,$30,$1c,$00
                .byte   $00,$00,$c6,$c6,$c6,$c6,$7a,$00
                .byte   $00,$00,$c6,$c6,$6c,$38,$10,$00
                .byte   $00,$00,$c6,$d6,$d6,$fe,$6c,$00
                .byte   $00,$00,$c6,$6c,$38,$6c,$c6,$00
                .byte   $00,$00,$c6,$c6,$ce,$76,$06,$7c
                .byte   $00,$00,$fe,$0c,$38,$60,$fe,$00
                .byte   $1e,$38,$18,$70,$18,$38,$1e,$00
                .byte   $18,$18,$18,$18,$18,$18,$18,$00
                .byte   $78,$1c,$18,$0e,$18,$1c,$78,$00
                .byte   $72,$dc,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$03,$0f,$1f,$3f,$3f,$7f,$7f
                .byte   $fe,$ff,$ff,$ff,$ff,$ff,$81,$00
                .byte   $00,$80,$e0,$e0,$c0,$80,$00,$00
                .byte   $fe,$fc,$fc,$fc,$fc,$fc,$fe,$7f
                .byte   $00,$01,$03,$07,$03,$01,$00,$01
                .byte   $80,$c0,$e0,$f0,$f8,$fc,$fe,$fe
                .byte   $7f,$3f,$3f,$1f,$0f,$03,$00,$00
                .byte   $83,$ff,$ff,$ff,$ff,$ff,$fe,$00
                .byte   $fc,$f8,$f8,$f0,$e0,$80,$00,$00
                .byte   $73,$84,$b4,$b4,$94,$f7,$73,$00
                .byte   $39,$a5,$bd,$b9,$a5,$bd,$39,$00
                .byte   $0e,$04,$04,$04,$04,$ee,$ee,$00
                .byte   $90,$90,$d0,$f0,$f0,$b0,$90,$00
                .byte   $77,$82,$e2,$72,$12,$f2,$e2,$00
                .byte   $4b,$4a,$4a,$4a,$4a,$7b,$33,$00
                .byte   $9c,$49,$49,$49,$49,$dd,$9c,$00
                .byte   $c0,$20,$20,$20,$20,$e0,$c0,$00
                .byte   $7c,$e6,$ce,$ce,$e6,$7c,$00,$00
                .byte   $00,$7e,$e0,$e0,$e0,$fe,$7e,$00
                .byte   $00,$7c,$e6,$e6,$e6,$fe,$7c,$00
                .byte   $06,$7e,$e6,$e6,$e6,$fe,$7e,$00
                .byte   $00,$7c,$c6,$fe,$c0,$fe,$7e,$00
                .byte   $00,$db,$db,$db,$db,$ff,$7e,$00
                .byte   $00,$3e,$03,$3f,$73,$7f,$3f,$00
                .byte   $00,$7c,$76,$76,$70,$70,$70,$00
                .byte   $3c,$60,$fc,$e6,$e6,$fe,$7c,$00
                .byte   $fc,$e0,$fc,$06,$06,$7e,$7c,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
                .byte   $00,$00,$00,$00,$00,$00,$00,$00
chrdefend:

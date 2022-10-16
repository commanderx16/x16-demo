; Zero Page Addresses
; Reserved by X16 Kernel
RESERVED: .res $22

SPEED: .byte 0
VBLANK_SKIP_COUNT: .byte 0   ; Count of current VBLANK skip
NOTE_NOTE: .byte 0
NOTE_OCTAVE: .byte 0
NOTE_NUMERIC: .byte 0
PATTERN_NUMBER: .byte 0
ROW_NUMBER: .byte 0
CHANNEL_NUMBER: .byte 0
ORDER_NUMBER: .byte 0
SCROLL_ENABLE: .byte 0

; Channel to start when displaying the pattern on screen
START_CHANNEL: .byte 0

; Track the state of the tracker engine
; 0 = Stopped
; 1 = Playing
STATE: .byte 0

ROW_POINTER: .word $0000           ; 16-bit address of the row in the pattern
; Basically just A000
PATTERN_POINTER: .word $0000
STRING_POINTER: .word $0000
PREVIOUS_ISR_HANDLER: .word $0000


TMP1: .byte $00
TMP2: .byte $00
TMP3: .byte $00
TMP4: .byte $00
;TMP5: .byte $00
;TMP6: .byte $00

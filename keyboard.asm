_8255_port_A = $e000
_8255_port_B = $e001
_8255_port_C = $e002
_8255_ctrl   = $e003
_8253_ch0    = $e004
_8253_ch1    = $e005
_8253_ch2    = $e006
_8253_ctrl   = $e007

; Only read up, down, left, right, ctrl and shift
keyboard:
.update:
    ; key dirs are bits 2 to 5 of the 7th strobe
    ld hl, _8255_port_A
    ld (hl), 0x07

    inc hl              ; on to port B
    ld a, (hl)
    and 0x3c
    ld b, a

    ; shift and ctrl are on bits 0 and 6 of the 8th strobe 
    dec hl              ; back to port A
    ld (hl), 0x08

    inc hl              ; and yep, port B
    ld a, (hl)
    and 0x41
    or b                ; mix keys
    ld b, a
.current equ $+1
    xor 0xff

    ld hl, .current
    ld (hl), b

; [todo] store trig?
    ret

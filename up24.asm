; [todo] bounce

    org #1200

SCREEN_WIDTH = 40
SCREEN_HEIGHT = 25

hblnk = 0xe008
vblnk = 0xe002

FRAME_DELAY = 5

    macro wait_vbl
        ; wait for vblank    
        ld hl, vblnk
        ld a, 0x7f
.wait0:
        cp (hl)
        jp nc, .wait0
.wait1:
        cp (hl)
        jp c, .wait1
    endm

main:
        di
        im 1

        xor a

        out (0xe0), a                               ; allocates RAM to $0000-$0fff
                                                    ; the monitor will be unavailable and all the IRQ jump addresses
                                                    ; are right in the area where the frame are unpacked...

        call copy_line.init

        ld a, 5
        ld (load_next_frame.id), a
        ld (load_next_frame.last), a

        call copy_banner.init

        ld a, 0x11                                      ; Fill the RAM "framebuffer" with blue
        ld hl, 0x0040
        ld (hl), a
        ld de, 0x0041
        ld bc, (SCREEN_WIDTH*SCREEN_HEIGHT*2)-1
        ldir

        ld hl, 0xe008                               ; sound off
        ld (hl), 0x00

        ld hl, song
        xor a
        call PLY_LW_Init

.intro_run:
        ld hl, welcome
        ld de, 0x0040
        call DecompressZX0v1
        call 0x840     
.intro_loop:
        wait_vbl
        call PLY_LW_Play

        ld hl, 0xe000
        ld (hl), 0xf6 
        inc hl
        bit 4,(hl)
        jp nz, .intro_loop
.start:


        ld hl, irq_call
        ld de, 0x0038
        ld bc, 3
        ldir

        ld hl, 0xe007                               ;Counter 2.
        ld (hl), 0xb0
        dec hl
        ld (hl),1
        ld (hl),0

        ld hl, 0xe007                               ; 100 Hz (plays the music at 50hz).
        ld (hl), 0x74
        ld hl, 0xe005
        ld (hl), 156
        ld (hl), 0

        ld hl, 0xe008
        ld (hl), 0x01                               ; sound on

        ei
    macro falling_block table, source
.bar:
        ld hl, source
        ld (draw_banner.s0), hl
        ld (draw_banner.s1), hl
.loop:
.ybar = $+1
        ld l, 0
        ld h, high table
        ld a, (hl)

        ld hl, .ybar
        inc (hl)
        jp z, .exit

        call draw_banner

        wait_vbl

        call draw_banner.clean

        jp .loop
.exit:
        call draw_banner
    endm

.stripe_i = $+1
        ld a, 0xFF
        inc a
        cp 3
        jr nz, .skip
                xor a
.skip:
        ld (.stripe_i), a
        add a, a
        ld c, a
        ld b, 0
        ld hl, stripes
        add hl, bc
        ld e, (hl)
        inc hl
        ld d, (hl)
        ex de, hl
        ld de, scratch
        call DecompressZX0v1

        wait_vbl

        ld hl, 0x0040-(2*8*40)
        ld (draw_banner.s2), hl

        falling_block bounce0, scratch+32*40+80
        falling_block bounce1, scratch+16*40+80
        falling_block bounce2, scratch+80

        ld hl, frame_0
        ld de, 0x0040
        call DecompressZX0v1

        ld hl, scratch-(2*8*40)
        ld (draw_banner.s2), hl

        falling_block bounce0, 0x0040+32*40+80
        falling_block bounce1, 0x0040+16*40+80
        falling_block bounce2, 0x0040+80

        ld a, 80
        ld (frame_count), a

loop:
        call load_next_frame

        call 0x840                                  ; copy frame to VRAM

        ld b, FRAME_DELAY
.l0:
        wait_vbl
        djnz .l0

        ld hl, frame_count
        dec (hl)
        jp nz, loop

        jp main.start

frame_count defb 140

;----------------------------------------------------------------------------------------------------------------------
;
load_next_frame:
.id equ $+1
        ld    e, 1

        xor   a                                 ; fetch next compressed frame
        ld    d, a
        
        ld    hl, frame.lo
        add   hl, de
        ld    a, (hl)
        ld    (.src), a

        ld    hl, frame.hi
        add   hl, de
        ld    a, (hl)
        ld    (.src+1), a                       ; frame_src += frame[b]

        dec   e
        jp    p, .go
.last equ $+1
            ld e, 5
.go:
        ld a, e
        ld (load_next_frame.id), a

.src equ $+1
        ld hl, frame_0
        ld de, 0x0040
        call DecompressZX0v1

        ret

;----------------------------------------------------------------------------------------------------------------------
;
load_frame:                                     ; load a single frame
        push bc
        ld de, 0x0040
        call DecompressZX0v1                    ; unpack frame
        wait_vbl                                ; wait for vblnk
        call 0x840                              ; copy frame to VRAM
        pop bc
        ret

;----------------------------------------------------------------------------------------------------------------------
;
copy_line.init:
        ; the unpacked frame is stored from 0x0000 to 0x07d0
        ; the copy to vram routine is stored from 0x0800 to 0x0e12
                                                    ; setup vram copy routine to RAM
        ld hl, copy_line                            ; d000
        ld de, 0x840
        ld bc, copy_line.end - copy_line
        ldir

        ld ix, 0xd000+10
        ld iy, 0xd800+10
        ld (copy_line.begin+2), iy
        ld hl, copy_line.begin                      ; d800
        ld bc, copy_line.end - copy_line.begin
        ldir

        ld a, 24
.l1:
                ld bc, 40
                add ix, bc
                add iy, bc

                ld (copy_line.begin+2), ix
                ld hl, copy_line.begin                  ; d000
                ld bc, copy_line.end - copy_line.begin
                ldir

                ld (copy_line.begin+2), iy
                ld hl, copy_line.begin                  ; d800
                ld bc, copy_line.end - copy_line.begin
                ldir

                dec a
                jp nz, .l1

        ld hl, copy_line.end                        ; copy stack pointer backup and return
        ld bc, 4
        ldir

        ret

;----------------------------------------------------------------------------------------------------------------------
; copy a line from 0x0000-0xffff to VRAM (char or color)
copy_line:
        ld ix, 0x0040                   ; [todo]
.begin: 
        ld iy, 0xd000+10
.start:
        ld b, 4
.l0:
        di
        ld sp, ix
    
        pop hl
        pop de
        exx
        pop hl
        pop bc
        pop de
    
        ld sp, iy
        push de
        push bc
        push hl
        exx
        push de
        push hl
.out=$+1
        ld sp, 0x10ee
        ei

        ld de,  10
        add iy, de
        add ix, de

        djnz .l0
.end:                                           ; we can hardcode stack return address
        ret
;----------------------------------------------------------------------------------------------------------------------
;
draw_banner:
        cp 8
        jp nc, .full

        ld hl, 8*40
        ld (.src), hl

        ld e, a
        ld a, 8
        sub e           ; a = 8-a
        add a, a        ; 2*a
        add a, a        ; 4*a
        add a, a        ; 8*a
        ld l, a
        ld h, 0
        ld b, h
        add hl, hl      ; 16*a
        add hl, hl      ; 32*a
        ld c, a
        add hl, bc      ; 32*a + 8*a = 40*a
        add hl, hl      ; 80*a 

        ex de, hl
         
        ld a, l
        ld (.previous), a
.s0 = $+2
        ld ix, scratch
        add ix, de
        ld iy, 0xd000+10
        ld (.dst), iy
        jp copy_banner

.full:
        add a, a        ; 2*a
        add a, a        ; 4*a
        add a, a        ; 8*a
        ld l, a
        ld h, 0
        ld b, h
        add hl, hl      ; 16*a
        add hl, hl      ; 32*a
        ld c, a
        add hl, bc      ; 32*a + 8*a = 40*a
        ld (.src), hl
        
        ex de, hl

        ld iy, 0xceca   ; 0xd000+10-(8*40)
        add iy, de
        ld (.dst), iy
.s1 = $+2
        ld ix, scratch
        ld a, 8
        ld (.previous), a
        jp copy_banner

.clean:
.dst = $+2
        ld iy, 0xd000+10
.src = $+1
        ld de, 0x0000
        add de, de
.s2 = $+2
        ld ix,  0x0040-(2*8*40)
        add ix, de
.previous = $+1
        ld a, 1
        jp copy_banner

;----------------------------------------------------------------------------------------------------------------------
;
copy_banner.init:
        ld de, banner

        ld a, 8
.loop:
        ld hl, copy_line.start                      ; d000
        ld bc, copy_line.end - copy_line.start
        ldir

        ld hl, .color
        ld bc, .color_size
        ldir

        ld hl, copy_line.start                      ; d800
        ld bc, copy_line.end - copy_line.start
        ldir

        ld hl, .next_line
        ld bc, .next_line_size
        ldir

        dec a
        jp nz, .loop

        ld hl, copy_line.end                        ; copy stack pointer backup and return
        ld bc, 4
        ldir

        ret
.color:
        ld de, 0x800-40
        add iy, de
.color_size = $ - .color

.next_line:
        ld de, 0xF800 ; -800
        add iy, de
.next_line_size = $ - .next_line

copy_banner.offset = .next_line_size + .color_size + 2*(copy_line.end - copy_line.start)

;----------------------------------------------------------------------------------------------------------------------
; ix: RAM sources
; iy: VRAM dest (0: 0xd000+10)
;  a: line count
copy_banner:
    ld b, a
    add a, b
    add a, b
    ld ($+4), a
    jr $

    DUP 9, i
    jp banner+(copy_banner.offset*(8-i))
    EDUP
;----------------------------------------------------------------------------------------------------------------------
irq_call:
    jp _irq_vector
_irq_vector:                                    ; timer irq vector.
    di

    push af                                     ; ... this makes santa sad...
    push hl
    push bc
    push de
    push ix
    push iy
;    exx
;    push af
;    push hl
;    push bc
;    push de
;    push ix
;    push iy
    
    ld hl, 0xe006
    ld a,1
    ld (hl), a
    xor a
    ld (hl), a
    
    call PLY_LW_Play
    
;    pop iy
;    pop ix
;    pop de
;    pop bc
;    pop hl
;    pop af
;    exx
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af

    ei

    reti

        include "externals/unzx0v1_fast.asm"
        include "externals/PlayerLightweight_SHARPMZ700.asm"

        include "data/music_playerconfig.asm"
song: 
        include "data/music.asm"

        include "keyboard.asm"

frame_0: 
    incbin "_data/anim/Frame_1.bin.zx0"
frame_1: 
    incbin "_data/anim/Frame_2.bin.zx0"
frame_2: 
    incbin "_data/anim/Frame_3.bin.zx0"
frame_3: 
    incbin "_data/anim/Frame_4.bin.zx0"
frame_4: 
    incbin "_data/anim/Frame_5.bin.zx0"
frame_5: 
    incbin "_data/anim/Frame_6.bin.zx0"

frame.lo:
    defb low frame_5
    defb low frame_4
    defb low frame_3
    defb low frame_2
    defb low frame_1
    defb low frame_0
frame.hi:
    defb high frame_5
    defb high frame_4
    defb high frame_3
    defb high frame_2
    defb high frame_1
    defb high frame_0

        ALIGN 256
bounce: 
bounce0: 
        incbin "bounce0.bin"
bounce1: 
        incbin "bounce1.bin"
bounce2: 
        incbin "bounce2.bin"

stripes:
        defw stripes.0, stripes.1, stripes.2
stripes.0:
        incbin "_data/stripes/Frame_1.bin.zx0"
stripes.1:
        incbin "_data/stripes/Frame_2.bin.zx0"
stripes.2:
        incbin "_data/stripes/Frame_3.bin.zx0"
scratch=$
banner=$+40*25*2
welcome:
        incbin "_data/welcome/Frame_1.bin.zx0"

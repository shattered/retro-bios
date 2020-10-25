;
;L.Yadrennikov (RCgoff) disassembly of ES1840.C000 keyboard firmware
;The target is to fix the bug: on software reset from PC, if the keyb was in LAT mode before,
;nor RUS, nor LAT leds won't on. See 'ledinit:' label.
;
;port 1 bit 0 - KBD CLK in
;port 1 bit 1 - KBD DATA in
;port 1 bit 5 - RUS led
;port 1 bit 6 - LAT led
;port 1 bit 7 - NUM led
;
;port 2 bit 0 - k155id3 (col decoder) "enable" (active low)
;port 2 bit 1 - KBD CLK out
;port 2 bit 2 - KBD DATA out
;
;BUS bits 0..3 - k155id3 (col decoder 4x16)
;BUS bits 4..6 - addr mux (row decoder)
;
;T0 - disable halt on POST failures
;T1 (pin 39) - return from addr mux
;
;all other port and test pins are free (by circuit diagrams)
; 
;CLK and DATA are buffered (555lp8) but logic is fully indentical as if they're not.
;
;
;RAM map:
; 01bh - alias address of r3' (in bank 1) 
; 01ch...02bh - keyboard map (16 bytes maps 128 possible keys; each byte corresponds to 8 keys).
;               See KEYMAP routine at 0x130.
; 02ch...03fh - scancode FIFO buffer. 02ch is the top and outputs first. 20 symbols
;
;flags (in normal mode):       //during POST flags are used in different way
;   f0 means "typematic on":
;      typematic timer start sets f0;
;      every MAKE writing to buffer clears f0;
;      typematic off by BREAK clears f0.       
;   f1 means "non-empty FIFO buffer":
;      output one code to PC occurs only if F1=1;
;      when buffer is empty after output F1:=0;
;      when code is placed to buffer and F1 was 0, it set to 1.
;
;registers:
;   r2 bank 0 - bit 0 - num lock status
;   r6 bank 0 stores typematic keynum which will be out when timer overflow
;   r3' bank 1 - typematic long delay
;
;There are 2 typematic delays:
; -(long, r3'=30h) interval after first make: only if this interval expired and make yet exists, typematic ON
; -(short r2'=04h) interval between typematic generations 
;
;
;  8048 Disassembly of es1841kb.bin
;  8/24/2020 10:31
;
       org     0                        
; 
X0000: clr     f0 
       stop    tcnt 
       jtf     pg0chk                  ;clear timer flag 
       jmp     pg0chk 
; 
       org     7
; 
fartmr:        sel     rb1 
       jmp     tmr
;
;ROM page 0 checksum check 
pg0chk:        clr     f1 
       clr     a 
       mov     r6,a 
       mov     r7,a 
p0loop:        movp    a,@a 
       add     a,r6 
       mov     r6,a 
       inc     r7 
       mov     a,r7 
       jnz     p0loop 
       jmp     pg1chk                  ;256bytes summed ->page 1 
;
;---------------------------------set power-on status of LEDs   
ledinit: 
       anl     p1,#3fh                 ;0b0011.1111 - bit 5=1, bit 5=RUS led 
       jmp     scanloop
; 
       org     1eh 
; 
farchk_reset: 
       jmp     chk_reset 
; 
scanloop: 
       orl     p2,#3                   ;dc disable, read mode of interface 
       in      a,p1 
       cpl     a 
       jb0     farchk_reset 
       jf1     chk_out_ready 
chk_out_ret: 
       jtf     fartmr 
tmr_ret: 
       inc     r7 
       mov     a,r7 
       jb7     scan_from0              ;was 128 keys scanned? yes - scan from beginning 
       jmp     scan_contin             ;no - continue scan 
; ; 
scan_from0:
       mov     r7,#1                   ;scan beginning 
scan_contin: 
       mov     a,r7 
       outl    bus,a 
       anl     p2,#42h                 ;dc enable (bit 0:=0) 
       mov     a,r7 
       mov     r1,a                    ;keynum in r1 and acc 
       jnt1    k_make                  ;is key MAKE? 
       call    keymap                  ;no - test for BREAK: get map position... 
       mov     a,@r1                   ;...read appropriate byte... 
       anl     a,r5                    ;and compare it with bit index. 
                                       ;if key was BREAK, bit index and keymap bit... 
                                       ;will be both 1 (key was pressed before)... 
                                       ;and AND reslt won't be 0. 
       jnz     k_break                 ;is key BREAK? 
       mov     a,r7                    ;no - untouched key - compare typematic and keynum 
                                       ;note that after one-shot MAKE keymap will not change! only keynum in r6 will show this. 
                                       ;so we can get there if we had one MAKE and then BREAK, 
                                       ;or if we BREAK key previously held by typematic. 
       xrl     a,r6                    ;compare typematic and keynum //after startup typematic r6=0 
       jnz     scanloop                ;r6 <> keynum -> continue scan
       stop    tcnt                    ;else, switch typematic off by BREAK:
       clr     f0                      ;timer stop, f0:=0,
       mov     r0,#1bh                 ;clear r3' (at bank 1),
       clr     a
       mov     @r0,a
clr_r6:        mov     r6,#0                   ;clear typematic reg,
       jmp     brk_bit                 ;generate BREAK scancode on former typematic keynum.
;
       org     50h
;
k_break:
       mov     r4,#0ffh
       djnz    r4,$-1
       mov     r4,#0ffh
       djnz    r4,$-1
       mov     r4,#0ffh
       djnz    r4,$-1                  ;debounce
       jnt1    scanloop                ;BREAK yet? no - return to scan from the next key
                                       ;keymap position caculated already: r5 has byte, r1 has address
       mov     a,@r1                   ;once again read byte
                                       ;key was break, so we must set bit to 0, this will be done
                                       ;by XOR: if key was '1', 1xor1=0 //why not 'or'???
       xrl     a,r5                    ;set to 0
       mov     @r1,a                   ;write to keymap
       mov     a,r7
       xrl     a,r6                    ;compare keynum with typematic
       jz      clr_r6                  ;if equal -> clear typematic reg
brk_bit:                               ;generate BREAK scancode
       mov     a,r7
       orl     a,#80h
       mov     r3,a
       jmp     get_scode
;
k_make:        mov     r4,#0ffh
       djnz    r4,$-1
       mov     r4,#0ffh
       djnz    r4,$-1
       mov     r4,#0ffh
       djnz    r4,$-1                  ;debounce
       jt1     scanloop                ;MAKE yet? no - return to scan from the next key
       call    keymap                  ;calculate keymap position (r1 stores keynum already)
       mov     a,@r1                   ;read appropriate byte
       anl     a,r5                    ;was this key MAKE before? (in table)
       nop                             ;???????
       jnz     scanloop                ;yes - return to scan from the next key, typematic will do output job
       mov     a,r6                    ;no - take a look to previous MAKE code
       jz      frst_make               ;first MAKE after startup->just put to buf and save in r6
       xrl     a,r7                    ;compare r6 (typemat) and keynum
       jz      typemat_on              ;typemat=keynum-> switch typematic on (if already not)
       stop    tcnt                    ;typemat<>keynum-> switch typematic off - by another keypress...
       mov     a,r6
       mov     r1,a
       call    keymap                  ;..calculate keymap position for r6 (former typematic)...
       mov     a,@r1
       orl     a,r5
       mov     @r1,a                   ;...and write 1 in keymap for former typematic (r6) key.
                                       ;during typematic output, keymap isn't changed. only when exit from typematic
frst_make:
       mov     r0,#1bh
       clr     a
       mov     @r0,a                   ;clear typematic long delay counter @1bh (r3 in bank 1)
       jmp     make_scode              ;copy keynum to r6 and put in FIFO buf
;
;
;---------------------------here we are after make_scode or get_scode, with scancode in r3 and buffer-top-adr in r0
;------buffer placement maintenance
bufadr:        mov     a,@r0
       jz      bufwrt                  ;current buffer code=0? yes - place scancode here
       mov     a,r0                    ;no, get curbuff
       xrl     a,#3fh                  ;check if boundary achieved
       jz      scanloop                ;achieved - throw code away and return to scan
       inc     r0                      ;no - next buff addr
       jmp     bufadr
;
bufwrt:        mov     a,r3                    ;place code to buffer...
       mov     @r0,a
       jf1     scanloop
       cpl     f1
       jmp     scanloop                ;...set f1=1 and return to main scan loop
;
typemat_on:
       jf0     scanloop                ;typematic timer start? f0=1 - typematic already on, return
       clr     a
       mov     t,a
       strt    t
       cpl     f0
       jmp     scanloop                ;set f0=1, start tmr and return to main scan loop 
; 
       org     0afh 
; 
farled:        jmp     led 
; 
       org     0b3h 
;--------------------------output to PC routine 
; 
pc_out:        anl     p2,#0a5h 
       mov     r4,#7                   ;r4 is bit counter in byte 
       orl     p2,#0c3h                ;0b1100.0011 - raise 7,6,1,0
                       ;symbol out loop 
newbit:        mov     a,r5                    ;symbol to out stored in r5 
       jb0     out_1 
                       ;bit=0 
       anl     p2,#81h                 ;0b1000.0001 
       orl     p2,#0c3h                ;0b1100.0011 - 0->1 in bits 6,2 
pc_sft:        mov     a,r4 
       jz      stop_cond 
       dec     r4 
       mov     a,r5 
       rr      a 
       mov     r5,a 
       jmp     newbit 
                       ;bit=1 
out_1: orl     p2,#0a5h                ;0b1010.0101 
       anl     p2,#0a5h                ;0b1010.0101 - bits 3,1 
       orl     p2,#0e7h                ;0b1110.1000 - 0->1 in bits 6,4 
       jmp     pc_sft 
; 
;here we are after 8 bit output 
stop_cond:                             ;stop conditions on interface 
       orl     p2,#0a5h 
       anl     p2,#0a5h 
       orl     p2,#0e7h 
       anl     p2,#0c3h
;
;buffer shift maintentance 
;shift all entries down on 1 position 
       mov     r1,#2dh                 ;(top+1) address in the buffer 
buf_sft_loop: 
       mov     a,@r1                   ;read @(N+1) symbol from buffer 
       jz      fin_clr                 ;0->we should clear something and return to scan 
       mov     @r0,a                   ;else, write @(N+1) to @(N) 
       inc     r0 
       inc     r1 
       mov     a,r1                    ;while (N+1)... 
       jb6     fin_clr                 ;...is <= 40h (3fh is the highest ram addr) 
       jmp     buf_sft_loop 
; 
fin_clr: 
       clr     a 
       mov     @r0,a                   ;clear @3fh (after buffer loop) or @2ch (if buffer was empty) 
       mov     r1,#2ch 
       mov     a,@r1                   ;is buffer now empty? 
       jnz     scanloop                ;no - continue scan 
       clr     f1 
       jmp     scanloop                ;yes - clear f1 and continue scan 
; 
       org     0f8h 
; 
chk_out_ready: 
       orl     p2,#7 
       in      a,p1 
       jb1     farled 
       jmp     chk_out_ret 
; 
       org     100h 
;ROM page 1 checksum check (here we are after startup and reset) ;
; 
pg1chk:        mov     a,r7 
p1loop:        movp    a,@a 
       add     a,r6 
       mov     r6,a 
       inc     r7 
       mov     a,r7 
       jnz     p1loop 
       jmp     pg2chk                  ;256bytes summed ->0200 
;
       org     110h
;
;
;---------------------------------timer maintentance 
;------------------------------------here we are after jtf check and in register bank 1 
;note that there's NO r3 reload: it will count to 30h only ONCE, it's first delay to switch TYPEMATIC on 
;when r3 count up to 30, it won't change anymore, changes (and reload) will be only in r2: it's delay between 
;typematic generated MAKEs. 
; 
tmr:   mov     a,r3 
       xrl     a,#30h 
       jz      tmr_shortloop 
       inc     r3                      ;first, long-delay jtf case - inc r3 until 30h 
tmr_preret: 
       sel     rb0 
       jmp     tmr_ret 
; 
       org     11ah 
; 
tmr_shortloop:                         ;r3 overflow case
       mov     a,r2 
       xrl     a,#4 
       jz      tmr_typematic           ;r2<>04h? 
       inc     r2                      ;yes - inc r2 and exit tmr 
       jmp     tmr_preret 
; 
tmr_typematic: 
       clr     a                       ;r2 overflow case: clr r2, 
       mov     r2,a 
       sel     rb0 
       mov     a,r6 
       mov     r3,a                    ;typematic->r3 (for get_scode), 
       jmp     get_scode               ;and put typematic MAKE code to buffer 
;
       org     130h
;
;--------------------------------keyboard map maintentance 
;128 keys can be stored in binary format in 16 bits 
;every bit contains binary image of 8 keys 
;to get the map from key number (keynum), we should 
;calculate byte number (this in keynum mod 8, i.e 
;keynum without 3 least bits) 
;and then decode 3 bits to 8-bit "1-of-8" code 
; 
;on call, r1 contains key number 
;on return: 
; r1 contains coresponding byte address of keymap 
; r5 contains decoded position in corresponding byte of keymap 
; (lower keynum has higher bit) 
; r4,a := 0
;
keymap:        sel     rb0 
       dec     r1 
       mov     a,r1 
       mov     r4,a                    ;now keynum-1 is in r4 and acc 
       rr      a 
       rr      a 
       rr      a                       ;mod8 
       anl     a,#1fh                  ;0b0001.1111 - get 5 higher bits of keynum in low positions 
       add     a,#1ch                  ;keymap base address 
       mov     r1,a                    ;now r1 has byte number 
                                       ;1-of-8 decoding 
       mov     r5,#80h                 ;leading 1 
decod: mov     a,r4 
       anl     a,#7                    ;get 3 lower bits... 
       mov     r4,a                    ;...in r4 
       jz      dc_done                 ;if during "rr r5" and "dec r4" r4=0->exit 
       mov     a,r5 
       rr      a 
       mov     r5,a                    ;equ rr r5 
       dec     r4 
       jmp     decod 
; 
dc_done: 
       retr 
; 
       org     150h 
;here we are after MAKE 
make_scode: 
       mov     a,r7 
       mov     r6,a                    ;r7->r6 (for future typematic) 
       mov     r3,a                    ;->r3 (for get_scode, BREAK off) 
       clr     f0                      ;every real MAKE switch typematic off
 
;here we are after BREAK and TYPEMATIC timer 
get_scode: 
       mov     a,r3 
       anl     a,#80h                  ;r3 bit7 stores BREAK option, 6..0 - keynum 
       mov     r0,a                    ;now r0 bit7 stores only BREAK option 
       mov     a,r3 
       anl     a,#7fh                  ;now Acc stores only keynum 
       movp3   a,@a                    ;get MAKE scancode 
       orl     a,r0                    ;convert it to BREAK by r0, if necessary 
       mov     r3,a                    ;put scancode in r3 
       mov     r0,#2ch                 ;top-of-buffer addr in r0 
       jmp     bufadr                  ;place code in FIFO buffer 
 
 
 
;--------------------------Num, Rus and Lat LED 
;--------------------------processing rouine 
;port 1 bit 7 - NUM led 
;port 1 bit 6 - LAT led 
;port 1 bit 5 - RUS led 
;r2 bit 0 - NUM status (1=on) 
;NUM key - code 0x45 
;LAT key - code 0x5b 
;RUS key - code 0x57 
; 
led:   mov     r0,#2ch                 ;top of the scan code buffer 
       mov     a,@r0                   ;read last key 
       mov     r5,a 
;--------------------------rus and lat 
       xrl     a,#57h 
       jz      latled 
       mov     a,r5 
       xrl     a,#5bh 
       jz      rusled 
       mov     a,r5 
;--------------------------num lock toggler 
       xrl     a,#45h 
       jnz     exitled                 ;not num lock - exit 
       jf0     exitled                 ;typematic numlock - exit 
       mov     a,r2                    ;bit 0 of r2 stores num lock status 
       jz      num_on                  ;0 - wasn't numlock -> switch on 
       mov     r2,#0                   ;<>0 - was numlock -> switch off 
       anl     p1,#7fh                 ;0b0111.1111 - bit 7 off 
       jmp     pc_out 
; 
num_on:        mov     r2,#1                   ;lit the numlock led 
       orl     p1,#9fh                 ;0b1001.1111 - bit 7 on 
       jmp     pc_out 
;  
latled:        anl     p1,#9fh                 ;0b1001.1111 - off both rus/lat
       orl     p1,#5fh                 ;0b0101.1111 - on bit 6 
       jmp     pc_out 
; 
rusled:        anl     p1,#9fh                 ;0b1001.1111 - off both rus/lat 
       orl     p1,#3fh                 ;0b0011.1111 - on bit 5 
exitled: 
       jmp     pc_out 
;----------------------end of LED toggler
;
       org     1c0h 
; 
       clr     f1                      ; 01c0 - a5h
       nop     ; data truncated 
; 
       org     1d0h 
; 
clearam: 
       cpl     f1 
       mov     r1,#2 
       mov     r0,#0 
       jmp     ramloop 
; 
       org     200h 
;
;ROM page 2 checksum test (after startup and reset)
pg2chk:        mov     a,r7 
p2loop:        movp    a,@a 
       add     a,r6 
       mov     r6,a 
       inc     r7 
       mov     a,r7 
       jnz     p2loop 
;ROM page 3 checksum test 
pg3chk:        movp3   a,@a 
       add     a,r6 
       mov     r6,a 
       inc     r7 
       mov     a,r7 
       jnz     pg3chk 
       mov     a,r6                    ;is full checksum=0? 
       jnz     err_rom                 ;no->fatal loop 
 
;------------------registers test: r0   
r0_tst:        mov     r0,#0aah 
       mov     a,#0aah 
       xrl     a,r0 
       jnz     err_reg 
       mov     r0,#55h 
       mov     a,#55h 
       xrl     a,r0 
       jnz     err_reg 
       jmp     r1_tst 
; 
       org     226h 
;------------------registers test: r1 
r1_tst:        mov     r1,#0aah 
       mov     a,#0aah 
       xrl     a,r1 
       jnz     err_reg 
       mov     r1,#55h 
       mov     a,#55h 
       xrl     a,r1 
       jnz     err_reg
 
;------------------indirect addressing test 
;------------------and RAM test (including registers r2..r7)
;------------------wr/rd 0aah, then 055h, then clearing (wr/rd 00h)
;------------------then exit to out_0aah 
       mov     r1,#2 
       mov     r0,#0aah 
ramloop: 
       mov     a,r0                    ;test loop 
       mov     @r1,a 
       mov     a,@r1 
       xrl     a,r0 
       jnz     err_reg                 ;failure 
       inc     r1 
       mov     a,r1 
       xrl     a,#40h                  ;40h (64) is RAM size 
       jnz     ramloop 
       jf0     ram_f0_1 
       cpl     f0 
       mov     r1,#2 
       mov     r0,#55h 
       jmp     ramloop 
; 
ram_f0_1: 
       jf1     out_0aah                ;f1 should be set to 1 to proceed 0aah output 
       jmp     clearam 
; 
; 
;------------------------------this is 0aah output to pc after POST and software reset 
;
out_0aah: 
       mov     r7,#0aah                ;r7 stores symbol to out 
pc_out_2: 
       orl     p2,#0e7h                ;0b1110.0111 
       in      a,p1                    ;to read, pc_data and pc_clk are on port 1 
       cpl     a 
       jb0     chk_reset               ;p1.0=0 ->reset 
       jb1     pc_out_2                ;p1.1=0:contitious loop to wait it 
                       ;if p1.0 and p1.1=1 then out "0aah" (similar to "output" at 0b3h) 
                       ;output routine 
       anl     p2,#0a5h                ;0b1010.0101    ;bits 6 and 1? (4 and 3 see above) 
       mov     r4,#7                   ;r4 is bit counter 
       orl     p2,#0c3h                ;0b1100.0111    (6 and 1) to 1   
                                       ;symbol loop 
newbit_2: 
       mov     a,r7 
       jb0     out_1_2                 ;out_1 
                                       ;out_0 
       anl     p2,#81h                 ;0b1000.0001    (6 and 1) to 0 
       orl     p2,#0c3h                ;0b1100.0111    (6 and 1) to 1 
pc_sft_2: 
       mov     a,r4 
       jz      stop_cond_2 
       dec     r4 
       mov     a,r7 
       rr      a 
       mov     r7,a 
       jmp     newbit_2 
; 
chk_reset: 
       in      a,p1 
       cpl     a 
       jb0     chk_reset 
       jmp     X0000                   ;p1.0=0:RESET 
; 
out_1_2: 
       orl     p2,#0a5h                ;0b1010.0101    (6 and 1) to 0 
       anl     p2,#0a5h                ;0b1010.0101 
       orl     p2,#0e7h                ;0b1110.0111     
       jmp     pc_sft_2 
; 
;here we are after 0aah output (stop-conditions in pc transmit) 
;
stop_cond_2: 
       orl     p2,#0a5h 
       anl     p2,#0a5h                ;latch last bit 
       orl     p2,#0e7h 
       anl     p2,#0c3h                ;stop condition (?) 
                       ;searching for stuck keys 
       jf0     stucktest               ;only 1st case from beginning, rest cases - from last stuck key 
nxtkey:        inc     r6                      ;next key 
       mov     a,r6 
       cpl     a                       ;r6 stores key number (max=127) 
       jb7     stucnx                  ;all 127 keys checked? 
                                       ;final initialisation procedures 
       clr     a 
       mov     r6,a 
       mov     r7,a 
       mov     r1,a 
       clr     f0 
       jmp     ledinit                 ;after_reset rus led on 
; 
err_reg: 
       mov     a,#5fh                  ;r0,r1,ram fail: code 5f to bus 
       outl    bus,a 
       jnt0    ram_f0_1                ;t1=0 ignores this test results and continues 
       jmp     r0_tst                  ;loop to registers test 
; 
       org     2a0h 
; 
;stucked keys search and output code of the first of such a key 
; 
stucktest: 
       mov     r6,#1 
stucnx:        mov     a,r6 
       outl    bus,a 
       anl     p2,#42h                 ;0b0100.0010 enable DC (p2.0=0) 
       clr     f1 
       jt1     nxtkey                  ;check if key stuck on this col 
       mov     a,r6 
       mov     r1,a 
       call    keymap                  ;yes - stck - get keymap position 
       mov     a,@r1                   ;read keymap byte 
       orl     a,r5                    ;modify necessary bit 
       mov     @r1,a                   ;write keymap byte 
       jf0     stuck_cod               ;only 1st code of stucked key is sent 
       jmp     nxtkey                  ;next key 
; 
       org     2b6h 
;  
err_rom: 
       outl    bus,a                   ;out faulty checksum 
erloop:        jnt0    r0_tst                  ;t0 controls necessarity of stop after checkum fail (0-dont stop) 
       jmp     erloop                  ;fatal loop 
; 
       org     2c0h 
; 
stuck_cod: 
       clr     f0 
       mov     a,r6 
       movp3   a,@a                    ;read scan code 
       mov     r7,a 
       jmp     pc_out_2                ;outputs scan code of stucked key 
; 
       org     300h 
;
				       ;scan code table 
       db      0,1,2,3,4,5,6,7 
       db      8,9,0ah,0bh,0ch,0dh,2bh,0eh 
       db      0fh,10h,11h,12h,13h,14h,15h,16h 
       db      17h,18h,19h,36h,3ah,35h,37h,1dh 
       db      1eh,1fh,20h,21h,22h,23h,24h,25h 
       db      26h,1ah,1bh,27h,28h,1ch,38h,54h 
       db      2ch,2dh,2eh,2fh,30h,31h,32h,29h 
       db      2ah,5ch,33h,34h,55h,56h,57h,58h 
       db      59h,39h,5ah,5bh,3bh,3ch,3dh,3eh 
       db      3fh,40h,41h,42h,43h,44h,45h,46h 
       db      4ah,47h,48h,49h,4bh,4ch,4dh,4fh 
       db      50h,51h,52h,53h,4eh,0,0,0 
; 
       end 

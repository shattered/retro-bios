;------------   INT 13      --------------- 
;    **** χχοδ-χωχοδ ξα δισλετυ **** 
 
CONTROL_STAT   EQU    0C0H   ;ποςτ λοξτςομρ ι σοστορξιρ 
;-------------------------------------------------- 
; ξαϊξαώεξιε ςαϊςρδοχ ςεηιστςα (ποςτα) CONTROL_STAT 
;-------------------------------------------------- 
;       D0 - ϊαξρτο 
;       D1 - ιξδελσ ινπυμψσα, σοοτχ. DRQ 
;       D2 - νη ξα 0 δοςοφλε ιμι τακναυτ πςι ϊπ ι ώτ 
;       D3 - οϋιβλα CRC (λλ) 
;       D4 - ξετ ϊαπισι, ξε ξακδεξ νασσιχ 
;       D5 - νη ϊαηςυφεξα ιμι σο στιςαξιεν αν πςι ώτ 
;            ιμι δοςοφλα ξε ξακδεξα πςι ϊπ 
;       D6 - ϊαύιτα ϊαπισι 
;       D7 - ξε ηοτοχ 
;--------------------------------------------------- 
 
TRACK          EQU    0C1H   ;ποςτ ξονεςα δοςοφλι 
SECTOR         EQU    0C2H   ;ποςτ ξονεςα σελτοςα 
DATA_F         EQU    0C3H   ;ποςτ δαξξωθ 
;    ========   δμρ ώτεξιρ :  =========== 
; 
MOTOR_EN       EQU    0C6H   ;σοστορξιε δχιηατεμρ <D0> 
RD_INTRQ       EQU    0C4H   ;ώτεξιε INTRQ ιμι DRQ, D0-INTRQ 
; 
;   =========   δμρ ϊαπισι :  =========== 
RG_C           EQU    0C4H   ;DDEN,HDSEL,FDRES, 
                             ;EN. MOTORS,DRIVES(SEL1,SEL2) 
;------------------------------------- 
; ξαϊξαώεξιε ςαϊςρδοχ ςεηιστςα (ποςτα) RG_C 
;------------------------------------- 
;       D0 - DRIVE SELECT 0      -χωβος υστςοκστχα 0 
;       D1 - DRIVE SELECT 1      -χωβος υστςοκστχα 1 
;       D2 - MOTOR ON 0          -χλμ. νοτος 0 
;       D3 - MOTOR ON 1          -χλμ. νοτος 1 
;       D4 - SIDE (HEAD) SELECT  -χωβος στοςοξω (ηομοχλι) 
;       D5 - DOUBLE DENSITY      -ςεφιν δχοκξοκ πμοτξοστι 
;       D6 - FDC RESET           -σβςοσ δχοκξοκ πμοτξοστι 
;       D7 - NO USE              -ξε ισπομψϊυετσρ 
;------------------------------------- 
MOTOR_ON       EQU    0C6H   ;χλμ. νοτοςα 
 
; ========= ξ α   χ θ ο δ ε  ============= 
;       αL      -λομιώεστχο σελτοςοχ δμρ ώτ-ϊπ 
;       AH      -λοδ οπεςαγιι 
;            0    -σβςοσ 
;            1    -ώτεξιε σοστορξιρ 
;            2    -ώτεξιε δαξξωθ 
;            3    -ϊαπισψ δαξξωθ 
;            4    -οπςοσ, πςοχεςλα 
;            5    -ζοςνατιςοχαξιε 
;- - - - - - - - - - - - - - - - - - - - 
;       DH      -ξονες ηομοχλι 
;       DL      -ξονες υστςοκστχα (0-3) 
;- - - - - - - - - - - - - - - - - - - - 
;       CH      -ξονες γιμιξδςα (δοςοφλι) 
;       σL      -ξονες σελτοςα (1-17) 
;- - - - - - - - - - - - - - - - - - - - 
;       ES:BX   -αδςεσ βυζεςα 
; 
; ============== λοδω ϊαχεςϋεξιρ ================== 
BAD_CMD         EQU    1        ;ξεχεςξαρ λοναξδα (αξ>5,DL>3) 
BAD_ADDR_MARK   EQU    2        ; 
WRITE_PROTECT   EQU    3        ;ϊαύιτα ϊαπισι 
RECORD_NOT_FND  EQU    4        ; 
BAD_DMA         EQU    8        ; 
DMA_BOUNDARY    EQU    9        ; 
BAD_CRC         EQU    10H      ; 
BAD_FDC         EQU    20H      ;ξετ σβςοσα 
BAD_SEEK        EQU    40H      ; 
TIME_OUT        EQU    80H      ;τακν-αυτ 
;=================================================== 
; 
SEEK_OK         EQU    0 
READ_WRITE_OK   EQU    0 
SEEK_COMMAND    EQU   1cH       ;V = 1,h = 1 
SEEK_COMNOV     EQU   10H       ;V = 0 
READ_COMMAND    EQU   80H 
WRITE_COMMAND   EQU   0A0H 
WR_TRACK        EQU   0F0H 
STEP_COMMAND    EQU   48H 
WORD_DDEN       EQU   0 
; 
data    segment at 40h 
        ORG     3EH 
;---------------------------------------------------------------------------- 
; DISKETTE DATA AREAS     - οβμαστψ δαξξωθ 
;---------------------------------------------------------------------------- 
SEEK_STATUS            DB     ?             ;DRIVE RECALIBRATION STATUS 
;                                           BIT 3-0= DRIVE 3-0 NEEDS RECAL 
;                                           BEFORE NEXT SEEK IF BIT IS=0 
INT_FLAG               EQU    080H          ;ζμαη ξαμιώιρ πςεςωχαξιρ 
MOTOR_STATUS           DB     ?             ;σοστορξιε δχιηατεμρ 
;                             BIT 3-0 = DRIVE 3-0 IS CURRENTLY RUNNING 
;                             BIT 7 = CURRENT OPERATION IS A WRITE, 
;                             REQUIRES DELAY 
;                                           DISKETES 
MOTOR_WAIT             EQU    37            ;TWO SECONDS OF COUNTS FOR 
;                                           MOTOR TURN OFF 
MOTOR_COUNT            DB      ? 
; 
DISKETTE_STATUS        DB     ?             ;βακτ λοδα χοϊχςατα 
; 
NEC_STATUS             LABEL BYTE              ;7 BYTE 
TRACK_PTR              DB     2 DUP(?) 



STEP_MULT              DB     ?             ;πςιϊξαλ 1 -υστς 0,1 
                                            ;        2 -υστς 2,3 
DRIVER_N               DB     0             ;ξονες αλτιχξοηο υστς-χα 
                       DB     3 DUP (?)       ;ςεϊεςχ 



 
;----------------------------------------------------------------------- 
data ends 
 
; 
code    segment 
        assume cs:code,ds:data 
 
; λαςτςιδφξαρ σιηξατυςα 
 
        DW      0AA55H 
        DB      03H 
 
DISK_INIT    PROC   FAR 
 
; π/π ιξιγιαμιϊαγιι δισλοχοηο αδαπτεςα 
 
        MOV     AX,0H 
        MOV     DS,AX 
        MOV     BX,410H 
        MOV     AX,DS:[BX] 
        OR      AX,01H            ;δÒΑΚΧΕÒ ηνδ ΠÒΙΣΥΤΣΤΧΥΕΤ 
        MOV     DS:[BX],AX 
        MOV     BX,4CH            ;υΣΤΑΞΟΧΙΤΨ ΧΕΛΤΟÒ INT13H 
        LEA     AX,DISKETTE_IO 
        MOV     DS:[BX],AX 
        PUSH    CS 
        POP     AX 
        MOV     DS:[BX+2],AX 
        DB      0CBH           ;(RETF) 
DISK_INIT    ENDP 
 
DISKETTE_IO  PROC  FAR 
        STI                     ;ςαϊςεϋεξιε πςεςωχαξικ 
        PUSH    BX              ;σοθςαξεξιε ςεηιστςοχ 
        PUSH    CX 
        PUSH    DS 
        PUSH    SI 
        PUSH    DI 
        PUSH    BP 
        PUSH    DX 
        MOV     BP,SP           ;υλαϊατεμψ στελα 
        MOV     SI,DATA         ;DATA-σεηνεξτ 
        MOV     DS,SI           ;ιξιγιαγιρ DATA-σεηνεξτα 
        PUSH    CX              ;σοθς. σθ 
        MOV     CH,1 
        TEST    DL,2            ;υστςοκστχο 2,3? 
        JNZ     STM             ;δα 
        MOV     STEP_MULT,1     ;υστς0,υστς1 
        JMP     STM1 
STM:    MOV     STEP_MULT,2     ;υστς2(*),υστς3(*) 
        AND     DL,1            ;σοοτχ. χ 0,1 
STM1:   MOV     CL,DL           ;ξονες υστςοκστχα 
        ROL     CH,CL           ;σδχιη 1 πο ξονεςυ υστςοκστχα 
        MOV     MOTOR_STATUS,CH ;βακτ ιξιγιαμιϊαγιι (ξονες υστςοκστχα) 
        POP     CX              ;χοσσταξοχμεξιε σθ 
        CALL    J1              ;ξα οπςεδεμεξιε λοδα λοναξδω 
        MOV     AH,DISKETTE_STATUS ;λοδ ϊαχεςϋεξιρ 
        CMP     AH,1            ;εσμι αξ=0,TO CF=1, ιξαώε CF=0 
        CMC                     ;ιξχεςσιρ βιτα CF 
        POP     DX              ;χοσσταξοχμεξιε ςεηιστςοχ 
        POP     BP 
        POP     DI 
        POP     SI 
        POP     DS 
        POP     CX 
        POP     BX 
        RET     2               ;χοϊχςατ νεφσεηνεξτξωκ σ σοθς. ζμαηοχ 
DISKETTE_IO ENDP 
 
;========== οπςεδεμεξιε λοδα λοναξδω πο AH =========== 
J1:     AND     MOTOR_STATUS,7FH  ;ιξδιλαγιρ δμρ ώτεξιρ (χ7=0) 
        OR      AH,AH           ;AH = 0? 
        JZ      DISK_RESET      ;δα, λοναξδα σβςοσα 
        CMP     AH,6 
        JNL     J3              ;ξεχεςξαρ λοναξδα (AH > 5) 
        CMP     AH,1            ;ώτεξιε σοστορξιρ? 
        JZ      DISK_STATUS     ;δα, (AH = 1) 
        MOV     DISKETTE_STATUS,0   ;λοδ ϊαχεςϋεξιρ ξοςναμψξωκ (0) 
        CMP     DL,2            ;υστςοκστχο 0,1? 
        JAE     J3              ;ξετ (DL > 3) 
        cmp     ah,5            ;αξ=5? 
        jz      form            ;δα, ζοςνατιςοχαξιε 
        CMP     AH,3            ;λοδ οπ-γιι ξε βομψϋε 3? 
        JBE     RW_OPN          ;δα, ώτ/ϊπ οπεςαγιρ (AH = 2,AH = 3) 
        JMP     VERIFY_OPN      ;οπ-γιρ πςοχεςλι (AH = 4) 
J3:     MOV     DISKETTE_STATUS,BAD_CMD   ;λοδ οϋιβλι 
        RET                     ;χοϊχςατ 
form:   jmp     form1           ;ξα π/π ζοςνατιςοχαξιρ 
 
;=============================================================== 
;       π/π ώτεξιρ σοστορξιρ (αξ=1) 
;=============================================================== 
; 
; 
DISK_STATUS: 
        MOV     AL,DISKETTE_STATUS 
        RET 
; 
; 
;=============================================================== 
;       π/π σβςοσα χ ισθοδξοε σοστορξιε (αξ=0) 
;=============================================================== 
DISK_RESET: 
        PUSH    AX              ;σοθςαξεξιε ςεηιστςοχ 
        PUSH    SI 
        PUSH    CX 
        PUSH    DX 
        CLI                     ;ϊαπςετ πςεςωχαξικ 
        OUT     MOTOR_ON,AL     ;λ-χο σελτοςοχ-->C6 ????????????? 
        MOV     SI,DX           ;ξονες υστςοκστχα 
        AND     SI,1            ;χωδεμεξιε ξονεςα υστς. 
        MOV     TRACK_PTR [SI],0   ;0 χ βακτ πο ξονεςυ υστς. 
        MOV     CL,DL           ;ξονες υστςοκστχα 
        MOV     AL,5            ;υστς. 0, νοτος 0 
        SAL     AL,CL           ;σδχιη ξα λομιώεστχο πο ξονεςυ υστς. 
        MOV     AH,DH           ;ξονες ηομοχλι (στοςοξω) 
        AND     AH,1            ;χωδεμεξιε νμ. βιτα (0 ιμι 1) 
        MOV     CL,4            ; 
        ROL     AH,CL           ;ξονες ηομοχλι χ D4 
        OR      AL,AH           ;(υστς+νοτος)+ηομοχλα 
        OUT     RG_C,AL         ;σβςοσ .... δχοκξοκ πμοτξοστι 
        OR      AL,40H          ;+ σβςοσ δχοκξοκ πμοτξοστι 
        MOV     SEEK_STATUS,0   ;στατυσ ποπωτλι 0 
        MOV     DISKETTE_STATUS,0  ;στατυσ σοστορξιρ 0 
        OUT     RG_C,AL;        ;σο σβςοσον δχοκξοκ πμοτξοστι 
        STI                     ;ςαϊςεϋιτψ πςεςωχαξιρ 
        MOV     AH,2            ;2 ςαϊα 
RETR:   XOR     CX,CX           ;σθ=0 
RETR1:  PUSH    AX              ;σοθς. αθ 
        IN      AL,CONTROL_STAT   ;ώτεξιε σοστορξιρ 
        AND     AL,5            ;χωδεμεξιε βιτοχ 0 ι 2 
        CMP     AL,4            ;ξοςναμψξο? (νη ξα δος 0) 
        POP     AX 
        JZ      RESET_END       ;δα, λοξεγ σβςοσα 
        LOOP    RETR1           ;ξετ, εστψ εύε "ϊαξρτο" 
        DEC     AH              ; 
        JNZ     RETR            ;ποπωτατψσρ 2 ςαϊα 
        OR      DISKETTE_STATUS,BAD_FDC  ;ξετ σβςοσα δχ. πμοτξοστι 
                                         ;χσε χςενρ "ϊαξρτο" 
        MOV     TRACK_PTR [SI], 0FFH  ;FF χ βακτ πο ξονεςυ υστς. 
RESET_END: 
        POP     DX              ;χοσσταξοχμεξιε ςεηιστςοχ 
        POP     CX 
        POP     SI 
        POP     AX 
        RET 
 
;=============================================================== 
;       π/π ώτεξιρ-ϊαπισι 
;=============================================================== 
; 
RW_OPN: OR      AH,AH           ;λοδ αξ=2 (ώτεξιε)? 
        JNP     J9              ;δα       ???????????????? 
        OR      MOTOR_STATUS,80H   ;πςιϊξαλ ϊαπισι 
J9:     CALL    SELECT_DRIVE    ;χωβος υστς.+νοτος+ηομοχλα 
        CALL    TEST_WAIT       ;ϊαδεςφλα 
        TEST    MOTOR_STATUS,80H   ;ϊαπισψ? 
        JNZ     WRITE_DISK      ;δα 
READ_DISK:                      ;ώτεξιε σ δισλα 
        MOV     DL,0            ;σώετώιλ ώισμα σελτοςοχ 
        PUSH    BX 
        MOV     BL,SEEK_COMMAND ;ποισλ σ ϊαηςυϊλοκ νη ι πςοχ. 
        CALL    SEEK            ;ποισλ 
        POP     BX 
        JC      ERR_OUT         ;βωμα οϋιβλα (CF=1) 
READ_LENG: 
        CALL    READ            ;ξα π/π ώτεξιρ 
        JC      ERR_OUT         ;βωμα οϋιβλα 
        INC     DL              ;+1 λ σώετώιλυ σελτςοχ 
        CALL    GET_SECTOR      ;υσταξοχλα ξα σμεδ. σελτος 
        CMP     AL,DL           ;χσε σελτοςα? 
        JNZ     READ_LENG       ;εύε ξετ 
        RET                     ;ώτεξιε ϊαχεςϋεξο 
ERR_OUT: 
        MOV     AL,DL           ;ξονες σελτοςα σ οϋιβλοκ 
        RET 
WRITE_DISK: 
        MOV     DL,0            ;σώετώιλ ώισμα σελτοςοχ 
        PUSH    BX 
        MOV     BL,SEEK_COMMAND ;ποισλ σ ϊαηςυϊλοκ νη ι πςοχ. 
        CALL    SEEK            ;ποισλ 
        POP     BX 
        JC      ERR_OUT         ;βωμα οϋιβλα 
WRITE_LENG: 
        CALL    WRITE           ;ϊαπισψ 
        JC      ERR_OUT         ;βωμα οϋιβλα 
        INC     DL              ;+1 λ σώετώιλυ σελτοςοχ 
        CALL    GET_SECTOR      ;υσταξοχλα ξα σμεδ. σελτος 
        CMP     AL,DL           ;χσε σελτοςα? 
        JNZ     WRITE_LENG      ;ξε ύε 
        RET                     ;ϊαπισψ ϊαχεςϋεξα 
 
 
;========================================================================== 
;       π/π ζοςνατιςοχαξιρ δισλετω δοςοφλι 
;========================================================================== 
FORM1:  CALL    SELECT_DRIVE    ;υστς+νοτος+ηομοχλα 
        CALL    TEST_WAIT       ;χλμ νοτοςα 
        PUSH    BX 
        MOV     BL,SEEK_COMNOV  ;λοδ 10 -ποισλ 
        CALL    SEEK            ;ξα π/π ποισλα 
        POP     BX 
        JC      ERR_FORM        ;εσμι βωμα οϋβ, CF=1 
        CALL    WRITE_TRACK 
ERR_FORM: 
        MOV     AL,9 
        RET 
 
;SUBROUTINE  WRITE TRACK FOR FORMAT-π/π ζοςνατιςοχαξιρ 
;SI-TRACK,SIDE                     -SI δοςοφλα,στοςοξα 
;DI-END NUMB SEC ,SIZE SEC         -DI λοξ.ξον.σελτοςα,ςαϊνες 
;AH-SECTOR                         -AH σελτος 
;ES-SIZE SEC IN BYTE               -ES ςαϊνες σελτοςα 
; 
WRITE_TRACK: 
        PUSH ES 
        MOV     AX,ES:[BX]      ;σμοχο σ βυζεςα (δος., στος.) 
        MOV     SI,512          ;ςαϊνες σελτοςα 
        MOV     ES,SI           ; 
WR_TRACK5: 
        MOV     SI,AX           ;δοςοφλα, στοςοξα 
        MOV     DI,10*256+2     ;λοξεώξωκ  σώετώιλ σελτοςοχ 
        MOV     AH,01           ;ξαώαμψξωκ σώετώιλ σελτοςοχ 
        CALL    WRITE_TR        ;ϊαπισψ ξα δοςοφλυ 
        POP     ES 
        RET 
 
       ;π/π ϊαπισι ζοςνατα ξα δοςοφλυ 
WRITE_TR: 
        MOV     DX,DATA_F       ;ποςτ δαξξωθ 
        MOV     AL,WR_TRACK     ;λοδ "ϊαπισψ δοςοφλι" 
        CLI                     ;ϊαπςετ πςεςωχαξικ 
        OUT     CONTROL_STAT,AL ;λοναξδα "ϊπ δοςοφλι" 
                        ;80 βακτ 4ε (πςοβεμ) 
        MOV     CX,80 
WLD01:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,4EH 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD01 
                        ;12 βακτ 00 
        MOV     CX,12 
WLD02:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        SUB     AL,AL 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD02 
                        ;3 βακτα F6 (ϊπ σ2) 
        MOV     CX,3 
WLD03:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,0F6H 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD03 
                        ;1 βακτ FC (ιν) 
        IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,0FCH 
        OUT     DX,AL          ;WRITE DATA 
                        ;50 βακτ 4ε (1-κ πςοβεμ) 
        MOV     CX,50 
WLD05:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,4EH 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD05 
                        ;11 βακτ 00 
        MOV     CX,11 
WLD06:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        SUB     AL,AL 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD06 
                        ;+1 βακτ 00 
WR_SEC: 
        IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        SUB     AL,AL 
        OUT     DX,AL          ;WRITE DATA 
                        ;3 βακτα F5 (ϊπ α1) 
        MOV     CX,3 
WLD08:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,0F5H 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD08 
                        ;1 βακτ FE (αδςεσξαρ νετλα) 
WLD09:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,0FEH 
        OUT     DX,AL          ;WRITE DATA 
                               ;adress label 
                        ;1 βακτ (ξονες δοςοφλι) 
        MOV     BX,SI 
WLD0A:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,BL 
        OUT     DX,AL          ;WRITE DATA 
                               ;number track 
                        ;1 βακτ (ξονες στοςοξω) 
WLD0B:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,BH 
        OUT     DX,AL          ;WRITE DATA 
                               ;number side 
                        ;1 βακτ (ξονες σελτοςα) 
WLD0C:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,AH 
        OUT     DX,AL          ;WRITE DATA 
                               ;number sector 
        INC     AH             ;+1 λ ξονεςυ σελτοςα 
                        ;1 βακτ (δμιξα σελτοςα) 
        MOV     BX,DI          ; <0α02> 
WLD0D:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,BL 
        OUT     DX,AL          ;WRITE DATA 
                                ;size sector 
                        ;1 βακτ F7 (2 βακτα λλ) 
WLD0E:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,0F7H 
        OUT     DX,AL          ;WRITE DATA 
                                 ;byte crc 
                        ;22 βακτα 4ε (2-κ πςοβεμ) 
        MOV     CX,22 
WLD0F:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,4EH 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD0F 
                        ;12 βακτ 00 
        MOV     CX,12 
WLD10:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        SUB     AL,AL 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD10 
                        ;3 βακτα F5 (ϊπ α1) 
        MOV     CX,3 
WLD11:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,0F5H 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD11 
                        ;1 βακτ FB (αδς.νετλα δαξξωθ) 
                        ;βεϊ στιςαξιρ 
WLD12:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,0FBH 
        OUT     DX,AL          ;WRITE DATA 
                        ;πο ςαϊνεςυ σελτοςα <512> βακτ 4ε 
        MOV     CX,ES 
WLD13:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,4EH 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD13 
                        ;1 βακτ F7 (2 βακτα λλ) 
WLD14:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,0F7H 
        OUT     DX,AL          ;WRITE DATA 
                        ;54 βακτα 4ε (3-κ πςοβεμ) 
        MOV     CX,54 
WLD15:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,4EH 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD15 
                        ;11 βακτ 00 
        MOV     CX,11 
WLD16:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        SUB     AL,AL 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD16 
        CMP     AH,BH           ;χσε σελτοςα οτ 1-9 (αξ=10) 
        JNZ     WR_SEC          ;ξετ εύε 
                        ;598 βακτ 4ε (4-κ πςοβεμ) 
        MOV     CX,598 
        MOV     BL,04EH 
WLD17:  IN      AL,RD_INTRQ    ;WAIT FOR DRQ OR INTRQ 
        MOV     AL,BL 
        OUT     DX,AL          ;WRITE DATA 
        LOOP    WLD17 
        IN      AL,CONTROL_STAT ;ώτεξιε σοστορξιρ 
        AND     AL,47H          ; 
        JZ      WRDSK_END       ;ξοςναμψξο ϊαπισαξο 
        TEST    AL,40H          ;ϊαύιτα ϊαπισι? 
        MOV     AL,WRITE_PROTECT ;λοδ οϋιβλι "ϊαύιτα" 
        JNZ     ERR_EX          ;δα, οϋιβλα 
        MOV     AL,BAD_FDC      ;λοδ οβύεκ οϋιβλι 
ERR_EX:                         ; 
        OR      DISKETTE_STATUS,AL ;δοβαχμεξιε λοδα οϋιβλι 
        STC                     ;CF=1 -- οϋιβλα 
WRDSK_END: 
        RET 
 
;=============================================================== 
;       υσταξοχλα ξα σμεδυΰύικ σελτος 
;=============================================================== 
GET_SECTOR: 
        PUSH    AX 
        INC     CL              ;υχεμιώεξιε ξονεςα σελτοςα 
        MOV     AL,CL 
        OUT     SECTOR,AL       ;χωχοδ ξονεςα σελτοςα 
        POP     AX 
        RET 
 
;=============================================================== 
;       π/π πςοχεςλι δοςοφλι 
;=============================================================== 
VERIFY_OPN: 
        CALL    SELECT_DRIVE    ;υστς+νοτος+ηομοχλα 
        CALL    TEST_WAIT       ;χλμ. νοτοςα 
        MOV     DL,0            ;σώ. σώιταξωθ σελτοςοχ 
        PUSH    BX 
        MOV     BL,SEEK_COMMAND ;ποισλ σ ϊαηςυϊλοκ νη ι πςοχεςλοκ 
        CALL    SEEK 
        POP     BX 
        JC      ERR_OUTL        ;βωμα οϋιβλα ποισλα 
VERIFY_LENG: 
        CALL    VERIFY          ;π/π πςοχεςλι ώτεξιεν 
        JC      ERR_OUTL        ;βωμα οϋιβλα 
        INC     DL              ;+1 σώιταξωκ σελτος 
        CALL    GET_SECTOR      ;υσταξοχλα ξα σμεδυΰύικ σελτος 
        CMP     AL,DL           ;χσε σελτοςα ? 
        JNZ     VERIFY_LENG     ;ξετ εύε 
        RET                     ;πςοχεςλα ϊαχεςϋεξα 
 
VERIFY: PUSH    AX 
        PUSH    DX 
        MOV     DX,DATA_F       ;ποςτ δαξξωθ 
        MOV     AL,READ_COMMAND ;λοδ "ώτεξιε σελτοςα" 
        CLI                     ;ϊαπςετ πςεςωχαξικ" 
        OUT     CONTROL_STAT,AL ;λοναξδα 
        NOP 
VLOOP:  IN      AL,RD_INTRQ     ;ώτεξιε DRQ ιμι INTRQ 
        SHR     AL,1            ;νμ. βιτ χ σF 
        IN      AL,DX           ;ώτεξιε βακτα 
        JC      VLOOP           ;σελτος εύε ξε χεσψ 
        STI 
        CALL    ERR_TABL        ;ζοςνιςοχαξιε λοδα ϊαχεςϋεξιρ 
        POP     DX 
        POP     AX 
        RET                     ;χοϊχςατ 
ERR_OUTL: 
        JMP     ERR_OUT 
 
;=============================================================== 
;       π/π ποισλα δοςοφλι 
;=============================================================== 
SEEK:   PUSH    AX              ;σοθς. AX,DX 
        PUSH    DX              ; 
        MOV     AH,0            ; 
        MOV     AL,MOTOR_STATUS ;στατυσ νοτοςα 
        AND     AL,7FH          ;βεϊ οπεςαγιι 
        SUB     AL,1            ;-1  ?????????????????????? 
        MOV     SI,AX           ;σοθς.στατυσα 
        CMP     TRACK_PTR [SI],0FFH  ;σβςοσ βωμ ξοςναμψξωκ? 
        JNZ     SEEK0           ;δα 
SEEK00: PUSH    AX              ;βωμα οϋιβλα σβςοσα 
        CALL    SELECT_DRIVE    ;χωβος υστς+ηομοχλα 
        PUSH    DX              ;Cοθς. DX 
        MOV     DX,SI           ;στατυσ υστςοκστχα (ξονες) 
        CALL    DISK_RESET      ;σβςοσ 
        POP     DX 
        POP     AX 
        CMP     DISKETTE_STATUS,0 ;στατυσ 0 (σβςοσ ξοςναμψξωκ)? 
        JNZ     SEEK3           ;ξετ, οϋιβλα 
        OR      TRACK_PTR [SI],AH ;AH=0   δμρ πεςχοηο χθοδα χ SEEK00 
                                  ;AH=80H δμρ χτοςοηο χθοδα χ SEEK00 
SEEK0:  MOV     AL,TRACK_PTR [SI] ;σβςοσ βωμ ξοςναμψξωκ 
        MOV     AH,AL           ;0 
        AND     AH,80H          ;χωδεμεξιε δ7 (0) 
        AND     AL,7FH          ;χωδεμεξιε δ6-δ0 (0) 
        MOV     TRACK_PTR [SI],CH ;ξονες δοςοφλι 
        OR      TRACK_PTR [SI],AH ;+ ???????????? 
        MOV     AH,20H 
        SUB     AL,CH 
        JZ      SEEK2           ;δμρ AL = CH,AH:=21H 
        JNC     SEEK1           ;δμρ AL > CH,AH:=21H 
        NEG     AL              ;δμρ AL < CH,AH:=1 
        MOV     AH,0 
SEEK1:  CMP     STEP_MULT,1     ;υστς 0,1 
        JZ      STM3            ;δα 
        SHL     AL,1            ;δμρ υστς 2(*),3(*) AL:=AL*2 
STM3:   OR      AL,AL           ;δμρ υστς 0,1 
        JZ      SEEK2 
        CALL    STEP 
        JMP     SEEK22 
SEEK2:  MOV     AL,CH           ;ξονες δοςοφλι 
        OUT     TRACK,AL        ;χωχοδ ξονεςα δοςοφλι 
SEEK22: MOV     DX,DATA_F       ;αδςεσ ποςτα δαξξωθ 
        MOV     AL,CH           ;δοςοφλα 
        OUT     DX,AL           ;χωχοδ ξονεςα δοςοφλι 
        MOV     DX,CONTROL_STAT ;ποςτ σοστορξιρ 
        MOV     AL,BL           ;λοναξδα ποισλα 
        OUT     DX,AL           ;ποδαώα λοναξδω 
        NOP 
        NOP 
        IN      AL,RD_INTRQ     ;ώτεξιε ποςτα σ INTRQ 
        IN      AL,DX           ;ώτεξιε σοστορξιρ 
        AND     AL,19H          ;χωδεμεξιε δ0,δ3,δ4 
        CMP     AL,SEEK_OK      ;ξοςναμψξο? 
        JNZ     SEEK20          ;ξετ 
        AND     TRACK_PTR [SI],7FH ;ϊαβοκ δ7 
        JMP     SHORT EXIT_SEEK 
SEEK20: MOV     AL,TRACK_PTR [SI]  ; 
        AND     AL,80H          ;χωδεμεξιε δ7 
        CMP     AL,80H          ;δ7=1? 
        JZ      SEEK3           ;δα, υφε ποχτοςρμι 
        MOV     AH,80H          ;ξετ, ποχτοςιτψ 
        JMP     SEEK00 
SEEK3:  OR      DISKETTE_STATUS,BAD_SEEK ;+οϋιβλα ποισλα 
        MOV     TRACK_PTR [SI],0FFH      ;οϋιβλα 
        STC                     ;CF=1-->οϋιβλα ποισλα 
EXIT_SEEK: 
        MOV     AL,CL           ;σελτος 
        MOV     DX,SECTOR 
        OUT     DX,AL           ;ποδαώα 
        POP     DX 
        POP     AX 
        RET 
 
;============================================================== 
;       π/π ώτεξιρ      ES:BX --> αδςεσ βυζεςα. 
;============================================================== 
READ:   PUSH    AX 
        PUSH    DX 
        MOV     DI,BX           ;σνεύεξιε 
        MOV     DX,DATA_F       ;ποςτ δαξξωθ 
        MOV     AL,READ_COMMAND ;λοδ λοναξδω "ώτεξιε σελτοςα" 
        CLI                     ;ϊαπςετ πςεςωχαξικ 
        OUT     CONTROL_STAT,AL ;χωχοδ λοδα οπεςαγιι 
        JMP     RLOOP+1         ; 
RLOOP:  STOSB                   ;πςεσωμλα βακτα  AL_-->ES:DI 
        IN      AL,RD_INTRQ     ;ώτ.  INTRQ ιμι DRQ 
        SHR     AL,1            ; 
        IN      AL,DX           ;ώτεξιε βακτα δαξξωθ 
        JC      RLOOP 
        STI                     ;ϊαπςετ πςεςωχαξκ 
        CALL    ERR_TABL        ;λοδ ϊαχεϋεξιρ 
        MOV     BX,DI           ;σνεύεξιε σχοβοδξοηο βακτα 
        POP     DX 
        POP     AX 
        RET                     ;χοϊχςατ 
 
;============================================================== 
;       π/π ϊαπισι      ES:BX --> αδςεσ βυζεςα. 
;============================================================== 
WRITE:  PUSH    AX 
        PUSH    DX 
        PUSH    DS 
        MOV     AX,ES           ;αδςεσ ES B DS 
        MOV     DS,AX 
        MOV     SI,BX           ;σνεύεξιε βυζεςα χ SI 
        MOV     DX,DATA_F       ;αδςεσ ποςτα δαξξωθ 
        MOV     AL,WRITE_COMMAND ;λοδ λοναξδω "ϊαπισψ σελτοςα" 
        CLI                     ;ϊαπςετ πςεςωχαξικ 
        OUT     CONTROL_STAT,AL ;χωχοδ λοδα 
WLOOP:  IN      AL,RD_INTRQ 
        SHR     AL,1 
        LODSB                   ;AL <-- DS:SI 
        OUT     DX,AL           ;χωχοδ βακτα 
        JC      WLOOP 
        STI                     ;ςαϊςεϋεξιε πςεςωχαξικ 
        DEC     SI              ;σνεύεξιε ποσμεδξεηο χωχεδεξξοηο βακτα 
        MOV     AX,DS           ;χοσσταξοχμεξιε αδςεσα σεηνεξτα 
        MOV     ES,AX 
        MOV     BX,SI 
        POP     DS 
        CALL    ERR_TABL        ;ζοςνιςοχαξιε λοδα ϊαχεςϋεξιρ 
        POP     DX 
        POP     AX 
        RET                     ;χοϊχςατ 
 
;============================================================== 
;   π/π ζοςνιςοχαξιρ λοδοχ ϊαχεςϋεξιρ 
;============================================================== 
ERR_TABL: 
        PUSH    AX              ; 
        PUSH    DX 
        MOV     DX,CONTROL_STAT ;ποςτ σοστορξιρ 
        IN      AL,DX           ;ώτεξιε σοστορξιρ 
        AND     AL,0DFH         ;οώιστλα βιτα 5  ??????????????? 
        CMP     AL,READ_WRITE_OK   ;ξοςναμψξο (=0)? 
        JZ      NORM_EXIT       ;δα 
        IN      AL,DX           ;ώτεξιε σοστορξιρ 
        TEST    MOTOR_STATUS,80H   ;ώτεξιε? 
        JZ      R_W_ERROR       ;δα 
WRITE_ERROR:                    ;εσμι ϊαπισψ 
        TEST    AL,40H          ;ϊαύιτα ϊαπισι ? 
        MOV     AH,WRITE_PROTECT  ;λοδ οϋιβλι (ϊαύιτα ϊαπισι) 
        JNZ     ERR_EXIT        ;δα, οϋιβλα 
R_W_ERROR: 
        TEST    AL,10H          ;πςιϊξαλ "ξετ ϊαπισι" ? 
        MOV     AH,RECORD_NOT_FND  ;λοδ ότοκ οϋιβλι 
        JNZ     ERR_EXIT        ;δα, οϋιβλα "ξετ ϊαπισι" 
        TEST    AL,8            ;λοδ οϋιβλι CRC ? 
        MOV     AH,BAD_CRC      ;λοδ ότοκ οϋιβλι 
        JNZ     ERR_EXIT        ;δα, οϋιβλα CRC 
        MOV     AH,BAD_FDC      ;λοδ οϋιβλι δχοκξοκ πμοτξοστι 
ERR_EXIT: 
        MOV     AL,AH           ; 
        OR      DISKETTE_STATUS,AL ;χ στατυσ δισλα λοδ οϋιβλι 
        STC                     ;υσταξοχλα ζμαηα CF=1 (οϋιβλα) 
NORM_EXIT: 
        POP     DX              ;χοσσταξοχμεξιε DX, AX 
        POP     AX 
        RET                     ;χοϊχςατ 
 
;============================================================== 
;       χωβος υστςοκστχα : DL-->ξον.υστς., DH-->ξον.ηομοχλι 
;============================================================== 
SELECT_DRIVE: 
        PUSH    AX              ;σοθς. ςεηιστςοχ 
        PUSH    CX 
        MOV     CL,DL           ;DL=0 δμρ υστς. 0,2(*) 
        MOV     AL,5            ;υστς. 0, νοτος 0 
        SAL     AL,CL           ;σδχιη πο ξονεςυ υστςοκστχα 
        MOV     AH,DH           ;ξονες ηομοχλι 
        AND     AH,1            ;νμ. βιτ 
        MOV     CL,4            ; 
        ROL     AH,CL           ;ξονες ηομοχλι χ ποϊ. D4 
        OR      AL,AH           ;υστς +νοτος +ηομοχλα 
        OR      AL,40H          ;+σβςοσ δχ. πμοτξοστι 
        OUT     RG_C,AL         ;χωχοδ (χωβος υστςοκστχα ) 
        POP     CX              ;χοσσταξοχμεξιε ςεηιστςοχ 
        POP     AX 
        RET                     ;χοϊχςατ 
 
;============================================================= 
;       π/π οφιδαξιρ δμρ νοτοςα. ϊαδεςφλα ολομο 0.5SEC. 
;============================================================= 
TEST_WAIT: 
        PUSH    AX 
        PUSH    BX 
        PUSH    CX 
        MOV     BL,1 
        IN      AL,MOTOR_EN     ;ώτ. σοστορξιρ νοτοςα --> D0 
        TEST    AL,1            ;νοτος χλμ (D0=0) ? 
        OUT     MOTOR_ON,AL     ;χλμ MOTOςα 
        JNZ     J36 
        TEST    DRIVER_N,DL 
        JNZ     J37 
 
J36:    MOV     CX,0 
DISK_TIME: 
        LOOP    DISK_TIME       ;ϊαδεςφλα 
        CLI 
        MOV     DRIVER_N,DL 
        STI 
        TEST    MOTOR_STATUS,80H  ;ώτεξιε? 
        JZ      J37             ;δα 
WAIT_WRITE:                     ;εσμι ϊαπισψ 
        MOV     CX,0 
        WAIT_TIME: 
        LOOP    WAIT_TIME       ;χςενρ δμρ ϊαπισι 
J37:    MOV     AH,4 
RET_RDY: 
        OUT     MOTOR_ON,AL     ;χλμ νοτοςα 
        MOV     CX,0 
WT_RDY: IN      AL,CONTROL_STAT ;ώτεξιε σοστορξιρ 
        AND     AL,80H          ;ηοτοχ? 
        JZ      END_RDY         ;δα 
        LOOP    WT_RDY          ;65535 ςαϊ οπςοσ 
        DEC     AH              ;ι χσε εύε 4 ςαϊα 
        JNZ     RET_RDY 
END_RDY: 
        POP     CX              ;χοσσταξοχμεξιε 
        POP     BX 
        POP     AX 
        RET                     ;χοϊχςατ 
 
 
STEP:   PUSH    CX 
        SUB     CX,CX            ;CX=0 
        MOV     CL,AL            ;FOR LOOP 
        XCHG    AL,AH 
        OR      AL,STEP_COMMAND 
STEPC:  OUT     CONTROL_STAT,AL  ;STEP_COMMAND AND DIR 
        PUSH    AX 
        IN      AL,RD_INTRQ 
        POP     AX 
        LOOP    STEPC 
        POP     CX 
        MOV     AL,CH 
        OUT     TRACK,AL 
        RET 
 
CODE    ENDS 
        end 

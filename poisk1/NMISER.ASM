 
;------------------------------------------------------------------------ 
;                                                                       ; 
;     *******          ��������� ������������ NMI            *******    ; 
;                                                                       ; 
;------------------------------------------------------------------------ 
NMI_SERVICE: 
        CLD 
        PUSH    ES 
        PUSH    DS 
        PUSH    DX 
        PUSH    CX 
        PUSH    BX 
        PUSH    SI 
        PUSH    DI 
        PUSH    AX 
        MOV     AX,DSEGMENT 
        MOV     DS,AX 
        MOV     AX,START_BUFFER   ;����� ������ ������ 
        MOV     ES,AX 
        IN      AX,TRAP_A 
        MOV     BX,AX 
        TEST    AH,40h 
        JNZ     IO_ROUTINES 
MWTC_ROUTINE:                     ;������������ ������������ ����� 
                                  ; (������ ������) 
        CLI                       ;������ ���������� 
        MOV     DI,BX 
        AND     DI,3FFEh          ;����� ����� ������ 
        MOV     DX,ES:[DI]        ;������ �������/�������� 
        SAR     DI,1 
        MOV     AX,DI 
        MOV     CL,AH 
        SAR     CL,1 
        SAR     CL,1 
        TEST    CRT_MODE,2        ;80x25 ? 
        JZ      MW4               ;���, 40x25 
        SAR     CL,1              ;CL = PageNo 
        MOV     CH,80             ;CH = 80 
        AND     AH,7 
MW2: 
        DIV     CH 
        XCHG    AH,AL 
        PUSH    AX 
        CBW 
        SUB     DI,AX 
        SAL     DI,1 
        SAL     DI,1 
        ADD     DI,AX 
        POP     AX 
        CMP     CL,ACTIVE_PAGE    ;�������� ��������? 
        JNE     AX_NMI 
        XOR     CH,CH 
        MOV     SI,CX 
        SAL     SI,1 
        CMP     AX,[SI+OFFSET CURSOR_POSN] 
        MOV     BX,EXTRA_BUFFER 
        MOV     ES,BX 
        PUSHF 
        JNE     MW3 
        CALL    REMOVE_CURSOR 
MW3: 
        PUSH    AX 
        MOV     AX,DX 
        MOV     BL,AH 
        XOR     AH,AH 
        MOV     CL,1 
        TEST    CRT_MODE,2        ;\80x25 ? 
        JNZ     MW31              ;\�� 
        and     di,0fffh          ;\ 
        JMP     MW32              ;\ 
MW31:   AND     DI,1FFFH          ;\ 
MW32:   CALL    S1B 
        POP     AX 
        POPF 
AX_NMI: 
        POP     AX 
NMI_RET: 
        JMP     VIDEO_RETURN      ;������� �� ������� �� ����� 
MW4: 
        MOV     CH,40 
        AND     AH,3 
        JMP     MW2 
 
IO_ROUTINES:                      ;���������� ��������� NMI 
                                  ;  (��������� � ������ �����) 
        TEST    AH,80h 
        JNZ     IOWC_ROUTINE 
 
IORC_ROUTINE: 
        POP     AX 
        MOV     AL,0FFh 
        JMP     VIDEO_RETURN 
 
IOWC_ROUTINE: 
        IN      AL,TRAP_D 
        MOV     SI,AX 
        CMP     BL,0D4h ;         ;���� 3D4 ? 
        JE      PORT_3D4 
        CMP     BL,0D5h           ;���� 3D5 ? 
        JE      PORT_3D5 
        CMP     BL,0D8h           ;���� 3D8 ? 
        JE      PORT_3D8 
        CMP     BL,0D9h           ;���� 3D9 ? 
        JNE     AX_NMI 
PORT_3D9: 
        XCHG    AL,AH             ;��������� �������������� ������ 
        IN      AL,SCR_MODE       ;������ ���� �������� ������ 
        AND     AX,37C8H          ;����� D7,D6 � D3 
                                  ;����� D4,D5 � D2..D0 
        OR      AL,AH             ;��������� ����� ���� 
        OUT     SCR_MODE,AL       ;������ ����� ����� ������ 
        JMP     AX_NMI 
PORT_3D4:                         ;������ � ���� 3D4 (����� 6845) 
        MOV     REG_6845,AL       ;��������� ��� � ������ 
        JMP     AX_NMI            ;��� ������� 
PORT_3D5: 
        MOV     CL,REG_6845       ;������������ ����� 
        CMP     CL,11 
        JNZ     REG10 
        MOV     BYTE PTR CURSOR_MODE,AL 
REG10:  CMP     CL,10 
        JNZ     REG14 
        MOV     BYTE PTR CURSOR_MODE+1,AL 
REG14: 
        CMP     CL,15             ;�������=15? 
        JE      REG_15 
        CMP     CL,14             ;�������=14? 
        JNE     AX_NMI            ;���� ������� �� 14 � �� 15, ������ �� ������ 
        MOV     CURSOR_POS_H,AL   ;��������� ������� ������� ������� 
        JMP     AX_NMI            ;��� ������� 
REG_15:                           ;������� 15 
        MOV     CURSOR_POS_L,AL   ;��������� ������ ������� ������� 
        MOV     AH,CURSOR_POS_H 
        TEST    CRT_MODE,2 
        JZ      R_15_2 
        MOV     CL,80 
R_15_1: 
        and     ax,07ffh 
 
        DIV     CL 
        XCHG    AL,AH 
        MOV     DX,AX 
        POP     AX 
        MOV     BH,ACTIVE_PAGE 
        JMP     SET_CPOS 
R_15_2: 
        MOV     CL,40 
        JMP     R_15_1 
PORT_3D8:                         ;���� 3D8 (���� ������) 
        AND     AL,1Fh            ;*** 
        JE      P_D8_RET 
        TEST    AL,8 
        JNZ     P_D8_RET 
        TEST    AL,12h               ;�������? 
        JNZ     P_D8_3               ;�� 
        XOR     AH,AH 
        TEST    AL,1                 ; 80X25 ? 
        JZ      P_D8_1               ;��� 
        MOV     AH,2 
P_D8_1: 
        TEST    AL,4                 ;�������? 
        JNZ     P_D8_2               ;��� 
        INC     AH 
P_D8_2: 
        XCHG    AL,AH 
        XOR     AH,AH 
        CMP     AL,CRT_MODE 
        JE      P_D8_RET          ;����� ��������� ������� ����� 
        INT     10h 
P_D8_RET: 
        JMP     AX_NMI 
P_D8_3: 
        MOV     AH,6 
        TEST    AL,10h                ; 640X200 ? 
        JNZ     P_D8_2                ; �� 
        DEC     AH 
        TEST    AL,4                  ;�������? 
        JNZ     P_D8_2                ;��� 
        DEC     AH 
        JMP     P_D8_2 
 
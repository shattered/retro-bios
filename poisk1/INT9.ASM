;--------------------------------------------------------------- 
; 
;              � � � � � � � � � �       I N T 9 
; 
;--------------------------------------------------------------- 
;         ����������� �.                    06.01.89 
;--------------------------------------------------------------- 
;    ��������� ��������� ���������� ���������� 
; 
; ��������� ��������� ��� ������������ ������� � ������� AL. 
; ��������� ��������� ������� 7 � ���� ������������ ��������, 
; ��� ������� ������. 
;   � ���������� ���������� ��������� � �������� AX ����������� 
; �����, ������� ���� �������� (AH) �������� ��� ������������, 
; � ������� (AL) - ��� ASCII. ��� ���������� ���������� � ����� 
; ����������. ����� ���������� ������ �������� �������� ������. 
; �������������� ����� 0:417 � 0:418 
;  ����������� � �������������� ��������: 
;        - SHIFT + PrintScreen 
;        - CTRL  + NumLock 
;        - ALT   + CTRL + DEL 
;------------------------------------------------------------- 
 
;----------------------- I N T 9 ----------------------------------- 
 
 
KB_INT  PROC    FAR 
        STI                   ;��������� ���������� 
        PUSH    AX 
        PUSH    BX 
        PUSH    CX 
        PUSH    DX 
        PUSH    SI 
        PUSH    DI 
        PUSH    DS 
        PUSH    ES 
 
        CLD                   ;����������� ������ 
 
;------ ��������� ��������� 
 
        PUSH    CS 
        POP     ES            ;ES=CS 
        MOV     AX,DATA 
        MOV     DS,AX         ;��������� �� ������� ������� 
        IN      AL,KB_DATA    ;������ ����_���� 
        MOV     AH,AL         ; (AH) - ����-��� 
 
;        CALL    DISP_HEX     ;  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
        AND     AL,7FH       ;����� ���� ������-������ 
        MOV     SI,OFFSET ALT_INPUT ; ��������� �� ���������� ���� ������� 
        MOV     DX,word ptr KB_FLAG    ; ��������� ����������� ������: 
                              ;           DL - KB_FLAG,  DH - KB_FLAG1 
 
;------ �������� �� ����_��� ����������� ������� 
 
K16: 
        MOV     DI,OFFSET K6   ;������� SHIFT KEY 
        MOV     CX,K6L         ;����� ������� 
        REPNE   SCASB          ;����� 
	JNE	K25	       ;�� ������������ ������� 
 
;------ ����������� ������� 
 
K17:                           ;(CL) - ���������� ������� 
        MOV     BH,80H 
        SHR     BH,CL          ;(BH) - ����� ������� ��� KB_FLAG 
 
        CMP     AH,AL          ;�������� �� ������� 
        JNZ     K23            ;���� ������� ������ 
 
;------ ����������� ������� ������ 
 
        CMP     BH,SCROLL_SHIFT 
        JAE     K18            ;���� ������� �� ��������� 
                               ; { Scroll,Num,Caps,Ins } 
 
;------ ������ ������� �� ���������  { Alt,Ctl,ShiftLeft,ShiftRigth } 
 
        OR      DL,BH           ;��������� ������ � KB_FLAG 
        JMP     SHORT K26       ;� ������ �� ���������� 
 
;------ ������ ������� �� ���������  { Scroll,Num,Caps,Ins } 
 
K18: 
        TEST    DL,CTL_SHIFT+ALT_SHIFT; 
        JNZ     K25                ; ��������� �� ������� ������� 
        CMP     AL,INS_KEY         ; �������� �� ��� INS 
        JNZ     K22 
 
;------ ������ ������� INS 
 
K19:    CALL    CALC_NUMKEY_SHIFT  ; ����������� ������� ������. ���������� 
        JZ      K22  ; �������������� ���������� � ����������� ��������� 
        ; �������������� ���������� � �������� ��������� 
        MOV     AL,'0'             ; ������ � ����� ����� '0' 
        JMP     SHORT K23E 
 
;------ ��������� KB_FLAG ��� ������� �� ���������  { Scroll,Num,Caps,Ins } 
 
K22: 
        TEST    BH,DH              ; ��������� ��������� ��� ����� �������? 
        JNZ     K26                ; ���� ��������� 
        OR      DH,BH              ; ��������� ���� - ������� ������ 
        XOR     DL,BH              ; �������� ������ 
        CMP     AL,INS_KEY         ; �������� INSERT KEY 
        JNE     K26                ; ���� ��� 
        JMP     KW0_BUF            ; ������ � ����� ���� ������� INS 
 
;------ ����������� ������� ������ 
 
K23: 
        CMP     BH,SCROLL_SHIFT 
        JAE     K24 
 
;------ ������ ������� �� ���������  { Alt,Ctl,ShiftLeft,ShiftRigth } 
 
        NOT     BH                 ; �������������� ����� 
        AND     DL,BH              ; c���� ���� �������� � KB_FLAG 
        CMP     AH,ALT_KEY+80H     ; ������ ������� ALT 
        JNE     K26                ; � ������ �� ��������� 
 
;------ ������ ������� ALT, ������ ������� � ����� 
;       ( ������ ��� ������ � �������� ���� ) 
 
        MOV     AL,[SI] 
        SUB     AH,AH              ; ����_���=0 
        MOV     [SI],AH            ; ����� ����-���������� 
        OR      AL,AL              ; ��� ������� = 0 ? 
        JE      K26                ; � ������ �� ���������� 
K23E:   JMP     KW_BUF             ; ������ ��������� ���� ������� � ����� 
 
 
;------ ������ ������� �� ���������  { Scroll,Num,Caps,Ins } 
 
K24: 
        NOT     BH                 ; �������������� ����� 
        AND     DH,BH              ; ����� ����-�������� � KB_FLAG1 
        JMP     SHORT K26          ; � ������ �� ���������� 
 
 
;------ ����-��� ������� ������� ----------------------------------------- 
 
K25: 
        CMP     AH,AL             ; �������� ���� �������/������� 
        JNE     K26A               ; ������� ������ 
        TEST    DH,HOLD_STATE      ; �������� ������-����� 
        JZ      K28                ; ����� ����� ����������� 
        ;�����_����� 
        CMP     AL,NUM_KEY 
        JE      K26A               ; ���� ����� ����� ������������ 
        AND     DH,NOT HOLD_STATE  ; ����� ������ ����� 
 
;------ ������� �� ���������� 
K26: 
        MOV     word ptr KB_FLAG,DX      ; ���������� ������ ������ ���������� 
K26A: 
        MOV     SCAN_CODE_OLD,AH; ����������� ����-���� 
        CLI                     ; ������ ���������� 
        MOV     AL,EOI          ; ������� - ����� ���������� 
        OUT     020H,AL         ; ������ ������� � ���������� ���������� 
K27: 
        POP     ES 
        POP     DS 
        POP     DI 
        POP     SI 
        POP     DX 
        POP     CX 
        POP     BX 
        POP     AX 
        IRET 
 
;-------------------------------------------------------------- 
;           ������� ����-��� ������� ������� 
;  ( ������������� ����-����� � �������������� ��������� ) 
;-------------------------------------------------------------- 
 
K28:    ;�������� �� �������������� ����-��� 
        CMP      SCAN_CODE_OLD,0E0H 
        JZ       K65AA        ; ���� �������������� ����-��� 
 
       ;�������� ��������� ����������� ������ 
       TEST    DL,ALT_SHIFT+CTL_SHIFT 
       JNZ     K70             ; ���� ���� ��� ��� ������� ������ 
 
;-------------------------------------------------------------- 
;    �������� � ������������ �������� ��� ALT � CTRL 
;-------------------------------------------------------------- 
 
K60:   CMP     RUSS,TRUE 
       JNE     K61 
 
 
;----- SERVICE RUSS  -  �������� � ������������ ������� �������� 
 
SERVICE_RUSS: 
        MOV     BX,offset KT_RUS0 
        CALL    CONTR_TABLE 
        JNZ     K61                     ; ���� �� ������� ����� 
SR2: 
        MOV     BX,offset LR 
        XLAT    CS:LR            ; ��������� ���� ������� 
        ; 
        MOV     CL,DL 
        AND     CL,LEFT_SHIFT+RIGHT_SHIFT+CAPS_STATE 
        JZ      SR3                     ; ������� ���������� �� ������ 
        CMP     CL,CAPS_STATE+1 
        JC      SR4                     ; ������ ������ ���� �� ������ 
                                        ; SHIFT1 ��� CAPS_STATE 
SR3:    ; ��������� ����� 
        CMP     AL,0F0h 
        JNZ     SR0 
        INC     AL 
        JMP     short SR4 
 
SR0:    ADD     AL,20H 
        CMP     AL,0B0H 
        JC      SR4 
        ADD     AL,30H 
SR4: 
        JMP     KW_BUF                  ; � ������ � ����� 
 
;----------------------------------------------------------------- 
;----- �������� � ������������ �� ������� ���� 
K61: 
       CMP      AL,71         ; �������������� ���������� ? 
       JAE      K65           ; �� 
 
;----- �������� ���������� 
 
       TEST     DL,LEFT_SHIFT+RIGHT_SHIFT 
       JNZ      K62 
 
       ; �������� ����������, ������� SHIFT �� ������ 
 
       MOV      BX, offset K10 
       CALL     CONTR_CODE 
       SUB      CL,CL 
       JMP      CONTR_FK 
 
       ; �������� ����������, ������� SHIFT ������ 
K62: 
 
K63:   ; �������� SHIFT + PrintScreen 
        CMP     AL,55           ; PRINT SCREEN KEY 
        JNE     K64 
        ; ���������� ����������� ������ 
        MOV     AL,EOI 
        OUT     020H,AL 
        INT     5H              ; 
        JMP     K27             ;  ������� ��� ���. ������������ ���������� 
 
K64:    MOV     BX,offset K11 
        CALL     CONTR_CODE 
        MOV     CL,84-59 
        JMP      CONTR_FK 
 
;------ �������������� ���������� 
 
K65:   CALL    CALC_NUMKEY_SHIFT  ; ����������� ������� ������. ���������� 
       MOV     BX, offset K14     ; ���. ���������� � �������� ��������� 
       JNZ     K65A 
K65AA: MOV     BX, offset K15     ; ���. ���������� � ����������� ��������� 
K65A:  CALL    CONTR_CODE 
       JMP     K26 
 
;----------------------------------------------------------------- 
;----- ������ ALT �/��� CTL -------------------------------------- 
;----------------------------------------------------------------- 
 
K70:    TEST    DL,ALT_SHIFT 
        JZ      K80            ; ���� ALT �� ������ (������ CTRL) 
 
;----- �������� �� ���������� ALT + CTL + DEL 
 
        CMP     AL,DEL_KEY 
        JNE     K71             ; ��� ������ 
 
        MOV     RESET_FLAG,1234H ; ��������� ���������� ��� ������� ������ 
        JMP     RESET           ; ������� �� ����� 
 
 
;-------------------------------------------------------------- 
;    �������� � ������������  ��������  � ALT 
;-------------------------------------------------------------- 
 
K71:    ; �������� �� ����� �������������� ���������� 
        CMP     AL,71 
        JB      K72 
        CMP     AL,82 
        JA      K72 
        MOV     BX,offset  K14+2-71 
        XLAT    CS:K14 
        SUB     AL,'0' 
        JC      K72 
        ;���������� ���� ������� 
        XCHG    [SI],AL 
        MOV     AH,10 
        MUL     AH 
        ADD     [SI],AL 
        JMP     K26             ; ����� �� ���������� 
 K72: 
        MOV     AL,AH 
        MOV      byte ptr[SI],0        ; ����� ������������ ���� 
 
        MOV     BX,offset KT_ALT ;A..Z, 0..9, -, + 
        CALL    CONTR_TABLE     ; �������� � ������������� ���� ����� 
        CMP     CL,84 
        JZ      K72A            ; ���� ��� ��������� KT_ALT 
        CMP     CL,2            ; �������� �� ����-���� 0..9-+ 
        JNZ     K72AA 
        ADD     AH,118          ; ���� � ���������  0..9-+ 
K72AA:  JMP     KW0_BUF 
 
K72A:   MOV     CL,104-59       ; ���������� ��� ��������� ������ ����-���� 
        JMP     CONTR_FK        ; �������� �� �������������� ������� 
 
 
;-------------------------------------------------------------- 
;    �������� � ������������  ��������  � CTRL 
;-------------------------------------------------------------- 
K80: 
        MOV     BX, offset K8   ; �������� ���������� + CTRL 
        CALL    CONTR_CODE 
        MOV     BX, offset K9  ; �������������� ���������� + CTRL 
        CALL    CONTR_CODE 
 
;       �������� �������������� ������ 
        CMP     AL,SCROLL_KEY   ; �������� ������� "BREAK" 
        JNE     K81             ; �� "BREAK" 
 
        ;"BREAK" 
        ;������� ������ ����� 
        MOV     AX,BUFFER_HEAD 
        MOV     BUFFER_TAIL,AX 
        MOV     BIOS_BREAK,80H  ; ������� BREAK �� ���������� 
        INT     1BH             ; ������ ���������� ��������� BREAK 
        SUB     AX,AX           ; ������ ������ 
        JMP     KW_BUF          ; � ������ � ����� 
 
K81: 
        CMP     AL,NUM_KEY      ; �������� ������� "PAUSE" 
        JNE     K82             ; NO-PAUSE 
 
        ;"PAUSE" 
        OR      KB_FLAG_1,HOLD_STATE ; ���������� ���� "PAUSE" 
        MOV     W_SCAN,FALSE   ; ���������� ���������� ����� � SCANINT 
        MOV     AL,EOI 
        OUT     020H,AL 
        ; 
;        CMP     CRT_MODE,7     ; IS THIS BLACK AND WHITE CARD 
;        JE      K81A           ; YES,NOTHING TO DO 
;        MOV     DX,03D8H       ; PORT FOR COLOR CARD 
;        MOV     AL,CRT_MODE_SET        ; GET THE VALUE OF THE CURRENT MODE 
;        OUT     DX,AL          ; SET THE CRT MODE,SO THAT CRT IS ON 
 
K81A:   ; ���� �������� ��������� ����� 
        TEST    KB_FLAG_1,HOLD_STATE 
        JNZ     K81A 
        JMP     K27            ; � ������ �� ���������� 
 
K82: 
       ; �������� CTRL+PrintScreen 
        CMP     AL,55 
        JNE     K83 
        MOV     AH,114     ; START/STOP PRINTING SWITCH 
        JMP     KW0_BUF         ; � ������ � ����� 
 K83: 
        MOV     CL,94-59        ; ���������� ��� ��������� ������ ����-���� 
 
;----------------------------------------------------------------------- 
;     �������� �������������� ������ � ������� 
;      (CL) - ���������� ��� ��������� ������ ����_���� 
 
CONTR_FK: 
         ; �������� �� ������ 
         CMP     AL,57 
         JNE     C_FK1 
         MOV     AL,' ' 
         JMP     SHORT KW_BUF 
C_FK1:   ; �������� �� �������������� ������� 
         CMP     AL,59 
         JB      K90A 
         CMP     AL,68 
         JA      K90A 
         ADD     AH,CL 
 
;---------------------------------------------------------------------- 
;------- ������ � ����� 
 
KW0_BUF: SUB    AL,AL 
KW_BUF: 
 
;        CALL    DISP_AX     ;  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
 
        ; ��������� ����_���� (AH) � ���� ������� � ����� (AL) 
        MOV     BX,BUFFER_TAIL ; GET THE END POINTER TO THE BUFFER 
        MOV     SI,BX         ; SAVE THE VALUE 
        CALL    K4            ; ADVANCE THE TAIL 
        CMP     BX,BUFFER_HEAD ; HAS THE BUFFER WRAPPED AROUND 
        JE      K90           ; BUFFER_FULL_BEEP 
        MOV     [SI],AX        ; STORE THE VALUE 
        MOV     BUFFER_TAIL,BX ; MOVE THE POINTER UP 
        JMP     K90A           ; INTERRUPT RETURN 
 
;------ BUFFER IS FULL,SOUND THE BEEPER 
 
K90:                          ; BUFFER-FULL-BEEP 
 
;        MOV     AL,EOI 
;        OUT     20H,AL 
        MOV     BX,0504H       ; 
        CALL    BEEP 
K90A:   JMP     K26           ; INTERRUPT_RETURN 
 
 
KB_INT ENDP 
 
;========================================================================= 
 
;      ����������� ������� ������. ���������� 
;      �����: 
;        Z=TRUE   -   ����������� ���������� 
;        Z=FALSE  -   �������� ���������� 
 
 CALC_NUMKEY_SHIFT  PROC NEAR 
       MOV     BL,DL 
       AND     BL,NUM_SHIFT+LEFT_SHIFT+RIGHT_SHIFT 
       JZ      CALC_END 
       CMP     BL,NUM_SHIFT+1 
       JB      CALC_END 
       CMP     AL,AL    ;��������� ����� Z 
CALC_END: RET 
CALC_NUMKEY_SHIFT  ENDP 
 
;========================================================================= 
 
;      ������������� �������� � ��������� ������ ���������� 
;      (BX) - ��������� �� ��������� 
;              <���><����><����������> 
;       �����: ���� Z=0  - ��������� ����� 
;              ���� Z=1  - ������� �����, (AL)- ���������� ����� 
 
 
 
CONTR_TABLE PROC  NEAR 
       PUSH    DX 
       SUB     DL,DL       ; ��������� �������� 
CT0:   MOV     CX,CS:[BX] 
       CMP     AL,CL 
       JB      CTE 
       CMP     AL,CH 
       JBE     CT00 
 
       ;��� ��� ��������� 
       SUB     CH,CL 
       ADD     DL,CH         ;���������� ��������� ����� ���������� 
       INC     DL 
       ADD     BX,2 
       CMP     CL,83 
       JB      CT0 
       JMP     SHORT CTE 
       ;��� ������ ��������� 
CT00:  SUB     AL,CL 
       ADD     AL,DL 
       CMP     AL,AL   ; ��������� ����� Z 
CTE:   POP     DX 
       RET                   ;����� - ������� ����� 
 
CONTR_TABLE ENDP 
 
 
;========================================================================= 
 
;      ������������� �������� � ��������� ��������� 
;      (BX) - ��������� �� ��������� 
;             <���><����><�������> 
; 
CONTR_CODE PROC  NEAR 
       MOV     CX,CS:[BX] 
 
;       PUSH    AX          ;  !!!!!!!!!!!!!!!!! 
;       MOV     AL,'=' 
;       CALL    DISP_CHAR 
;       MOV     AX,CX 
;       CALL    DISP_AX 
;       POP     AX 
       CMP     AL,CL 
       JB      CC_END 
       CMP     AL,CH 
       JA      CC_END 
 
 
       ; ����-��� ��������� � ���������� ��������� 
       SUB     AL,CL ; ����������� �������� ������������ ������������ ���� 
       ADD     AL,2 
       XLAT    CS:K10 
       POP     CX    ; �������� �� ����� ������ �������� 
       TEST    AL,80H; �������� ������������ ������ ����_���� 
       JNZ     CC_C1; ���� ������ ��� 
 
       ; �������� �� ��������� ����� 
       CMP     AL,'a' 
       JB      CC_C0 
       CMP     AL,'z' 
       JA      CC_C0 
       ; ��������� ����� - ������ ��������� ���. ������ 
       MOV     CL,DL 
       AND     CL,LEFT_SHIFT+RIGHT_SHIFT+CAPS_STATE 
       JZ      CC_C0                    ; ������� ���������� �� ������ 
       CMP     CL,CAPS_STATE+1 
       JAE     CC_C0                     ; ������ ������ ���� �� ������ 
       SUB     AL,'a'-'A' 
CC_C0: JMP     KW_BUF 
 
CC_C1: ; �������� ������������ ����_���� 
       CMP     AL,0FFH 
       JZ      K90A   ;����������� ����_��� 
       CMP     AL,0FEH 
       JNZ     CC_C2; 
       MOV     AH,132 
       JMP     KW0_BUF 
 
CC_C2: ; ������ ����_��� 
       AND     AL,7FH 
       MOV     AH,AL 
       JMP     KW0_BUF 
 
CC_END: RET 
CONTR_CODE ENDP 
 
;======================================================================= 
;      ���������� ��������� ���������� ������ ����� 
;      (BX) - ��������� 
 
K4      PROC    NEAR 
 
        ADD     BX,2          ;������� � ���������� ����� 
        CMP     BX,OFFSET KB_BUFFER_END ; ����� ������ ? 
        JNE     K5            ;����� ������ �� ��������� 
        MOV     BX,OFFSET KB_BUFFER ;� ������ ������ (�� ������) 
K5:     RET 
K4      ENDP 
 
;========================================================================= 
 
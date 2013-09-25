;--------------------------------------------------------------------------- 
; ��������� ����-���������, ������������� 
;--------------------------------------------------------------------------- 
        ASSUME  CS:CODE, DS:DATA 
RESET   LABEL   NEAR 
START:  CLI                          ;����� ����� � BIOS (�� ������, 
                                     ;�� ��������� �������) 
        IN      AL,TRAP_A            ;����� �������� NMI 
        MOV     AL,89H               ;��������� ������ 8255 (TRAP) 
        OUT     PPIC,AL 
        MOV     AL,88H               ;��������� ������ 
        OUT     SCR_MODE,AL 
        IN      AL,TRAP_A            ;����� �������� NMI 
        MOV     AL,83H               ;��������� ������ 8255 (KBD) 
        OUT     KEY_SERV_MODE,AL     ;��������� ������ ���������� 
; �������� ���������� ������������������ ���, ���� ��� ���� 
        MOV     AX,0C000H 
        SUB     BX,BX 
        MOV     DS,AX 
        CMP     DS:[BX],055AAH 
        JNZ     ST0 
        JMP     KARTRIDJ+3 
 
ST0:    SUB     AX,AX 
        MOV     ES,AX                ;�������=0 
        XOR     DI,DI 
        MOV     CX,0FFFFH 
        CLD                          ;������� ������� ������=64� 
        REP     STOSB 
        MOV     CX,0800H 
        MOV     ES,CX 
        MOV     DI,8000H 
        MOV     CX,DI 
        CLD 
        REP     STOSB 
        MOV     ES,AX                ;�������=0 
        XOR     DI,DI 
        MOV     CX,0FFFFH 
        CLD                          ;������� ������� ������=64� 
        REP     SCASB 
        CMP     CX,0 
        JZ      CLR1 
        HLT 
CLR1:   MOV     CX,0800H 
        MOV     ES,CX 
        MOV     DI,8000H 
        MOV     CX,DI 
        CLD 
        REP     SCASB 
        CMP     CX,0 
        JZ      CLR2 
	MOV	DX,04 
	CALL	BEEP_ERROR 
        HLT 
 
CLR2: 
        MOV     ES,AX 
	MOV	SS,AX 
	MOV	SP,03FFH 
        PUSH    CS                   ;��������� ������� ����������: 
        PUSH    CS 
        POP     BX 
        POP     DS 
        MOV     CX,1EH               ;��������� �������� �������� 
        MOV     SI,OFFSET VECTOR_TABLE      ;�������� ������� �������� 
        MOV     DI,OFFSET INT5_PTR 
SM0:    LODSW                        ;��������� ������� �������� 
        STOSW                        ;(������ ������������ ����������) 
        MOV     AX,BX 
        STOSW 
        LOOP    SM0 
        MOV     DI,8 
        MOV     AX,OFFSET NMI_SERVICE ;������� ������� NMI 
        STOSW 
        MOV     AX,BX 
        STOSW 
        MOV     AX,DATA 
        MOV     ES,AX 
        MOV     CX,10H               ;������ TEST_TABLIC 
        MOV     SI,OFFSET TEST_TABLIC ;(������� ������������) 
        MOV     DI,OFFSET RS232_BASE 
        REP     MOVSW 
	SUB	AX,AX 
IX0:    ADD     AX,4000H 
	PUSH	AX 
	MOV	DS,AX 
	SUB	BX,BX 
	MOV	AX,5AA5H 
	MOV	[BX],AX 
	NOT	AX 
	NOT	WORD PTR [BX] 
	CMP	WORD PTR [BX],AX 
	POP	AX 
	PUSH	ES 
	POP	DS 
	JNZ	IX1 
	ADD	MEMORY_SIZE+1,1 
	JMP	IX0 
IX1:    MOV     MOTOR_STATUS,1 
    ;;; MOV     EMPTY,0            ; ���������� ������ 
        MOV     FBEEP,TRUE 
    ;;;	MOV	RUSS,FALSE 
    ;;; MOV     SHIFT1,LEFT_KEY    ; ������� ������ 
        MOV     AL,13H                ;���������� ����� 8259 
        OUT     INTA00,AL             ;���������� ���������� 
        MOV     AL,8 
        OUT     INTA01,AL 
        MOV     AL,9 
        OUT     INTA01,AL 
        MOV     AL,36H               ;���������� ����� 8253 
        OUT     TIM_CTL,AL           ;������ 
        XOR     AL,AL 
        OUT     TIMER0,AL            ;����� 0 
        OUT     TIMER0,AL 
        MOV     AL,76H 
        OUT     TIM_CTL,AL 
        XOR     AL,AL 
        OUT     TIMER0+1,AL          ;����� 1 
        OUT     TIMER0+1,AL 
 
; ��������� ������ VIDEO 
 
        MOV     AX,0003H 
        INT     10H 
 
; ���� BIOS 
        PUSH    DS 
        PUSH    CS 
        POP     DS 
        MOV     BX,0E000H 
        MOV     CX,2000H 
        CALL    ROS_CHECKSUM         ;�������� ����������� ����� 
        JZ      IX2 
        MOV     DX,3 
        CALL    BEEP_ERROR 
        HLT 
; ��������� ��������� �������� �������� ���������� 
IX2:    POP     DS 
        MOV     BYTE PTR TRACK_PTR,0H 
        MOV     BYTE PTR TRACK_PTR+1,0H 
;���������� ���������� �������� ������ �������� 
 
        MOV     WORD PTR LOAD_ADDR,0060H 
        STI                          ;��������� ���������� 
 
; ������ �������� 
 
; �������� � ������������� ��� � ���������� 
 
        MOV     DX,0C000H 
ROM_CH0: 
        MOV     DS,DX 
        SUB     BX,BX 
        CMP     [BX],0AA55H 
        JNE     ROM_CH1 
        CALL    ROM_INIT 
ROM_CH1: 
        ADD     DX,20H 
        CMP     DX,0FE00H 
        JL      ROM_CH0 
SYS_BOOT: 
        PUSH    DS 
        INT     19H                  ;�������� ������� 
        POP     DS 
        INT     18H                  ;�������� ���������� ��� 
                                     ;��� ������ � �������� 
 
 
 
 
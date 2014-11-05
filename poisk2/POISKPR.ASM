PAGE 64,132
Title IVK_BIOS v1.2A 1990.4

;********************************************************
;*	BIOS для компьютера ПОИСК  			*
;********************************************************

;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include BiosEqu.ASM					;
include BiosEqu1.ASM					;



;---------------ДАННЫЕ КМОП---------------------------------------------
BAD_MEMORY	EQU     01H	; ОШИБКА БАЗОВОЙ ПАМЯТИ
SHUT_DOWN	EQU	0fh
CMOS_PORT	EQU	070H	;АДРЕСС КМОП ПОРТА
CLK_UP		EQU	0AH	;РЕГИСТР СТАТУСА
CMOS_ALARM	EQU	0BH
CMOS_BEGIN	EQU	010H
CMOS_END	EQU	020H
BATTERY_COND_STATUS EQU 08DH	;СТАТУС ПИТАНИЯ
M_SIZE_HI	EQU	16H	;РАЗМЕР ПАМЯТИ СТАРШИЙ БАЙТ
M_SIZE_LO	EQU	15H	;РАЗМЕР ПАМЯТИ МЛАДШИЙ БАЙТ
M1_SIZE_HI	EQU	18H	;РАЗМЕР РАСШИРЕННОЙ ПАМЯТИ СТАРШИЙ БАЙТ
M1_SIZE_LO	EQU	17H	;МЛАДШИЙ БАЙТ
;---------------КМОП ДИАГНОСТИКА            ----------------------------
DIAG_STATUS	EQU	0EH	;БАЙТ ДИАГНОСТИКИ
BAD_BAT 	EQU	080H	;ПЛОХОЕ ПИТАНИЕ
BAD_CKSUM	EQU	040H	;ОШИБКА КОНТРОЛЬНОЙ СУММЫ
W_MEM_SIZE	EQU	010010B	;НЕПРАВИЛЬНЫЙ РАЗМЕР ПАМЯТИ  10H
;HF_FAIL 	EQU	008H	;HARD FILE FAILURE ON INIT
CMOS_CLK_FAIL	EQU	004H	;CMOS CLK NOT UPDATING OR NOT VALID
;---------------CMOS INFORMATION FLAGS----------------------------------
;INFO_STATUS	EQU	0B3H	;CMOS ADDRESS OF INFO BYTE
;M640K		EQU	080H	;512K --> 640K CARD INSTALLED

;- - - - - - - - - - - - - - - - - - - - - - - - - - - -

;* * * * * * * * * * * * * * * * * * * * * * * * * * * *
;	КОД ПЗУ          				;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * *

CODE    SEGMENT
	org	0c000h
	db	21h
	db	43h
	db	0eah
	db	70h
	db	0e0h
	db	0
	db	0bch	

        ORG     0C05BH
        Assume  CS:CODE,SS:NOTHING,ES:NOTHING,DS:DATA
include  d3.asm         ;ПРОЦЕДУРЫ         INT	13H
include  d2.asm         ;ПРОЦЕДУРЫ         INT	13
include  d7.asm
;	ORG	   0CFF1H
        Assume  CS:CODE,SS:NOTHING,ES:NOTHING,DS:NOTHING
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include W64.ASM						;
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include HD_SETUP.ASM					;
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include IVK_Tit.ASM					;
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include AltGen.ASM					;
;----------------------------------------------------(-


        ORG        0E000H

IVK	label	BYTE
        DB      13,10,13,10,13,10,0,0
	DB      'Bios POISK (C) 1991'
	DB      ' Version 2.1B'
        DB      0,0
        DB      'CPU 8086',0,0,0
;-------------------------------------------------------

        ORG     0E05BH
RESET		label	FAR
RESET_NEAR	label	NEAR

START:
	CLI
	MOV	BX,0C800H
	MOV	DS,BX
	XOR	BX,BX
	MOV	BX,DS:[BX]
	CMP	BX,4321H
	JNE	NOT_BIOS	
	DB	0EAH
	DB	2
	DB	0
	DB	0
	DB	0C8H
;-----EGA РЕЖИМ И ГАШЕНИЕ ЭКРАНА
NOT_BIOS:
        MOV     DX,3DFH
        XOR     AL,AL
        OUT     DX,AL
        MOV	DX,3D8H
        OUT	DX,AL
;----------------------------------------------------------------------------
;	ТЕСТ РЕГИСТРОВ R0...R3 УСТРОЙСТВА EMS ОЗУ И ДЕШИФРАТОРА
;       		ФИЗИЧЕСКИХ АДРЕСОВ ОЗУ
;------------------------------------------------------------------------------
	MOV	DL,0FFH
LP2:	MOV	CX,100H
LP1:	OUT	0E0H,AL      ;- адрес для статики
	XCHG	AL,DL
	OUT	0F0H,AL	     ;- значение
	XCHG	AL,DL
        INC	AL
	LOOP	LP1
;---------------------------------------------------
;   ОБНУЛЕНИЕ DIAG_STATUS
;---------------------------------------------------
	MOV	AL,DIAG_STATUS
	OUT	CMOS_PORT,AL
	IN	AL,CMOS_PORT+1
	AND	AL,10B          ;ОСТАВЛЯЕМ БИТ ВНЕШНЕГО ТЕСТА ПАМЯТИ
	XCHG	AL,AH
	MOV	AL,DIAG_STATUS
	OUT	CMOS_PORT,AL
	XCHG	AL,AH
	OUT	CMOS_PORT+1,AL
;--------------------------------------------------------------------
; TEST 12
;	 ПРОВЕРКА КОНТРОЛЬНОЙ СУММЫ/РАБОТОСПОСОБНОСТИ CMOS
; ОПИСАНИЕ
;	 ОПРЕДЕЛЯЕТСЯ СЛЕДУЕТ ЛИ ИСПОЛЬЗОВАТЬ ЗАПИСЬ КОНФИГУРАЦИИ
;--------------------------------------------------------------------

  	ASSUME DS:DATA
        MOV     AX, DATA
        MOV     DS,AX           ;SET SEGMENT
; ДОСТАТОЧНОЕ ЛИ НАПРЯЖЕНИЕ БАТАРЕИ ?

  	MOV	 AL,0DH                 ;ПРОВЕРКА СОСТОЯНИЯ БАТАРЕИ
  	OUT	 CMOS_PORT,AL		;УКАЗАТЕЛЬ НА СОСТОЯНИЕ БАТАРЕИ
  	IN	 AL,CMOS_PORT+1
  	TEST	 AL,80H 		;НИЗКОЕ НАПРЯЖЕНИЕ ?
  	JNZ	 CMOS1  		;ПЕРЕХОД ЕСЛИ GOOD

; УСТАНОВКА ФЛАГА НЕИСПРАВНОСТИ БАТАРЕИ
CMOS1A:
	MOV	AL,DIAG_STATUS
	OUT	CMOS_PORT,AL
	IN	AL,CMOS_PORT+1
  	XCHG	 AL,AH			;ЗАПОМНИТЬ
  	OR	 AH,BAD_BAT		;УСТАНОВИТЬ ФЛАГ НЕИСПРАВНОСТИ БАТАРЕИ
  	MOV	 AL,0EH			;DIAG_STATUS
  	OUT	 CMOS_PORT,AL
  	XCHG	 AL,AH			;ВЫВЕСТИ СОСТОЯНИЕ
  	OUT	 CMOS_PORT+1,AL 	;УСТАНОВИТЬ ФЛАГ В CMOS
;--ПРОГРАМИРУЕМ ДЕЛИТЕЛЬ ЧАСОВ
	MOV	AL,0AH
	OUT	70H,AL
	MOV	AL,00100000B
	OUT	71H,AL
	MOV	AL,0BH
	OUT	70H,AL
	MOV	AL,00100001B
	OUT	71H,AL 
	JMP      short CMOS3            ;ПЕРЕЙТИ НА МИНИМАЛЬНУЮ КОНФИГУРАЦИЮ

; ПРОВЕРКА КОНТРОЛЬНОЙ СУММЫ
CMOS1:
  	SUB	 BX,BX
  	SUB	 CX,CX
  	MOV	 CL,CMOS_BEGIN		;УСТАНОВИТЬ НАЧАЛО CMOS
  	MOV	 CH,CMOS_END		;УСТАНОВИТЬ КОНЕЦ CMOS
CMOS2:
	MOV	 AL,CL
	OUT	 CMOS_PORT,AL		;НАЧАЛЬНЫЙ АДРЕС
  	IN	 AL,CMOS_PORT+1
  	SUB	 AH,AH			;ГАРАНТИЯ AH=0
  	ADC	 BX,AX			;ДОБАВИТЬ К ТЕКУЩЕМУ ЗНАЧЕНИЮ
  	INC	 CL			;УКАЗАТЕЛЬ НА СЛЕДУЮЩЕЕ СЛОВО
  	CMP	 CH,CL			;ЗАКОНЧИТЬ ?
  	JNZ	 CMOS2			;ПЕРЕХОД ЕСЛИ НЕТ
  	OR	 BX,BX			;BX ДОЛЖЕН БЫТЬ 0
  	JZ	 CMOS3			;CMOS ПЛОХОЙ ЕСЛИ CKSUM=0
  	MOV	 AL,2EH 		;ВЗЯТЬ КОНТРОЛЬНУЮ СУММУ
  	OUT     CMOS_PORT,AL
  	IN	 AL,CMOS_PORT+1 	;ПЕРВЫЙ БАЙТ КОНТРОЛЬНОЙ СУММЫ
  	MOV	 AH,AL			;ЗАПОМНИТЬ ЕГО
  	MOV	 AL,2FH 		;СЛЕДУЮЩИЙ БАЙТ
  	OUT	 CMOS_PORT,AL
  	IN	 AL,CMOS_PORT+1
  	CMP	 AX,BX			;КОНТРОЛЬНАЯ СУММА OK ?
  	JZ	 CMOS4			;ПЕРЕХОД ЕСЛИ ДА

; УСТАНОВКА ОШИБКИ КОНТРОЛЬНОЙ СУММЫ CMOS
CMOS3:
	MOV	AL,DIAG_STATUS
	OUT	CMOS_PORT,AL
	IN	AL,CMOS_PORT+1
  	XCHG	 AL,AH			;ЗАПОМНИТЬ
  	OR	 AH,BAD_CKSUM		;УСТАНОВИТЬ ФЛАГ BAD CHECKSUM
  	MOV	 AL,DIAG_STATUS
  	OUT	 CMOS_PORT,AL
  	XCHG	 AL,AH			;УСТАНОВИТЬ ФЛАГ
  	OUT	 CMOS_PORT+1,AL
CMOS4:
;-----------------------------------------------
; ПОДСТРАХОВКА КОГДА ПРЕРЫВАНИЕ ЧАСОВ CMOS ЗАПРЕЩЕНО
; ЗАПРЕЩАЮТСЯ ПРЕРЫВАНИЯ
;--------------------------------------------------
       	MOV	 AL,CMOS_ALARM
       	OUT	 CMOS_PORT,AL
       	IN	 AL,CMOS_PORT+1 	;ВЗЯТЬ ЗНАЧЕНИЕ РЕГИСТРА КОНТРОЛЯ

       	XCHG	 AL,AH			;ЗАПОМНИТЬ
 	AND	 AH,01000111b           ;07 ;ОЧИСТИТЬ SET, PIE, AIE, UIE И SQWE БИТЫ

 	MOV	 AL,CMOS_ALARM
 	OUT	 CMOS_PORT,AL
  	XCHG	 AL,AH
  	OUT	 CMOS_PORT+1,AL

  	MOV	 AL,CMOS_ALARM+1	;ОЧИСТИЬ ОТЛОЖЕННОЕ ПРЕРЫВАНИЕ
  	OUT	 CMOS_PORT,AL
  	IN	 AL,CMOS_PORT+1
;-------------------------------------------------------
;   	ИНИЦИАЛИЗАЦИЯ  8237  И  8253 ДЛЯ РЕГЕНЕРАЦИИ ПАМЯТИ
;-------------------------------------------------------
IVK_RES:
        SUB     AX,AX
        OUT     0A0H,AL         ; ЗАПРЕТ ПРЕРЫВАНИЙ
        OUT     83H,AL          ; ИНИЦИАЛИЗАЦИЯ РЕГИСТРА СТРАНИЦ
	OUT     DMA+0DH,AL	; ПОСЫЛАЕМ ДАННЫЕ В DMA
        MOV     AL,4
        OUT     DMA08,AL
;------ установка режима для 8255A
	MOV     AL,99H
        OUT     CMD_PORT,AL
;------ установка режима для таймера 0
	MOV     AL,36H
        OUT     TIM_CTL,AL
        MOV     AL,0
        OUT     TIMER0,AL
        OUT     TIMER0,AL
;------ установка режима для таймера 1
        MOV     AL,54H
        OUT     TIM_CTL,AL
        MOV     AL,19      ;32  ;инициализация регенерации
        OUT     TIMER0+1,AL
;------ установка режима для таймера 2
        MOV     AL,0B6H
        OUT     TIM_CTL,AL
        MOV     AL,0FFH
        OUT     TIMER0+2,AL
        MOV     AL,8
        OUT     TIMER0+2,AL
;------ установка режима для  DMA
	MOV     AL,0FFH
        OUT     DMA+1,AL
        OUT     DMA+1,AL
        MOV     AL,58H
        OUT     DMA+0BH,AL
        MOV     AL,20H           ; EXTENDED WRITE OPERATION,FIX. PRIORITY,
        OUT     DMA08,AL         ; HIGH DRQ, LOW DACK, ENABLE CONTROLLER
        OUT     DMA+0AH,AL       ; RESET ALL MASK'S  (SET TO 0)
;-------------------------------------------------------
;   ИНИЦИАЛИЗАЦИЯ КОНТРОЛЛЕРА ПРЕРЫВАНИЙ 825; " 	;
;-------------------------------------------------------
        MOV     AL,13H
        OUT     INTA00,AL
        MOV	AL,8
        OUT     INTA01,AL
        MOV     AL,9
        OUT     INTA01,AL
        MOV     AL,0FFH
        OUT     INTA01,AL
;-------------------------------------------------------
;   ИНИЦИАЛИЗАЦИЯ ВТОРОГО ТАЙМЕРА 8253   		;
;-------------------------------------------------------
	MOV	DX,TIM2_CTL
;------ установка для RS232-C
	MOV     AL,36H
        OUT     DX,AL
        MOV     AL,0
        SUB	DL,3
        OUT     DX,AL
        OUT     DX,AL
;------ установка для адаптера мыши
	MOV     AL,76H
        ADD	DL,3
        OUT     DX,AL
        MOV     AL,0FFH
        SUB	DL,2
        OUT     DX,AL
        OUT	DX,AL
;------ установка для игрового адаптера
	MOV     AL,0B6H
        ADD	DL,2
        OUT     DX,AL
        MOV     AL,80H
	DEC	DX
        OUT     DX,AL
        MOV     AL,0
        OUT     DX,AL
;--ПОДГОТОВКА НЕКОТОРЫХ РЕГИСТРОВ ДЛЯ ТЕСТА ПАМЯТИ
        XOR     BX,BX
        MOV     DS,BX
;-----------------------------------------;
; ПРОВЕРКА CMOS				  ;
; LOK_3: - ВНЕШНИЙ ТЕСТ                   ;
; LOK_7: - ВНУТРЕННИЙ ТЕСТ                ;
;-----------------------------------------;
	CLD
	MOV	AL,DIAG_STATUS
	OUT	CMOS_PORT,AL
	IN	AL,CMOS_PORT+1
	TEST	AL,0C0H
 	JNZ	LOK_7
 	TEST	AL,10B
     	JZ	LOK_3   	; ПАМЯТЬ ХОРОШАЯ НЕТ НЕОБХ. ИЗ КМОП
;------------------------------------;
; ВНУТРЕННИЙ ТЕСТ                    ;   
; ОБНУЛЕНИЕ КАРТЫ КМОП 19H - 29H     ;   
; И ТЕСТ НУЛЕВОГО СЕГМЕНТА           ;   
; В СЛУЧАЕ ОШИБКИ СДВИГ ПАМЯТИ ВВЕРХ ;
;------------------------------------;
MEMORY_PROC   EQU   0E0H
MEMORY_CHIP   EQU   0F0H
LOK_7: 
;---------ОБНУЛЕНИЕ ЯЧЕЕК КМОП
        MOV     CX,10H
        MOV     BL,19H
LOK_8:
        MOV     AL,BL
        OUT     CMOS_PORT,AL
        XOR     AL,AL
        OUT     CMOS_PORT+1,AL
        INC     BL
        LOOP    LOK_8

;---------------------------------
; ПОИСК ХОРОШЕГО 0 СЕГМЕНТА В КМОП
; И ПОСЛЕДУЮЩАЯ ПРОВЕРКА
; AL - ЯЧЕЙКА КМОП
; DH - БЛОК
;---------------------------------
MAP_BEGIN       EQU     19H
LOK_3:
;----ПОИСК В КМОП ПЕРВОГО ХОРОШЕГО СЕГМЕНТА
        MOV     DX,100H
        MOV     AL,MAP_BEGIN
MEM_2:
        OUT     CMOS_PORT,AL
        XCHG    AH,AL
        IN      AL,CMOS_PORT+1
        XCHG    AH,AL
        TEST    AH,DH
        JZ      MEM_1
MEM_2P:
	INC	DL
        SHL     DH,1    ;D7 --> CF
        JAE     MEM_2   ;ПЕРЕХОД ЕСЛИ CF=0
        MOV     DX,100H
        INC     AL      ;УКАЗАТЕЛЬ НА НОВУЮ ЯЧЕЙКУ
        CMP     AL,28H
        JNE     MEM_2
        JMP     LOK_7 ;В ЧАСАХ НЕТ ХОРОШИХ ЯЧЕЕК
;-----ПРОГРАМИРОВАНИЕ КАРТЫ
MEM_1:  ;ВЫЧИСЛЕНИЕ БЛОКА
        MOV     SI,AX           ;СОХРАНЕНИЕ AX
        SUB     AL,MAP_BEGIN
        SHL	AL,1
        SHL	AL,1
        SHL	AL,1
        ADD     AL,DL
        INC	DL
;-----ПРОГРАМИРОВАНИЕ КАРТЫ
        XCHG    AH,AL
        MOV     AL,0
        OUT     MEMORY_PROC,AL
        XCHG    AH,AL
        OUT     MEMORY_CHIP,AL
        MOV     AX,SI
;-----ТЕСТ 0 СЕГМЕНТА
        MOV     CX,1FFFH
        XOR     BX,BX
MEM_GN:
	MOV	DI,DS:[BX]
	NOT	DI
	NOT	WORD PTR DS:[BX]
	CMP	DI,DS:[BX]
        JNE     MEM_2P
        NOT	DI
	NOT	WORD PTR DS:[BX]
	CMP	DI,DS:[BX]
        JNE     MEM_2P
        ADD     BX,2
        LOOP    MEM_GN
NOT_MAP:

;---------------------------
;	ОЧИСТКА  0 СЕГМЕНТА 
;---------------------------
	XOR     AX,AX
	MOV     ES,AX			; ES=0

	Assume	ES:ABS0

	MOV	BP,ES:ABS_RESET_FLAG	; запись флага сброса
	MOV     DI,AX			; DI=0
	MOV     CX,2000H		; для 64K bytes
	CLD
	REP     STOSW

;------ УСТАНОВКА СТЕКА

	Assume	SS:STACK

	MOV     AX,STACK
        MOV     SS,AX
	MOV     SP,offset TOS

;-------------------------------------------------------
;	УСТАНОВКА ТАБЛИЦЫ ВЕКТОРОВ ПРЕРЫВАНИЙ    	;
;-------------------------------------------------------
	PUSH	ES
	POP	DI			; DI=0
;------ УСТАНОВКА IRET В НЕИСПОЛЬЗУЕМЫХ ВЕКТОРАХ
	MOV     CX,32D
D3:     MOV     AX,offset D11
        STOSW
        MOV     AX,CS
        STOSW
        LOOP    D3
;------ УСТАНОВКА ТАБЛИЦЫ
	MOV     CL,24D
        PUSH    CS
        POP     DS
	MOV     SI,offset VECTOR_TABLE
	MOV     DI,offset INT_PTR
F7A:
        MOVSW
	INC	DI
	INC	DI
        LOOP    F7A

;-------УСТАНОВКА ДРУГИХ НЕОБХОДИМЫХ ПРЕРЫВАНИЙ

	Assume	DS:ABS0

	SUB     AX,AX
        MOV     DS,AX
	MOV     INT5_PTR,offset PRINT_SCREEN ;PRINT SCREEN
        MOV	rtc_int_1,Offset rtc_int     ;int 0AH
	MOV	ALARM1,offset ALARM          ;БУДИЛЬНИК
	mov	ax,int5_ptr+2
	mov	alarm1+2,ax
        CALL    DDS

	Assume	DS:DATA

	MOV     INTR_FLAG,0
	MOV     SI,offset KB_BUFFER	;УСТАНОВКА ПАРАМЕТРОВ КЛАВИАТУРЫ
        MOV     BUFFER_HEAD,SI
        MOV     BUFFER_TAIL,SI
        MOV     BUFFER_START,SI
        ADD     SI,32               ;БУФЕР В 32 БАЙТА
        MOV     BUFFER_END,SI
        MOV     RS232_BASE,3F8H

	mov     rs232_base+2,2f8h

        MOV     PRINTER_BASE,378H
	MOV     DI,offset PRINT_TIM_OUT
        PUSH    DS
        POP     ES
        MOV     AX,1414H            ;УСТАНОВКА  TIM OUT ПРИНТЕРА
        STOSW
        STOSW
        MOV     AX,0101H            ;УСТАНОВКА  TIM OUT  RS232
        STOSW
        STOSW
        
        CALL	KBD_RESET
	XOR	AX,AX
	OUT     INTA01,AL		; RESET MASK OF INTERRUPT

;---ИНИЦИАЛИЗАЦИЯ ВИДЕО
	CALL	ADAPTER
	CMP	BX,505H
	JNE	KL_1
;---ZAPROS
        mov     word ptr equip_flag,20h
        MOV     AX,3
        INT     10H
       	MOV	CX,LLC1
	MOV	SI,offset ZAPROS1
	CALL	STR_PRINT
	mov     word ptr equip_flag,30h
        MOV     AX,7
        INT     10H
       	MOV	CX,LLC1
	MOV	SI,offset ZAPROS1
	CALL	STR_PRINT
	
	XOR	AX,AX
	INT	16H
	CMP	AH,32h
	JE	HERCULES
	JMP	SHORT CGA_EGA
KL_1:
        CMP     BH,5
        JNE     HERCULES
CGA_EGA:        
        mov     word ptr equip_flag,20h
        MOV     AX,3
        INT     10H
        JMP     SHORT CGA_A
HERCULES:
        mov     word ptr equip_flag,30h
        MOV     AX,7
        INT     10H
CGA_A:

;--------------------------------------
;       ПРОВЕРКА НАЛИЧИЯ EGA/VGA BIOS
;--------------------------------------

	assume ds:data
        MOV     DX,0C000H
        MOV     DS,DX
        SUB     BX,BX
        MOV     AX,DS:[BX]
        CMP     AX,0AA55H
        JNZ     NEXT_R
        CALL    ROM_CHECK
NEXT_R:
;----------------------------
; УБИРАЕМ КУРСОР
;----------------------------
        MOV     AH,1
        MOV     CX,2000H
        INT     10H
;------------------------ПЕРВОЕ СООБЩЕНИЕ--------
        MOV	CX,LLC
        MOV	SI,OFFSET MSG1
        CALL    STR_PRINT
;-----------------------------------------
; ЗАПИСЬ В КМОП ПЛОХИХ БЛОКОВ
; НАЙДЕННЫХ В РЕЗУЛЬТАТЕ ТЕСТА 0 СЕГМЕНТА
;-----------------------------------------
        ;----ОПРЕДЕЛЕНИЕ ЧИСЛА ПЛОХИХ БЛОКОВ
        MOV     AX,0
        OUT     MEMORY_PROC,AL
        IN      AL,MEMORY_CHIP
        MOV     DI,AX           ; СОХРАНЕНИЕ ЗНАЧЕНИЯ
	; AL - ЧИСЛО ПЛОХИХ СЕГМЕНТОВ
        CALL    CMOP_0SEG
;-----------------------------------------
; УСТАНОВКА ДЛЯ ТЕСТА АДРЕСОВ
;-----------------------------------------
	MOV	CX,80H
	MOV	AX,DI
	sub	cx,ax
	MOV	AH,1
	XOR	BX,BX
	MOV	DS,BX
	MOV	BX,4000H  ; ПИШЕМ ВО ВТОРЫЕ 16K В ПЕРВУЮ ЯЧЕЙКУ
REPID_SET:	
	XCHG	AH,AL
	OUT	MEMORY_PROC,AL
	XCHG	AH,AL
	OUT	MEMORY_CHIP,AL
	MOV	DS:[BX],AL
	INC	AL
	LOOP	REPID_SET       
;-----------------------------------------;      
; ТЕСТ ПАМЯТИ				  ;	
; ПРОВЕРКА CMOS				  ;
; LOK_3N: - ВНЕШНИЙ ТЕСТ                  ;
; LOK_7N: - ВНУТРЕННИЙ ТЕСТ               ;
;-----------------------------------------;
  ;--- ВЫВОД СООБЩЕНИЯ О ТЕСТЕ
  	MOV	CX,LLC2
  	MOV	SI,OFFSET MEM_TES
	CALL	STR_PRINT
	XOR	BX,BX
	MOV	AH,3
	INT	10H	; ЧИТАЕМ КУРСОР
	MOV	ES,DX
;---------------------------------------	  
  	MOV	BX,0D000H
  	MOV	DS,BX
;-----------------------------
; ТЕСТ ПАМЯТИ С ИСПОЛЬЗОВАНИЕМ
; ДАННЫХ ВНЕШНЕЙ УТИЛИТЫ
;-----------------------------
LOK_3N:
        MOV     AL,MAP_BEGIN
        MOV     CX,10H  ; СЧЕТЧИК ЯЧЕЕК
        MOV	DI,0
        MOV	SI,10D
        XOR	BX,BX
TEST_2:
        PUSH    CX
        MOV     CX,8    ; СЧЕТЧИК СДВИГОВ
        MOV     BH,1
        mov	DH,0
        OUT     CMOS_PORT,AL
        XCHG    AH,AL
        IN      AL,CMOS_PORT+1
        XCHG    AH,AL
TEST_LOK:
        TEST    AH,BH
        JNZ     BAD_PIKS        ; ПЛОХАЯ ЯЧЕЙКА
        CMP	BL,34H		; ПЕРВОЕ ВХОЖДЕНИЕ ПРОПУСКАЕМ Т.К. ЭТО ВЕКТОРА
        JE	NEXT_TEST
        MOV	BL,34H
        JMP	SHORT GOOD_1S
        ;------ВЫЧИСЛЕНИЕ НОМЕРА БЛОКА
NEXT_TEST:        
        PUSH    AX
        SUB     AL,MAP_BEGIN
        SHL     AL,1   ;
        SHL     AL,1   ; УМНОЖЕНИЕ НА 8
        SHL     AL,1   ;
        add	al,DH
klo_1:
        XCHG    AH,AL
        MOV     AL,34H
        OUT     MEMORY_PROC,AL
        XCHG    AH,AL
        OUT     MEMORY_CHIP,AL
        xchg	ah,al
	CALL	TEST_1SEG
	JAE	GOOD_1S1   ; ПЕРЕХОД CF=0
	CALL	CMOS_SET
	POP	AX
	JMP	SHORT BAD_PIKS
GOOD_1S1:	
	POP	AX
GOOD_1S:
;----------------------------
; ОТОБРАЖЕНИЕ ТЕСТА ПАМЯТИ
; DI НЕОБХОДИМО СОХРАНЯТЬ
;----------------------------
        CALL    ROM_SHOW
        PUSH	BX
        MOV	BX,10FFH
        CALL	BEEP
        POP	BX
BAD_PIKS:
        SHL     BH,1
        inc	DH
        LOOP    TEST_LOK
	INC	AL
        POP     CX
	LOOP	TEST_2
;-----------------------------------------;
;  ПРОГРАМИРОВАНИЕ КАРТЫ		  ;
;-----------------------------------------;
KONFIG:
;	CALL	SUMMM     ???????????
        CALL    MAP_PROG
;----------------------------------------------------------
; ЗАГРУЗКА ПО МИНИМАЛЬНОЙ КОНФИГУРАЦИИ
;----------------------------------------------------------
        CALL    DEFINE_MEM
;----TEST SIZE MEMORY IF < 200H OUT E,0
	CMP	BX,100H
	JAE	GOOD_SIZE
	MOV	AL,0EH
	OUT	CMOS_PORT,AL
	XOR	AL,AL
	OUT	CMOS_PORT+1,AL
	JMP	START
GOOD_SIZE:	        
	CALL	SET_UP_N
	ASSUME DS:DATA
	CALL	DDS
	MOV     AL,0
	MOV     MOTOR_STATUS,AL		; TIMER 2 SETUP
;-----------------------------------------------------------------------
;       ПРОВЕРКА НАЛИЧИЯ ДОПОЛНИТЕЛЬНЫХ ПРОГРАММ В ПЗУ
;------------------------------------------------------------------------
        CALL    POISK_BIOS
        CALL	DISK_SETUP
;----------------------------------------------------------
; cpaвнение полученного размера памяти с значением
; в CMOS 15H AND 16H
;---------------------------------------------------------
        CALL    CMOS_MEM
;------------------------------
;ПОЛУЧЕНИЕ КОНФИГУРАЦИИ ИЗ CMOS
;------------------------------
        CALL    K_ONFIG
;-----------------------
;      ЗАГРУЗКА СИСТЕМЫ
;-----------------------
TYU_1:
	STI
	JMP	IVK_TITLE
include	int_1a.asm
include	tyme_cmo.asm

	org	0e500h

;-- INT 19 ---------------------------------------------
; ЗАГРУЗКА СИСТЕМЫ 					;
;-------------------------------------------------------
BOOT_STRAP:
        JMP     BOOT_STRAPR
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include Int14.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include KBR.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include Int13.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include Int17.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include Int10.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include Int12.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include Int11.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include Int15.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -


;---------------------------------------------------------------------------
;       ПРОЦЕДУРА ПРОВЕРКИ КОНТРОЛЬНОЙ СУММЫ
;---------------------------------------------------------------------------
ROS_CHECKSUM    PROC    NEAR
        MOV     CX,8192
ROS_CHECKSUM_CNT:
        XOR     AL,AL
C26:
        ADD     AL,DS:[BX]
        INC     BX
        LOOP    C26
        OR      AL,AL
        RET
ROS_CHECKSUM    ENDP

;-----------------------------------------------------------------------------
;THIS ROUTINE CHECKSUMS OPTIONAL ROM MODULES AND
;IF CHECKSUM IS OK,CALLS INIT/TEST CODE IN MODULE
;-----------------------------------------------------------------------------
ROM_CHECK       PROC     NEAR
        MOV     AX,DATA        ;POINT ES TO DATA AREA
        MOV     ES,AX
        SUB     AH,AH          ;ZERO OUT AH
        MOV     AL,[BX+2]      ;GET LENGTH INDICATOR
        MOV     CL,09H         ;MULTIPLY BY 512
        SHL     AX,CL
        MOV     CX,AX          ;SET COUNT
        PUSH    CX             ;SAVE COUNT
        MOV     CX,4           ;ADJUST
        SHR     AX,CL
        ADD     DX,AX          ;SET POINTER TO NEXT MODULE
        POP     CX             ;RETRIVE COUNT
        CALL    ROS_CHECKSUM_CNT ;DO CHECKSUM
        JZ      ROM_CHECK_1
	JMP     short ROM_CHECK_END  ;AND EXIT
ROM_CHECK_1:
        PUSH    DX             ;SAVE POINTER
        MOV     ES:IO_ROM_INIT,0003H ;LOAD OFFSET
        MOV     ES:IO_ROM_SEG,DS ;LOAD SEGMENT
        CALL    DWORD PTR ES:IO_ROM_INIT ;CALL INIT./TEST ROUTINE
        POP     DX
ROM_CHECK_END:
        RET                    ;RETURN TO CALLER
ROM_CHECK       ENDP

;-------ROUTINE TO SOUND BEEPER

        ORG     0FA10H

BEEP    proc    NEAR
	PUSH	AX
        MOV     AL,10110110B    ;SEL TIM 2,LSB,MSB,BINARY
        OUT     TIMER+3,AL      ;WRITE THE TIMER MODE REG
        MOV     AX,533H         ;DIVISOR FOR 1000 HZ
        OUT     TIMER+2,AL      ;WRITE TIMER 2 CNT - LSB
        MOV     AL,AH
        OUT     TIMER+2,AL      ;WRITE TIMER 2 CNT - MSB
        IN      AL,PORT_B       ;GET CURRENT SETTING OF PORT
        MOV     AH,AL         ;SAVE THAT SETTINH
        OR      AL,3           ;TURN SPEAKER ON
        OUT     PORT_B,AL
G7:
        DEC     BL              ;DELAY CNT EXPIRED?
        JNZ     G7              ;NO - CONTINUE BEEPING SPK
        MOV     AL,AH           ;RECOVER VALUE OF PORT
        OUT     PORT_B,AL
        POP	AX
        RET                     ;RETURN TO CALLER
BEEP    EndP

;------------------------------------------------------------------------
;       THIS PROCEDURE WILL SEND A SOFTWARE RESET TO THE KEYBOARD.

;------------------------------------------------------------------------
KBD_RESET       proc   NEAR
        MOV     AL,0C8H         ;SET KBD CLK LINE LOW
        OUT     PORT_B,AL       ;WRITE 8255 PORT B
        MOV     CX,10582        ;HOLD KBD CLK LOW FOR 20 MS
G8:
	LOOP    G8              ;LOOP FOR 20 MS
        MOV     AL,048H         ;SET CLK, ENABLE LINES HIGH
        OUT     PORT_B,AL
        RET                     ;RETURN TO CALLER
KBD_RESET       EndP

DDS     proc    NEAR
        PUSH    AX              ;SAVE AX
        MOV     AX, DATA
        MOV     DS,AX           ;SET SEGMENT
        POP     AX              ;RESTORE AX
        RET
DDS     EndP
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include CharGen.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include Int1A.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include Int8.ASM
;- - - - - - -  - - - - - - - - - - - - - - - - - - - -

;---------------------------------------------------------------------------
; THESE ARE THE VECTORS WHICH ARE MOVED INTO
; THE 8086 INTERRUPT ARE DURING POWER ON.
; ONLI THE OFFSETS ARE DISPLAYED HERE, CODE
; SEGMENT WILL BE ADDED FOR ALL OF THEM, EXCEPT
; WHERE NOTED.
;----------------------------------------------------------------------------
        Assume  CS:CODE
        ORG     0FEF3H
VECTOR_TABLE    label  WORD          ;VECTOR TABLE FOR MOVE TO INTERRUPTS
        DW      offset TIMER_INT     ;INTERRUPT 8
        DW      offset KB_INT        ;INTERRUPT 9
        DW      offset D11           ;INTERRUPT A
        DW      offset D11           ;INTERRUPT B
        DW      offset D11           ;INTERRUPT C
        DW      offset D11           ;INTERRUPT D
        DW      offset DISK_INT      ;INTERRUPT E
        DW      offset D11           ;INTERRUPT F
        DW      offset VIDEO_IO      ;INTERRUPT 10H
        DW      offset EQUIPMENT     ;INTERRUPT 11H
        DW      offset MEMORY_SIZE_DET ;INTERRUPT 12H
        DW      offset DISKETTE_IO   ;INTERRUPT 13H
        DW      offset RS232_IO      ;INTERRUPT 14H
        DW      offset INT_15_SERVICE  ;INTERRUPT 15H
        DW      offset KEYBOARD_IO   ;INTERRUPT 16H
        DW      offset PRINTER_IO    ;INTERRUPT 17H
	DW      0C05BH               ;INTERRUPT 18H -- Monitor
        DW      offset BOOT_STRAP    ;INTERRUPT 19H
        DW      TIME_OF_DAY          ;INTERRUPT 1AH -- TIME OF DAY
        DW      DUMMY_RETURN         ;INTERRUPT 1BH -- KEYBOARD BREAK ADDR
        DW      DUMMY_RETURN         ;INTERRUPT 1CH -- TIMER BREAK ADDR
        DW      VIDEO_PARMS          ;INTERRUPT 1DH -- VIDEO PARAMETERS
        DW      offset DISK_BASE     ;INTERRUPT IEH -- DISK PARMS
        DW      offset ALT_GEN       ;INTERRUPT 1FH -- POINTER TO VIDEB EXT
;dw	offset rtc_int	     ;int 70
;---------------------------------------------------------------------------
; TEMPORARY INTERRUPT SERVISE ROUTINE
;       1. THIS ROUTINE IS ALSO LEFT IN PLACE AFTER THE
;       POWER ON DIAGNOSTICS TO SERVICE UNUSED
;       INTERRUPT VECTORS.LOCATION 'INTR_FLAG' WILL
;       CONTAIN EXTHER: 1. LEVEL OF HARDWARE INT. THAT
;       CAUSED CODE TO BE EXEC.
;       2. 'FF' FOR NON-HARDWARE INTERRUPTS THAT WAS
;       EXECUTED ACCIDENTLY.
;-------------------------------------------------------------------------
D11     proc    NEAR
        Assume  DS:DATA
        PUSH    DS
        PUSH    DX
        PUSH    AX                   ;SAVE REG AX CONTENTS
        CALL    DDS
        MOV     AL,0BH               ;READ IN-SERVICE REG
        OUT     INTA00,AL            ;(FIND OUT WHAT LEVEL BEING
        NOP                          ;SERVICED)
        IN      AL,INTA00            ;GET LEVEL
        MOV     AH,AL                ;SAVE IT
        OR      AL,AH                ;00? (NO HARDWARE ISR ACTIVE)
        JNZ     HW_INT
        MOV     AH,0FFH
        JMP     SHORT SET_INTR_FLAG  ;SET FLAG TO FF IF NON-HARDWARE
HW_INT:
        IN      AL,INTA01            ;GET MASK VALUE
        OR      AL,AH                ;MASK OFF LVL BEING SERVISED
        OUT     INTA01,AL
        MOV     AL,EOI
        OUT     INTA00,AL
SET_INTR_FLAG:
        MOV     INTR_FLAG,AH         ;SET FLAG
        POP     AX                   ;RESTORE REG AX CONTENTS
        POP     DX
        POP     DS
DUMMY_RETURN:                        ;NEED IRET FOR VECTOR TABLE
        IRET
D11     EndP

	org	0ed63h
include	d8.asm
;	DB	'MAX4'

;--------------------------------------------------------------------------
; DUMMY RETURN FOR ADDRESS COMPATIBILITY
;--------------------------------------------------------------------------
        ORG     0FF53H
        IRET
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
include Int5.ASM
;- - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	org	0e5efh
;include	d7.asm
;	DB	'MAX3'
;	org	0f8c7h
;include d9.asm;
;	db	'maxim'

;---------------------------------------------------------------------------
;       POWER ON RESET VECTOR
;---------------------------------------------------------------------------

	ORG	0FFF0H

	JMP	far ptr RESETV
	DB	'06-11-91'
	DB	0H
	DB	0FBH        ;0FBH

        CODE    ENDS
;--------------------------------------------------------
VECTOR	segment	at	0F000H

        Assume  CS:VECTOR

	ORG	0E05BH
RESETV	label	FAR

VECTOR	EndS
;--------------------------------------------------------




	END



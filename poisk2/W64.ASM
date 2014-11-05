;---------DISK CHANGE LINE EQUATES
;NOCHGLN                 EQU     001H                    ; NO DISK CHANGE LINE AVAILABLE
;CHGLN                   EQU     002H                    ; DISK CHANGE LINE AVAILABLE
;
;WDC_RATE	EQU	0000B 	; 35 mkS
;LONG_FLAG	EQU	0010B	; LONG opn active
;MULT_TRANS	EQU	0100B	; Multiple Sector flag
;RESTORE_CMD	EQU	10H+WDC_RATE
;SEEK_CMD	EQU	70H+WDC_RATE
;READ_CMD	EQU	28H+MULT_TRANS	; Retries Enable
;
;WRITE_CMD	EQU	30H+MULT_TRANS	; Retries Enable
;RD_LONG_CMD	EQU	READ_CMD+LONG_FLAG  ;
;WR_LONG_CMD	EQU	WRITE_CMD+LONG_FLAG ;
;SCAN_ID_CMD	EQU	40H		; Retries Enable
;WR_FORMAT_CMD	EQU	50H
;	GAP_1	EQU	30D		; GAP length for format
;COMPUTE_CMD	EQU	08H
;SET_PARM_CMD	EQU	00H		; 5-bit Span
;
;
;
;WDC_PORT		EQU	1F0H       ;320H
;HD_PORT	        EQU	1F8H       ;328H
;DSEL_0_BIT             EQU	00001000B
;HD_RES_BIT	        EQU	00100000B
;IR_DMA_EN	        EQU	01000000B
;BF_RES_BIT	        EQU	10000000B
;LONG_MODE_BIT	        EQU	40H		; !!!
;I64_FMT_CMD	        EQU	01010000B ; Format command
;
;FD_INT_NO		EQU	0DH	; Hardware INT vector
;INT_CTL_PORT		EQU	20H	; 8259 Control port
;EOI			EQU	20H	; END OF INTERRUPT command
;FD_INT_MASK		EQU	(1 SHL (FD_INT_NO-8))	;


;-- INT 13 -----------------------------------------------------
;								;
; ИНТЕРФЕЙС ЖЕСТКОГО ДИСКА					;
;								;
;	ЭТА ПРОЦЕДУРА ПОДДЕРЖИВАЕТ КОНТРОЛЛЕР Ж.ДИСКА       	;
;	ВЫПОЛНЕННЫЙ НА  Intel'82064 ДЛЯ	ПК ПОИСК          	;
;								;
;---------------------------------------------------------------
;
;---------------------------------------------------------------
;	ПРЕДУПРЕЖДЕНИЕ: ДЛЯ УВЕРЕННОЙ РАБОТЫ С Ж.ДИСКОМ         ;
;	ПОЛЬЗУЙТЕСЬ ФУНКЦИЯМИ ОПРЕДЕЛЕННЫМИ В ПРЕРЫВАНИИ  	;
;---------------------------------------------------------------
;
; ВХОД 	(AH = HEX ЗНАЧЕНИЕ)
;
;	AH = 00	СБРОС ДИСКА (DL = 80H/81H)/ДИСКЕТ
;	AH = 01 ЧТЕНИЕ СТАТУСА ПОСЛЕДНЕЙ ДИСКОВОЙ ОПЕРАЦИИ В AL
;	    ЗАМЕТИМ	DL < 80H - ДИСКЕТЫ
;			DL > 80H - ДИСК
;	AH = 02 ЧТЕНИЕ ВЫБРАННОГО СЕКТОРА В ПАМЯТЬ
;	AH = 03 ЗАПИСЬ ВЫБРАННОГО СЕКТОРА В ПАМЯТЬ
;	AH = 04 ВЫРИФИКАЦИЯ ВЫБРАННОГО СЕКТОРА
;	AH = 05 ФОРМАТИРОВАНИЕ ВЫБРАННОГО ТРЕКА
;	AH = 06 ФОРМАТИРОВАНИЕ ВЫБРАННОГО ТРЕКА С УСТАНОВКОЙ ФЛАГА
;		ПЛОХИХ СЕКТОРОВ
;	AH = 07 ФОРМАТИРОВАНИЕ ДИСКА НАЧИНАЯ С ВЫБРАННОГО ТРЕКА
;	AH = 08 Возвращает текущие параметры диска
;
;	AH = 09 Initialize drive pair characteristics
;			interrupt 41 points to data block
;	AH = 0A ДЛИННОЕ ЧТЕНИЕ
;       AH = 0B ДЛИННАЯ ЗАПИСЬ
;	   ЗАМЕТИМ	Read and Write LONG encompass 512+4 bytes ECC
;	AH = 0C ПОИСК ТРЕКА
;	AH = 0D АЛЬТЕРНАТИВНЫЙ СБРОС (СМОТРИ DL)
;	AH = 0E Read Sector Buffer
;	AH = 0F Write Sector Buffer
;	AH = 10 ТЕСТ ЧИТАЕМОСТИ ДИСКА
;	AH = 11 РЕКАЛИБРАЦИЯ
;	AH = 12 ДИАГНОСТИКА RAM КОНТРОЛЛЕРА
;	AH = 13 ДИАГНОСТИКА ДИСКА
;	AH = 14 ВНУТРЕННЯЯ ДИАГНОСТИКА КОНТРОЛЛЕРА
;	AH = 15 ЧТЕНИЕ ТИПА НОСИТЕЛЯ
;	AH = 16-18 ЗАРЕЗЕРВИРАВОНО ДЛЯ ДИСКОВОДОВ
;	AH = 19 ПАРКОВКА ГОЛОВОК
;
;	РЕГИСТРЫ ИСПОЛЬЗУЕМЫЕ ДЛЯ ФУНКЦИЙ:
;
;		DL - НОМЕР ДИСКА     (80H-87H ДЛЯ ДИСКА. ЗНАЧЕНИЕ ПРОВЕРЯЕТСЯ)
;		DH - НОМЕР ГОЛОВКИ   (0-7 ЗНАЧЕНИЕ НЕ ПРОВЕРЯЕТСЯ)
;		CH - НОМЕР ЦИЛИНДРА  (0-1023. ЗНАЧЕНИЕ НЕ ПРОВЕРЯЕТСЯ,СМОТРИ CL)
;		CL - НОМЕР СЕКТОРА   (1-17. ЗНАЧЕНИЕ НЕ ПРОВЕРЯЕТСЯ)
;		    ЗАМЕТИМ 	СТАРШИЕ 2 БАЙТА НОМЕРА ЦИЛИНДРА РАСПОЛОЖЕНЫ
;				В 2 СТАРШИХ БАЙТАХ РЕГИСТРА CL
;				(ВСЕГО 10 БИТ)
;		AL - ЧИСЛО СЕКТОРОВ (МАКСИМАЛЬНОЕ 1-80H,
;				     ДЛЯ ДЛИННЫЙ ЧТЕН/ЗАПИСИ  1-79H)
;			(ЧЕРЕДОВАНИЕ СЕКТОРОВ ДЛЯ ФОРМАТИРОВАНИЯ 1-16D)
;	     ES:BX - АДРЕС БУФЕРА ДЛЯ ЧТЕНИЯ И ЗАПИСИ
;
; ВЫХОД
;	AH = СТАТУС ТЕКУЩЕЙ ОПЕРАЦИИ
;		ОПИСАНИЕ БИТ СТАТУСА ПРЕВЕДЕННО НИЖЕ
;	CY = 0  УСПЕШНАЯ ОПЕРАЦИЯ (AH=0 ПРИ ВОЗВРАТЕ)
;	CY = 1  НЕ УСПЕШНАЯ ОПЕРАЦИЯ (AH СОДЕРЖИТ ОШИБКУ)
;
;     ЗАМЕТИМ	ОШИБКА 11H  ПОКАЗЫВАЕТ, ЧТО ПРИ ЧТЕНИИ БЫЛА ИСПРАВЛЕНА ОШИБ-
;		КА ПО ECC АЛГОРИТМУ.  ПРОЧИТАННЫЕ ДАННЫЕ ВОЗМОЖНО ХОРОШИЕ.
;		ОДНАКО BIOS ПОКАЗЫВАЕТ ОШИБКУ, ПОЭТОМУ ВЫЗЫВАЮЩАЯ ПРОГРАММА
;		ДОЛЖНА САМА ВЫБИРАТЬ АЛГОРИТМ ОБРАБОТКИ ЭТИХ ДАННЫХ
;
;	ОТВЕТ НА ЗАПРОС ПАРАМЕТРОВ ДИСКА:
;
;	DL = ЧИСЛО ПОДКЛЮЧЕННЫХ ДИСКОВ (0-2)
;		(ПОДСЧЕТ ЧИСЛА КОНТРОЛЛЕРОВ)
;	DH = МАКСИМАЛЬНАЯ ГОЛОВКА
;	CH = МАКСИМАЛЬНОЕ ЧИСЛО ЦИЛИНДРОВ
;	CL = МАКСИМАЛЬНОЕ ЧИСЛО СЕКТОРОВ И 2 СТАРШИЕ БИТА ЭТО СТАРШИЕ
;		БИТЫ ЧИСЛА ЦИЛИНДРОВ
;
;	ВСЕ РЕГИСТРЫ, ЗА ИСКЛЮЧЕНИЕМ ВОЗВРАЩАЮЩИХ ИНФОРМАЦИЮ НЕ ИЗМЕНЯЮТСЯ
;
;  ЗАМЕТИМ 	ОБЫЧНЫЙ АЛГОРИТМ ОБРАБОТКИ ОШИБКИ ЭТО СБРОС СИСТЕМЫ И
;		ПОВТОРЕНИЕ ОПЕРАЦИИ.
;
;----------------------------------------------------------------------------
;-----------------------------------------------
;	ТОЧКА ВХОДА                		;
;-----------------------------------------------

DISK_IO		Proc FAR
	Assume	CS:CODE, DS:DATA

	CMP	DL,80H			; ТЕСТ Ж.ДИСК ИЛИ ГИБКИЙ
	JAE	HARD_DISK		; ДА,Ж.ДИСК
	INT	40H			; ОБСЛУЖИВАНИЕ ДИСКЕТ
	JMP	short RET_2		; ВОЗВРАТ В ВЫЗЫВАЮЩУЮ
HARD_DISK:
	STI				; РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ
	OR	AH,AH			; КОМАНДА СБРОСА ?
	JNZ	A0			; НЕТ, ПРОДОЛЖЕНИЕ
	INT	40H			; СБРОС NEC
	XOR	AH,AH			; ОБНУЛЕНИЕ
A0:
	PUSH	SI
	PUSH	DS
	PUSH	ES
        CALL	DDS    		        ; УСТАНОВКА СЕГМЕНТА ДАННЫХ BIOS
	CMP	AH,8			; КОМАНДА ЧТЕНИЯ ПАРАМЕТРОВ ?
	JNE	HHA1			; НЕТ
	JMP	short READ_PARMS
HHA1:
	CMP	AH,15H			; ЧТЕНИЕ DASD ТИПА ?
	JNE	HHA2			; НЕТ
	JMP	short RD_DASD_TYPE
HHA2:
	PUSH	BP			; ЗАПИСЬ УКАЕТЕЛЯ
	PUSH	DI
	PUSH	DX
	PUSH	BX			; ЗАПИСЬ РЕГИСТРОВ ОПЕРАЦИИ
	PUSH	CX
	PUSH	DS
	PUSH	AX
	AND	DL,7FH			; СБРОС СТАРШИХ БИТ
	CMP	DL,[HF_NUM]		; ПРАВИЛЬНЫЙ НОМЕР ?
	JAE	RET_BAD_CMD		; НЕТ, НЕПРАВИЛЬНЫЙ
	CMP	AH,(H1L SHR 1)		; ПЛОХАЯ КОМАНДА ?
	JB	DIO_0			; НЕТ, ПРОДОЛЖЕНИЕ
RET_BAD_CMD:
	MOV	AH,18H			; ДА, УСТАНАВЛИВАЕМ BAD_COMMAND.
DIO_0:
	MOV	AL,AH			; ПОЛУЧЕНИЕ МЛАДШЕГО БАЙТА
	XOR	AH,AH			; ОБНУЛЕНИЕ СТАРШЕГО БАЙТА
	SHL	AX,1			; *2 ДЛЯ ПРОСМОТРА ТАБЛИЦЫ
	MOV	SI,AX			; ЗАГРУЖАЕМВ SI ДЛЯ ПЕРЕХОДА ПО CALL
	POP	AX			; ВОССТАНОВЛЕНИЕ AX
	XOR	AH,AH
	MOV	DI,AX			; DI = СЧЕТЧИК БЛОКОВ
	XCHG	AH,[HDISK_STATUS]	; СБРОС СТАТУСА

	CALL	Word ptr CS:H_COM[SI]	; ВЫЗОВ НЕОБХОДИМОЙ ОПЕРАЦИИ

	PUSH	AX
	MOV	DX,HD_PORT		; АДРЕС ПОРТА
	MOV	AL,(HD_RES_BIT or BF_RES_BIT or IR_DMA_EN)
	OUT	DX,AL			; ПОСЫЛКА DX = HD_PORT
	POP	AX
	POP	DS			; ВОССТАНОВЛЕНИЕ РЕГИСТРА ДАННЫХ
	MOV	[HDISK_STATUS],AH	; ПОЛУЧЕНИЕ СТАТУСА ОПЕРАЦИИ
	POP	CX
	POP	BX
	POP	DX
	POP	DI
	POP	BP
	CMP	AH,1			; УСТАНОВКА ФЛАГА ДЛЯ ИНДИКАЦИИ
	CMC				; УСПЕХА ИЛИ НЕУСПЕХА ОПЕРАЦИИ
RET_8:
	POP     ES
	POP	DS
	POP	SI
RET_2:
	RET	2
DISK_IO		EndP

;-------------------------------------------------------
; ПОЛУЧЕНИЕ СТАТУСА (AH=1)				;
;-------------------------------------------------------
HREAD_STATUS	Proc	near
	MOV	AL,AH			; AH СОДЕРЖИТ DISK STATUS
	XOR	AH,AH			; СБРОС СТАТУСА
	RET
HREAD_STATUS	EndP
;-------------------------------------------------------
; ПОЛУЧЕНИЕ ПАРАМЕТРОВ ДИСКА (AH=8)			;
;-------------------------------------------------------
READ_PARMS	Proc	near
	Assume	DS:DATA

	PUSH    DS			; ЗАПИСЬ РЕГИСТРА BIOS
	CALL	TST_DRV_NUM
	JB	RP0			; ДА.
	XOR	DX,DX			; НЕПРАВИЛЬНЫЙ НОМЕР ДИСКА
	MOV	AX,700H			; INIT_FAIL ОШИБКА
	STC				; ВЫХОД ПО ОШИБКЕ
RP_RET:
	POP	DS
	MOV	[HDISK_STATUS],AH
	JMP	short   RET_8		; ВЫХОД
RP0:
	LODSW				; ПОЛУЧЕНИЕ ЧИСЛА ЦИЛИНДРОВ
	DEC	AX			; НАЧИНАЕТСЯ НУМЕРАЦИЯ С 0
	XCHG	AL,AH
	ROR	AL,1
	ROR	AL,1			; ПОЛУЧЕНИЕ СТАРШИХ БИТ ЧИСЛА ЦИЛИНДРОВ
	OR	AL,0CH[SI]		; СМЕШИВАНИЕ
	XCHG	CX,AX			; AX=0
	MOV	DL,DH			; УСТАНОВКА ЧИСЛА ДИСКОВ
	MOV	DH,[SI]			; SI УКАЗАТЕЛЬ НА ЧИСЛО ГОЛОВОК
	DEC	DH			; НАЧИНАЕТСЯ С 0
	JMP	short RP_RET		; Carry = 0
READ_PARMS	EndP
;-------------------------------------------------------
; ЧТЕНИЕ ТИПА DASD  (AH=15)				;
;-------------------------------------------------------
RD_DASD_TYPE	proc	near
	CALL	TST_DRV_NUM
	MOV	AX,CX			; AX=0
	MOV	DX,CX			; DX=0
	JNB	RD_RET			; НЕПРАВИЛЬНЫЙ НОМЕР ДИСКА, ВЫХОД
	MOV	AL,2[SI]		; ПОЛУЧЕНИЕ ЧИСЛА ГОЛОВОК
	IMUL	byte ptr 0EH[SI]	; УМНОЖЕНИЕ ЧИСЛА СЕКТОРОВ НА
	IMUL	word ptr [SI]		; ЧИСЛО ТРЕКОВ
	MOV	CX,DX
	MOV	DX,AX
	MOV	AX,300H			; ТИП ДИСКА - ФИКСИРОВАННЫЙ
RD_RET:
	JMP	short   RET_8		; ВЫХОД (CY=0)
RD_DASD_TYPE	EndP
;
;------
	Assume	DS:DATA

TST_DRV_NUM:
	AND	DL,7FH			; СБРОС СТАРШИХ БИТ
	XOR	CX,CX			; CX=0
	MOV	DH,[HF_NUM]		; ЗАПИСЬ НОМЕРА ДИСКА В DH
	CALL	SET_PARAM_PTR
	CMP	DL,DH			; ПРАВИЛЬНЫЙ НОМЕР ?
	RET				; ВОЗВРАТ СТАТУСА
;-------------------------------------------------------
; BAD_COMMAND						;
;	ЭТА ПРОЦЕДУРА ВОЗВРАЩАЕТ ОШИБКУ           	;
; ВОЗВРАЩАЕТ   						;
;	AH = 01						;
;-------------------------------------------------------
HDISK_SEEK: mov    di,1
            jmp    HDISK_VERF
PARK_HEAD:
FMT_BAD:
FMT_DRV:
RD_BUFF:
WR_BUFF:
BAD_COMMAND:
	MOV	AX,BAD_CMD*256
	RET
;-------------------------------------------------------
; СБРОС Ж.ДИСКА (AH=0)					;
;-------------------------------------------------------
HDISK_RESET	proc	near
HDISK_RECAL:
	CALL	DRIVE_SELECT
	PUSH	AX
	AND	AL,not (HD_RES_BIT or BF_RES_BIT)
        CLI
	OUT	DX,AL			; СБРОС КОНТРОЛЛЕРА
	POP	AX
	OUT	DX,AL			; ВКЛЮЧАЕТ КОНТРОЛЛЕР И ВЫДЕЛЯЕТ ДИСК
	DEC	DX			; 327, РЕГИСТР КОМАНД
	MOV	AL,RESTORE_CMD
	OUT	DX,AL			; СТАРТ ВОССТАНОВЛЕНИЯ
	MOV	AX,TIME_OUT*256+10H	; ИНИЦИАЛИЗАЦИЯ TIME_OUT
	CALL	WAIT_START
	JC      RESET_DONE		; AH=ОШИБКА TIMEOUT
	IN	AL,DX			; ПОЛУЧЕНИЕ СТАТУСА
	XOR	AH,AH			; СТАТУС O.K.
	SHR	AL,1			; ОШИБКА ?
	JNC	RESET_DONE		; НЕТ, ВЫХОД
	MOV	AH,BAD_RESET		; ДА,УСТАНОВКА СТАТУСА BAD_RESET
RESET_DONE:
	RET
HDISK_RESET	EndP
;
;------ ЭТА ПРОЦЕДУРА ВКЛЮЧАЕТ ВЫБРАННЫЙ ДИСК
;
DRIVE_SELECT:
	MOV	AL,DSEL_0_BIT		; DSEL_0 БИТ
	MOV	CL,DL
	SHL	AL,CL			; СДВИГ ДИСКОВОДА
	OR	AL,(HD_RES_BIT or BF_RES_BIT or IR_DMA_EN)
	MOV	DX,HD_PORT
	OUT	DX,AL
	RET
;-------------------------------------------------------
; ТЕСТ ЧИТАЕМОСТИ ДИСКА (AH=10)				;
;-------------------------------------------------------
TST_RDY		proc	near
	CALL    DRIVE_SELECT
	DEC	DX			; WDC РЕГИСТР СТАТУСА
	XOR	AH,AH
	IN	AL,DX			; ПОЛУЧЕНИЕ СТАТУСА
	TEST	AL,40H			; ДИСК ЧИТАЕМ ?
	JNZ	TST_RDY_RET		; ДА.
	MOV	AH,DRIVE_NOT_RDY	; НЕТ,УСТАНОВКА ОШИБКИ
TST_RDY_RET:
	RET
TST_RDY		EndP
;-------------------------------------------------------
; ИНИЦИАЛИЗАЦИЯ ТАБЛИЦЫ ДИСКА  (AH=9)			;
;-------------------------------------------------------
INIT_DRV	proc	near
RAM_DIAG:
CHK_DRV:
	XOR	AH,AH			; O.K. СТАТУС
	RET
INIT_DRV	EndP
;-------------------------------------------------------
;HDISK_READ	(AH=2)					;
;	ЭТА ПРОЦЕДУРА ВЫПОЛНЯЕТ ЧТЕНИЕ С ДИСКА В
;	ПАМЯТЬ ДО 80H СЕКТОРОВ				;
;-------------------------------------------------------
HDISK_READ	proc	near
	MOV	AX,256*READ_CMD+DMA_WRITE_CMD+3	; КАНАЛ Ж.ДИСКА
	JMP	short RWVF_OPN
HDISK_READ	EndP
;-------------------------------------------------------
; HDISK_WRITE	(AH=3)					;
;-------------------------------------------------------
HDISK_WRITE	proc	near
	MOV	AX,256*WRITE_CMD+DMA_READ_CMD+3	; КАНАЛ Ж.ДИСКА
	JMP	short RWVF_OPN
HDISK_WRITE	EndP
;-------------------------------------------------------
; HDISK_VERF	(AH=4)					;
;-------------------------------------------------------
HDISK_VERF	proc	near
	MOV	AX,256*READ_CMD+DMA_READ_CMD+3	; КАНАЛ Ж.ДИСКА
	JMP	short RWVF_OPN
HDISK_VERF	EndP
;-------------------------------------------------------
; FMT_TRK	(AH=5)					;
;-------------------------------------------------------
FMT_TRK		proc	near
	MOV	AX,256*WR_FORMAT_CMD+DMA_READ_CMD+3	; КАНАЛ Ж.ДИСКА
	MOV	DI,1
	JMP	short RWVF_FMT_POINT
FMT_TRK		EndP
;-------------------------------------------------------
; RD_LONG	(AH=0A)					;
;-------------------------------------------------------
RD_LONG		proc	near
	MOV	AX,256*RD_LONG_CMD+DMA_WRITE_CMD+3	; КАНАЛ Ж.ДИСКА
	JMP	short RWVF_OPN
RD_LONG		EndP
;-------------------------------------------------------
; WR_LONG	(AH=0B)					;
;-------------------------------------------------------
WR_LONG		proc	near
	MOV	AX,256*WR_LONG_CMD+DMA_READ_CMD+3	; КАНАЛ Ж.ДИСКА
WR_LONG		EndP
;-------------------------------------------------------
; RWVF_OPN						;
;	ЭТА ПРОЦЕДУРА ВЫПОЛНЯЕТ ЧТЕН/ЗАПИСЬ/ВЕРИФИК.
;	ВЫБРАННОГО К-ВА СЕКТОРОВ В ДЛИННОЙ И НОРМАЛЬНОЙ
;	МОДЕЛИ
; INPUT							;
;	AH = БАЙТ КОМАНДЫ ДЛЯ Intel' 82064		;
;	CL = НОМЕР СЕКТОРА + СТАРШИЕ БИТЫ ТРЕКА		;
;	CH = БИТЫ ТРЕКА        				;
;	DL = НОМЕР ДИСКА (0..1)				;
;	DH = ГОЛОВКА					;
;	DI = СЧЕТЧИК БЛОКА(0..80)			;
; ВЫХОД 						;
;-------------------------------------------------------
RWVF_OPN         proc	near
	DEC	CX			; НОМЕРА СЕКТОРОВ НАЧИНАЮТСЯ С 0
RWVF_FMT_POINT:
	CALL	HDMA_SETUP		; УСТАНОВКА ПАРАМЕТРОВ ПЕРЕДАЧИ
	JNC	RWVF_CONTINUE
	MOV	AX,DMA_BOUNDARY*256	; ПЕРЕДАЧА 0 БЛОКА
	RET				; DMA ОШИБКА
RWVF_CONTINUE:
	PUSH	DI			; ЗАПИСЬ СЧЕТЧИКА БЛОКА
	CALL	SET_PARAM_PTR		; DS:SI УКАЗАТЕЛЬ НА ТАБЛИЦУ ПАРАМЕТРОВ
	XCHG	CL,CH
	MOV	BX,CX
	MOV	CL,6
	SHR	BH,CL			; УСТАНОВКА СТАРШИХ 2 БИТ
	XCHG	BX,DI			; DI = НОМЕР ЦИЛИНДРА
					; BL = СЧЕТЧИК БЛОКА
	AND	CH,3FH			; CH = НОМЕР СЕКТОРА
	MOV	BH,DSEL_0_BIT		; DSEL_0 БИТ
	MOV	CL,DL
	SHL	BH,CL			; СДВИГ ДИСКА
	OR	BH,(HD_RES_BIT or BF_RES_BIT or IR_DMA_EN)
;
;------ ДЛИННЫЙ ТЕСТ,ВОЗМОЖЕН ТОЛЬКО ДЛЯ 82064
;
	TEST	AH,LONG_FLAG		; ДЛИННОЕ ?
	JZ	SHORT_RWVF		; НЕТ, НОРМАЛЬНОЕ
	OR	BH,LONG_MODE_BIT	; !!!
SHORT_RWVF:
					; BH = HD_PORT БАЙТ
	MOV	CL,3
	SHL	DL,CL
	OR	DL,20H			; DL = SDH РЕГИСТР
					; (512 БАЙТ/СЕК, CRC МОДЕЛЬ- ДЛЯ 062)
					; CRC - OR   DL,20H
					; УСТАНАВЛИВАЕМ ECC МОДЕЛЬ
					; ECC - OR   DL,0A0H 
					; DH = ГОЛОВКА
					; AH = КОМАНДНЫЙ БАЙТ
;
;------ ГЛАВНЫЙ СЧЕТЧИК
;
RWVF_LOOP:
	MOV	CL,0EH[SI]		; ПОЛУЧ.ЧИСЛА СЕКТОР/ТРЕК  (1..x)
	CMP	AH,WR_FORMAT_CMD	; ТЕКУЩИЙ CMD ЭТО FORMAT ?
	JNE	RWVF_A0			; НЕТ
	MOV	CH,GAP_1		; ДА,УСТАНОВКА GAP ДЛИННЫ
	JMP	short RWVF_S
RWVF_A0:
	SUB	CL,CH			; МАКСИМАЛЬНЫЙ СЕКТОР ВТЕКУЩЕМ ТРЕКЕ
					; (1..x)
	CMP	CL,BL			; ПОСЛЕДНИЙ ТРЕК ДЛЯ ПРОЦЕССА ?
	JB	RWVF_S			; НЕТ
	MOV	CL,BL			; ДА, УСТАНОВКА ВРЕМЕНИ ВЫПОЛНЕНИЯ
RWVF_S:
;
;------ ПОСЫЛКА ПАРАМЕТРОВ В КОНТРОЛЛЕР
;
	PUSH	DX			; СОХРАНЕНИЕ DX
	MOV	AL,DL			; SDH
	OR	AL,DH			; ПРИБАВЛЕНИЕ БИТ ГОЛОВКИ
	PUSH	AX			; ПОСЫЛКА КОМАНДЫ И SDH         (7,6)
;------ ВЫДЕЛЕНИЕ ДИСКА
	MOV	AL,BH			; SDH ДОБАВОЧНЫЙ
	OR	AL,DH			; ПРИБАВЛЕНИЕ БИТ ГОЛОВКИ
	MOV	DX,HD_PORT
	OUT	DX,AL			; ПОВОРОТ ВЫДЕЛЕННОГО ДИСКА
;------ ЗАГРУЗКА ФАЙЛА ЗАДАЧИ  В РЕГИСТР КОМАНД
	CLI				; ЗАПРЕТ ПРЕРЫВАНИЙ НА ВРЕМЯ ЗАГРУЗКИ
	MOV	DL,(WDC_PORT+1) and 0FFH; ПОРТ ЗАПИСИ
	MOV	AX,5[SI]		; ПОЛУЧЕНИЕ ИЗ ТАБЛИЦЫ
	SHR	AX,1
	SHR	AX,1			; ДЕЛИМ НА 4
	OUT	DX,AL			; ПОСЫЛАЕМ Precomp ЦЕЛИНДР 		(1)
	PUSH	DI			; ПОСЫЛАЕМ ЦИЛИНДР (5,4)
	PUSH	CX			; ПОСЫЛАЕМ НОМЕР СЕКТОРА И СЧЕТЧИК (3,2)
OUT_LOOP:
	POP	AX
	INC	DX
	OUT	DX,AL			; ПОСЫЛКА ЧЕТНЫГО БАЙТА
	MOV	AL,AH
	INC	DX
	OUT	DX,AL			; ПОСЫЛКА НЕЧЕТНОГО БАЙТА
	CMP	DL,(WDC_PORT+7) AND 0FFH ; ПОСЛЕДНИЙ OUT ?
	JNE	OUT_LOOP		; НЕТ
;------ РАЗРЕШЕНИЕ DMA
	MOV	AL,3
	OUT	DMA_MASK,AL		; РАЗРЕШЕНИЕ КАНАЛА ДИСКА DMA
	CALL	HWAIT_INT
	IN	AL,DX			; РЕГИСТР СТАТУСА
	POP	DX			; ВОССТАН DX
	MOV	CH,TIME_OUT		; ВРЕМЯ ВЫШЛО ?
	JC	RWVF_EXIT		; ДА, ВРЕМЯ ВЫШЛО
	AND	AL,01100101B		; СБРОС БИТ BUSY,SC,RDQ,CIP
	XOR	AL,01000000B		; ИНВЕРСИЯ БИТ СБРОСА
	JNE	RWVF_ERROR		; WDC ОШИБКА
;------ ВЫЧИСЛЕНИЕ НОВЫХ ПАРАМЕТРОВ
	XOR	CH,CH			; ПЕРВЫЙ СЕКТОР НА ТРЕКЕ
	INC	DH			; ВЫДЕЛЕНИЕ СЛЕДУЮЩЕЙ ГОЛОВКИ
	CMP	DH,2[SI]		; МАКСИМАЛЬНАЯ ГОЛОВКА ?
	JB      RWVF_A1			; НЕТ
	XOR	DH,DH			; ВЫДЕЛЕНИЕ 0 ГОЛОВКИ
	INC	DI			; СЛЕДУЮЩИЙ ЦИЛИНДР
RWVF_A1:
	SUB	BL,CL			; УМЕНЬШЕНИЕ СЧЕТЧИКА
	JA	RWVF_LOOP		; ОБРАБОТКА СЛЕДУЮЩЕГО ТРЕКА
RWVF_EXIT:
	POP	AX			; ВОССТАНОВЛЕНИЕ СЧЕТЧИКА БЛОКА
	SUB	AL,BL			; СЕКТОРА ОБРАБОТАНЫ O.K.
	MOV	AH,CH			; AH = КОД ОШИБКИ (0 ЕСЛИ O.K.)
	RET
RWVF_ERROR:

	PUSH	BX
	XOR	BX,BX
	SHR	AL,1			; СБРОС ФЛАГА ОШИБКИ
	MOV	AH,AL
	MOV	DX,(WDC_PORT+1)		; РЕГИСТР ОШИБОК
	IN	AL,DX			; ПОЛУЧЕНИЕ ОШИБКИ
ERR_SCAN:
	INC	BX
	SHL	AX,1			; БИТ ОШИБКИ?
	JC	ERROR_FOUND
	JNZ	ERR_SCAN
ERROR_FOUND:
	MOV	CH,CS:(WDC_ERR_TBL-3)[BX] ; УСТАНОВКА КОДА ОШИБКИ
	POP	BX

	INC	DX			; 321+1
	IN	AL,DX			; ПОЛУЧЕНИЕ СЧЕТЧИКА СЕКТОРОВ WDC
	SUB	CL,AL			; ЧИСЛО УСПЕШНО ОБРАБОТАННЫХ СЕКТОРОВ
	SUB	BL,CL
	JMP	short RWVF_EXIT
RWVF_OPN         EndP

WDC_ERR_TBL	label	BYTE
	DB	DRIVE_NOT_RDY           ;0AAH
	DB	WRITE_FAULT             ;0CCH
	DB	UNDEF_ERR               ;0BBH
	DB	UNDEF_ERR               ;0BBH
	DB	DATA_CORRECTED		;011H
	DB	UNDEF_ERR               ;0BBH
	DB	BAD_TRACK               ;00BH
	DB	BAD_ECC                 ;010H
	DB	UNDEF_ERR               ;0BBH
	DB	RECORD_NOT_FND          ;004H
	DB	UNDEF_ERR               ;0BBH
	DB	BAD_CNTLR               ;020H
	DB	BAD_SEEK                ;040H
	DB	BAD_ADDR_MARK           ;002H

;-------------------------------------------------------
; SET_PARAM_PTR					           ;
;	ЭТА ПРОЦЕДУРА УСТАНАВЛИВАЕТ УКАЗАТЕЛЬ НА ТАБЛИЦУ   ;
;	ПАРАМЕТРОВ ТЕКУЩЕГО ДИСКА                	   ;
;  ВХОД						           ;
;	DL = НОМЕР ДИСКА (0 ИЛИ 1,ЗНАЧЕНИЕ НЕ ПРОВЕРЯЕТСЯ) ;
; OUTPUT					           ;
;    DS:SI = Pointer to parameter tbl			   ;
;-------------------------------------------------------
SET_PARAM_PTR	proc	near
	PUSH	AX
	XOR	AX,AX			; УСТАНОВКА СЕГМЕНТА ABS0
	MOV	DS,AX

	Assume	DS:ABS0
	MOV	SI,offset HF_TBL_VEC
	OR	DL,DL			; ДИСКОВОД 0 ?
	JZ	SPP_0			; ДА.
	ADD	SI,(HF2_TBL_VEC - HF_TBL_VEC)
SPP_0:
	LDS	SI,[SI]
	POP	AX
	RET
SET_PARAM_PTR	EndP

;-------------------------------------------------------
; HWAIT_INT						;
;	ЭТА ПРОЦЕДУРА ОЖИДАЕТ ВЫПОЛНЕНИЯ ОПЕРАЦИИ       ;
;	И СИГНАЛИЗИРУЕТ, ЕСЛИ ПРОИЗОШЛО ПРЕРЫВАНИЕ      ;
;  ВХОД							;
;	AH = БАЙТ КОМАНДЫ ДЛЯ Intel' 82064		;
;    DS:SI = УКАЗАТЕЛЬ НА ТАБЛИЦУ ПАРАМЕТРОВ
;  ВЫХОД						;
;	CARRY = 0 - НОРМАЛЬНО ВЫПОЛНЕНА
;	      = 1 - ВРЕМЯ ВЫШЛО		;
;-------------------------------------------------------
HWAIT_INT	proc	near
	MOV	AL,9[SI]		; СТАНДАРТНОЕ TIMEOUT
	CMP	AH,I64_FMT_CMD
	JNE	WAIT_START
	MOV	AL,0AH[SI]		; Time Out ПРИ ФОРМАТИРОВАНИИ
WAIT_START:
;
;------ В ЭТОЙ ПРЕРЫВАНИЯ ЗАПРЕЩЕНЫ !
;
	PUSH	DS
	CALL	DDS		        ; УСТАНОВКА СЕГМЕНТА BIOS

	Assume	DS:DATA

	PUSH	AX
;
;------ РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ КОНТРОЛЛЕРА
;
	IN	AL,INT_CTL_PORT+1	; ПОЛУЧЕНИЕ МАСКИ ПРЕРЫВАНИЙ
	AND	AL,not FD_INT_MASK
	OUT	INT_CTL_PORT+1,AL	; РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ ДИСКА
;
	MOV	AX,9000H		; ПРИБОР ЗАНЯТ
	MOV	[HF_EOI],AL		; СБРОС EndOfInt ФЛАГА
	STI				; РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ
	INT	15H			; ОШИБКА НЕ ОБНАРУЖЕНА
	POP	AX			; ВОССТАНОВЛЕНИЕ БАЙТА CMD
	PUSH	CX
WAIT_LOOP:
	TEST	HF_EOI,80H		; ОЖИДАЕТСЯ ПРЕРЫВАНИЕ ?
	JNZ	WAIT_DONE		; ДА. OK.
	LOOP	WAIT_LOOP		; ВНУТРЕННИЙ ЦИКЛ
	DEC	AL
	JNZ	WAIT_LOOP		; ВНЕШНИЙ ЦИКЛ
	CALL	IR_DMA_DISABLE
	STC				; УСТАНОВКА ФЛАГА - TIMEOUT
WAIT_DONE:
	POP	CX
	POP	DS
	RET
HWAIT_INT	EndP
;
;------ ТОЧКА ВХОДА В ПРЕРЫВАНИЕ Ж.ДИСКА
;
HD_INT	proc	FAR
	PUSH	AX			; СОХРАНЕНИЕ РЕГИСТРОВ
	PUSH	DS
	MOV	AL,EOI			; КОНЕЦ ПРЕРЫВАНИЯ
	OUT	INT_CTL_PORT,AL
	CALL	DDS          		; УСТАНОВКА СЕГМЕНТА BIOS
	CALL	IR_DMA_DISABLE
	POP	DS
	POP	AX
	IRET
HD_INT	EndP
;
;------ ЗАПРЕТ ПРЕРЫВАНИЙ И КОНТРОЛЛЕРА DMA
;
IR_DMA_DISABLE:
	PUSH	AX
	IN	AL,INT_CTL_PORT+1	; ПОЛУЧЕНИЕ МАСКИ ПРЕРЫВАНИЙ
	OR	AL,FD_INT_MASK
	OUT	INT_CTL_PORT+1,AL	; ЗАПРЕТ ПРЕРЫВАНИЙ ДИСКА
	MOV	AL,7
	OUT	DMA_MASK,AL		; УСТАНОВКА DMA ДЛЯ ЗАПРЕТА
	MOV	HF_EOI,80H		; УСТАНОВКА ФЛАГА ПРЕРЫВАНИЙ ДИСКА
	STI				; РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ
	MOV	AX,9100H		; ПРЕРЫВАНИЯ УСТАНОВЛЕНЫ
	INT	15H
	POP	AX
	RET				; НЕТ ОШИБКИ

;-------------------------------------------------------
; HDMA_SETUP						;
;	ЭТА ПРОЦЕДУРА ПРОГРАМИРУЕТ DMA          	;
;  ВХОД							;
;	   DI = СЧЕТЧИК БЛОКА (0..80h, ЗНАЧ ПРОВЕР.)	;
;	   AL = БАЙТ ДЛЯ DMA				;
;	   AH = LONG ФЛАГ (cmd ДЛЯ WDC)			;
;	ES:BX = АДРЕС ЧИТАЕМЫХ/ЗАПИСЫВ ДАННЫХ 		;
;  ВЫХОД						;
;	   BX : РАЗРУШЕН 				;
;	   CARRY = 0 - НОРМАЛЬНОЕ ОКОНЧАНИЕ
;		 = 1 - ОШИБКА ГРАНИЦЫ    		;
;-------------------------------------------------------
HDMA_SETUP	proc	near
	PUSH	DX
	PUSH	AX
	PUSH	CX
;
;------ УСТАНОВКА РЕЖИМА DMA
;
	OUT	DMA_F_F,AL		; СБРОС СТЕКА f/f
	MOV	CH,AH			; ЗАПИСЬ LONG ФЛАГА И ПАУЗАe
	OUT	DMA_MODE,AL		; ВЫВОД БАЙТА РЕЖИМА
;
;------ ВЫЧИСЛЕНИЕ DMA И НОМЕРА РЕГИСТРА СТРАНИЦ
;
	AND	AX,3			; НОМЕР КАНАЛА
	MOV	DX,AX
	SHL	DX,1			; DMA БАЗОВЫЙ РЕГИСТР (4 ИЛИ 6)
	PUSH	DX			; ЗАПИСЬ ЕГО
	ADD	AL,7FH			; РЕГИСТР СТРАНИЦ (81 ИЛИ 82)
	PUSH	AX			; ЗАПИСЬ ЕГО
;
;------ ОПРЕДЕЛЕНИЕ БАЗОВОГО АДРЕСА И ЗНАЧЕНИЕ СТРАНИЦЫ
;
	MOV	AX,ES			; ПОЛУЧЕНИЕ ES ЗНАЧЕНИЯ
	MOV	CL,4			; СДВИГ СЧЕТЧИКА
	ROL	AX,CL			; ВРАЩЕНИЕ ВЛЕВО
	PUSH	AX			; ЗАПИСЬ СТАРШИХ 4 БИТ
	AND	AL,0F0H			; ОБНУЛЕНИЕ МЛАДШЕГО НИБЛА
	ADD	AX,BX			; ПРИБАВЛЕНИЕ СМЕЩЕНИЯ
	OUT	DX,AL			; ВЫВОД МЛАДШЕГО АДРЕСА
	PUSH	AX			; ЗАПИСЬ СТАРТОВОГО АДРЕСА В BX
	POP	BX
	MOV	AL,AH
	OUT	DX,AL			; ВЫВОД СТАРШЕГО АДРЕСА
	POP	AX			; ВОССТАНОВЛЕНИЕ СТАРШИХ 4 БИТ
	ADC	AL,0			; ПРИ ПЕРЕНОСЕ НАДО INC
	AND	AL,0FH			; СБРОС СТАРШЕГО НИБЛА (ДЛЯ PC AT)
	POP	DX			; ВОССТАНОВЛЕНИЕ РЕГИСТРА СТРАНИЦ
	OUT     DX,AL			; ВЫВОД СТАРШИХ 4 БИТ РЕГИСТРА СТРАНИЦ
;
;------ ОПРЕДЕЛЕНИЕ СЧЕТЧИКА
;
	MOV	AX,512D			; РАЗМЕР СЕКТОРА
	TEST	CH,LONG_FLAG		; ДЛИННЫЙ ?
	JZ	SHORT_DMA		; НЕТ НОРМАЛЬНЫЙ
	MOV	AL,4			; 512 + 4 БАЙТ ECC
SHORT_DMA:
	MUL	DI			; СЧЕТЧИК ПЕРЕДАЧИ БЛОКА
	POP	DX			; ВОССТАНОВЛЕНИЕ DMA БАЗОВОГО РЕГИСТРА
	INC	DX			; DX = DMA CNT РЕГИСТР
	JNC	ADJUST_DMA		; OK, СЧЕТЧИК ПРАВИЛЬНЫЙ
	NEG	AX			; AX = 0 ?    ( = 64K )
	JC	BOUNDARY_OUT		; НЕТ, ОШИБКА ( > 64K )
ADJUST_DMA:
	DEC	AX			; РЕГУЛИРОВКА
	ADD	BX,AX			; ТЕСТ ДЛЯ 64K ПЕРЕПОЛННИЯ
	OUT     DX,AL			; МЛАДШИЙ БАЙТ СЧЕТЧИКА
	MOV	AL,AH
	OUT     DX,AL			; СТАРШИЙ БАЙТ СЧЕТЧИКА
BOUNDARY_OUT:
	POP	CX			; ВОССТАНОВЛЕНИЕ РЕГИСТРОВ
	POP	AX
	POP	DX
	RET				; CARRY = 1 ЕСЛИ ВЫХОД ЗА ГРАНИЦЫ
HDMA_SETUP	EndP
;----------------------------------------------------------------
H_COM	label	Word			; ТАБЛИЦА ФУНКЦИЙ ПЕРЕСЫЛКИ
	DW	HDISK_RESET		; 000H
	DW	HREAD_STATUS		; 001H
	DW	HDISK_READ		; 002H
	DW	HDISK_WRITE		; 003H
	DW	HDISK_VERF		; 004H
	DW	FMT_TRK			; 005H
	DW	FMT_BAD			; 006H
	DW	FMT_DRV			; 007H
	DW	READ_PARMS		; 008H
	DW	INIT_DRV		; 009H
	DW	RD_LONG			; 00AH
	DW	WR_LONG			; 00BH
	DW	HDISK_SEEK		; 00CH
	DW	HDISK_RESET		; 00DH
	DW	RD_BUFF			; 00EH
	DW	WR_BUFF			; 00FH
	DW	TST_RDY			; 010H
	DW	HDISK_RECAL		; 011H
	DW	RAM_DIAG		; 012H
	DW	CHK_DRV			; 013H
	DW	DISK_RESET		; 014H
	DW	RD_DASD_TYPE		; 015H
	DW	BAD_COMMAND		; 016H
	DW	BAD_COMMAND		; 017H
	DW	BAD_COMMAND		; 018H
	DW	PARK_HEAD		; 019H
H1L	EQU	$-H_COM



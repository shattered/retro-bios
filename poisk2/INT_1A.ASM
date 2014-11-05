;----- INT 1A --------------------------------------------------------------
; TIME_OF_DAY
;	ЭТО ПРЕРЕВАНИЕ ПОЗВОЛЯЕТ УСТАНАВЛИВАТЬ/ЧИТАТЬ CMOC ЧАСЫ
; НА ВХОДЕ
;   (AH) = 0 ЧТЕНИЕ ТЕКУЩЕГО ЗНАЧЕНИЯ CMOS ЧАСОВ
;     ВОЗВРАТ CX = СТАРШИЙ БАЙТ СЧЕТЧИКА
;	      DX = МЛАДШИЙ БАЙТ
;	      AL = 0 ЕСЛИ НЕ ПРОШЛО 24 ЧАСОВ ПОСЛЕ ПОСЛЕДНЕГО ЧТЕНИЯ
;	      <> 0 ЕСЛИ СЛЕДУЮЩИЙ ДЕНЬ
;   (AH) = 1 УСТАНОВКА ЗНАЧЕНИЯ CMOS ЧАСОВ
;	      CX = СТАРШИЙ БАЙТ СЧЕТЧИКА
;	      DX = МЛАДШИЙ БАЙТ СЧЕТЧИКА
; ЗАМЕЧАНИЕ: СЧЕТ ИДЕТ СО СКОРОСТЬЮ 1193180/65536 РАЗ В СЕКУНДУ
;	(ИЛИ ОКОЛО 18.2 РАЗА В СЕКУНДУ - СМОТРИ ОПЕРАТОРЫ EQU)
;   (AH) = 2 ЧТЕНИЕ ТЕКУЩЕГО ВРЕМЕНИ
;     ВОЗВРАТ CH = ЧАСЫ В BCD КОДЕ
;	      CL = МИНУТЫ В BCD КОДЕ
;	      DH = СЕКУНДЫ В BCD КОДЕ
;   (AH) = 3 УСТАНОВКА ТЕКУЩЕГО ВРЕМЕНИ
;	      CH = ЧАСЫ В BCD КОДЕ
;	      CL = МИНУТЫ В BCD КОДЕ
;	      DH = СЕКУНДЫ В BCD КОДЕ
;	      DL = 1 ЕСЛИ ПЕРВАЯ ПОЛОВИНА ДНЯ, ИНАЧЕ 0
;   (AH) = 4 ЧТЕНИЕ ДАТЫ ИЗ ЧАСОВ CMOS
;     ВОЗВРАТ CH = СТОЛЕТИЕ В BCD (19 ИЛИ 20)
;	      CL = ГОД В BCD
;	      DH = МЕСЯЦ В BCD
;	      DL = ДЕНЬ В BCD
;   (AH) = 5 УСТАНОВКА ДАТЫ В ЧАСАХ CMOS
;	      CH = СТОЛЕТИЕ В BCD (19 OR 20)
;	      CL = ГОД В BCD
;	      DH = МЕСЯЦ В BCD
;	      DL = ДЕНЬ В BCD
;   (AH) = 6 УСТАНОВКА СИГНАЛА
;	     СИГНАЛ МОЖЕТ БЫТЬ УСТАНОВЛЕН ПО ВРЕМЕНИ ДО 23:59:59
;	     ОДНА ФУНКЦИЯ СИГНАЛА МОЖЕТ БЫТЬ АКТИВНА В ЛЮБОЕ ВРЕМЯ
;	      CH = ЧАСЫ В BCD
;	      CL = МИНУТЫ В BCD
;	      DH = СЕКУНДЫ В BCD
;   (AH) = 7 СБРОС СИГНАЛА
; ЗАМЕЧАНИЕ: ДЛЯ AH = 2, 4, 6 - ФЛАГ CY УСТАНОВЛЕН ЕСЛИ ЧАСЫ НЕ РАБОТАЮТ
;	ДЛЯ AH = 6 - ФЛАГ CY УСТАНОВЛЕН ЕСЛИ СИГНАЛ УЖЕ ВКЛЮЧЕН
; ЗАМЕЧАНИЕ: ДЛЯ ФУНКЦИИ УСТАНОВКИ СИГНАЛА (AH = 6) ПОЛЬЗОВАТЕЛЬ
; ДОЛЖЕН ПРАВИЛЬНО УСТАНОВИТЬ АДРЕС ПРЕРЫВАНИЯ INT 4AH В ТАБЛИЦЕ ВЕКТОРОВ
;---------------------------------------------------------------------------

	assume	cs:code,ds:data
TIME_2:
TIME_OF_DAY_1	PROC	FAR
  STI				;РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ
  push	ds
  CALL	 DDS			;SET DATA SEGMENT
  OR	 AH,AH			;AH = 0
  JZ	 T2			;READ_TIME
  DEC	 AH			;AH = 1
  JZ	 T3			;SET_TIME
  CMP	 AH,07			;ПРОВЕРКА НА ПРАВИЛЬНОСТЬ
  JGE	 T1			;ВОЗВРАТ ЕСЛИ НЕТ
  JMP    short RTC_0            ;ПРОВЕРКА ДРУГИХ РЕЖИМОВ
T1:
  STI				;РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ
  POP	 DS			;ВОСТАНАВЛИВАЕМ СЕГМЕНТ
  IRET
T1_A:
  STC				;УСТАНОВКА ЩШИБКИ ВОЗВРАТА
  POP	 DS
  RET	 2
T2:				;READ_TIME
  CLI				;ПОКА ЧТЕНИЕ ЗАПРЕТ ПРЕРЫВАНИЙ
  MOV	 AL,TIMER_OFL
  MOV	 TIMER_OFL,0		;ВЗЯТЬ ЗНАЧЕНИЕ И УСТАНОВИТЬ ФЛАГ
  MOV	 CX,TIMER_HIGH
  MOV	 DX,TIMER_LOW
  JMP	 T1			;TOD_RETURN
T3:				;SET_TIME
  CLI				;ПОКА ЧТЕНИЕ ЗАПРЕТ ПРЕРЫВАНИЙ
  MOV	 TIMER_LOW,DX
  MOV	 TIMER_HIGH,CX		;УСТАНОВКА ВРЕМЕНИ
  MOV	 TIMER_OFL,00		;СБРОС ФЛАГА
  JMP	 T1			;TOD_RETURN
RTC_0:
  DEC	 AH			;AH = 2
  JZ	 RTC_2			;ЧТЕНИЕ CMOS ВРЕМЕНИ
  DEC	 AH			;AH = 3
  JZ	 RTC_3			;УСТАНОВКА CMOS ВРЕМЕНИ
  JMP	 RTC_1			;ПРОВЕРКА ОСТАВШИХСЯ ФУНКЦИЙ
RTC_GET_TIME	PROC	NEAR
RTC_2:
  CALL	 UPD_IN_PR		;ПРОВЕРКА ДЛЯ ИЗМЕНЕНИЙ В ПРОЦЕССЕ
  JNC	 RTC_2A 		;ДАЛЬШЕ ЕСЛИ OK
  JMP	 T1_A			;ВОЗВРАТ ЕСЛИ ОШИБКА
RTC_2A:
  CLI				;ЗАПРЕТ ПРЕРЫВАНИЙ
  MOV	 DL,-2
  CALL	 PORT_INC_2		;УСТАНОВИТЬ АДРЕС СЕКУНД
  IN	 AL,CMOS_PORT+1
  MOV	 DH,AL			;ЗАПОМНИТЬ
  CALL	 PORT_INC_2		;УСТАНОВИТЬ АДРЕС МИНУТ
  IN	 AL,CMOS_PORT+1
  MOV	 CL,AL			;ЗАПОМНИТЬ
  CALL	 PORT_INC_2		;УСТАНОВИТЬ АДРЕС ЧАСОВ
  IN	 AL,CMOS_PORT+1
  MOV	 CH,AL			;ЗАПОМНИТЬ
  MOV	 DL,00			;УСТАНОВИТЬ DL В 0
  JMP	 T1			;ВОЗВРАТ
RTC_GET_TIME	ENDP
;	ORG 0E506H
RTC_SET_TIME	PROC	NEAR
RTC_3:
  CALL	 UPD_IN_PR		;ПРОВЕРКА ДЛЯ ИЗМЕНЕНИЙ В ПРОЦЕССЕ
  JNC	 RTC_3A 		;ПРОДОЛЖИТЬ ЕСЛИ ЧАСЫ РАБОТАЮТ
  CALL	 INITIALIZE_STATUS
RTC_3A:
  CLI				;ПОКА УСТАНОВКА ЗАПРЕТ ПРЕРЫВАНИЙ
  PUSH	 DX			;ЗАПОМНИТЬ
  MOV	 DL,-2			;ПЕРВЫЙ АДРЕС
  CALL	 PORT_INC_2		;ИЗМЕНИТЬ АДРЕС
  MOV	 AL,DH			;ВЗЯТЬ БИТ ВРЕМЕНИ - СЕКУНДЫ
  OUT	 CMOS_PORT+1,AL 	;ЗАПИСАТЬ БИТ
  CALL	 PORT_INC_2		;ИЗМЕНИТЬ АДРЕС
  MOV	 AL,CL			;ВЗЯТЬ БИТ ВРЕМЕНИ - МИНУТЫ
  OUT	 CMOS_PORT+1,AL 	;ЗАПИСАТЬ БИТ
  CALL	 PORT_INC_2		;ИЗМЕНИТЬ АДРЕС
  MOV	 AL,CH			;ВЗЯТЬ БИТ ВРЕМЕНИ - ЧАСЫ
  OUT	 CMOS_PORT+1,AL 	;ЗАПИСАТЬ БИТ
  MOV	 DL,0AH
  CALL	 PORT_INC
  POP	 DX			;ВОСТАНОВИТЬ
  IN	 AL,CMOS_PORT+1 	;ВЗЯТЬ ТЕКУЩЕЕ ЗНАЧЕНИЕ
  AND	 AL,23H 		;МАСКА ДЛЯ ПРАВИЛЬНОЙ ПОЗИЦИИ БИТА
  OR	 AL,DL			;ВЗЯТЬ DST БИТ
  OR	 AL,02			;ВКЛЮЧИТЬ 24-ЧАСОВОЙ РЕЖИМ
  PUSH	 AX
  MOV	 DL,0AH
  CALL	 PORT_INC
  POP	 AX
  OUT	 CMOS_PORT+1,AL
  JMP	 T1			;ВЫПОЛНЕНО
RTC_SET_TIME	ENDP
   
RTC_GET_DATE	PROC	NEAR
RTC_4:
  CALL	 UPD_IN_PR
  JNC	 RTC_4A 		;ВОЗВРАТ ЕСЛИ ОШИБКА
  JMP	 T1_A
RTC_4A:
  CLI				;ПОКА УСТАНОВКА ЗАПРЕТ ПРЕРЫВАНИЙ
  MOV	 DL,06
  CALL	 PORT_INC		;УКАЗАТЕЛЬ НА ДЕНЬ
  IN	 AL,CMOS_PORT+1
  MOV	 CH,AL			;ЗАПОМНИТЬ
  CALL	 PORT_INC		;УКАЗАТЕЛЬ НА МЕСЯЦ
  IN	 AL,CMOS_PORT+1
  MOV	 DH,AL			;ЗАПОМНИТЬ
  CALL	 PORT_INC		;УКАЗАТЕЛЬ НА ГОД
  IN	 AL,CMOS_PORT+1
  MOV	 CL,AL			;ЗАПОМНИТЬ
  MOV	 DL,31H 		;УКАЗАТЕЛЬ НА БАЙТ ВЕКА
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;ВЗЯТЬ ЗНАЧЕНИЕ
  MOV	 DL,CH			;GET DAY BACK
  MOV	 CH,AL
  JMP	 T1			;ФИНИШ
RTC_GET_DATE	ENDP
RTC_1:
  DEC	 AH			;AH = 4
  JZ	 RTC_4			;ПРОЧИТАТЬ ДАТУ ИЗ CMOS
  DEC	 AH			;AH = 5
  JZ	 RTC_5			;УСТАНОВИТЬ ДАТУ В CMOS
  DEC	 AH			;AH = 6
  JZ	 RTC_6			;УСТАНОВИТЬ СИГНАЛ В CMOS
  JMP    RTC_7                  ;СБРОС СИГНАЛА CMOS
SOOB_1	DB	'All right reserved',0
        ORG  0E506H

RTC_SET_DATE	PROC	NEAR
RTC_5:
  CALL	 UPD_IN_PR		;ПРОВЕРКА ДЛЯ ИЗМЕНЕНИЙ В ПРОЦЕССЕ
  JNC	 RTC_5A 		;ДАЛЬШЕ ЕСЛИ ЧАСЫ ИЗМЕНЕНЫ
  CALL	 INITIALIZE_STATUS
RTC_5A:
  CLI				;ПОКА УСТАНОВКА ЗАПРЕТ ПРЕРЫВАНИЙ
  PUSH	 CX			;ЗАПОМНИТЬ
  MOV	 CH,DL			;ЗАПОМНИТЬ ДЕНЬ МЕСЯЦА
  MOV	 DL,5			;АДРЕС РЕГИСТРА ДНЯ НЕДЕЛИ
  CALL	 PORT_INC
  MOV	 AL,00H
  OUT	 CMOS_PORT+1,AL 	;ОБНУЛИТЬ БАЙТ 'ДЕНЬ НЕДЕЛИ'
  CALL	 PORT_INC		;АДРЕС РЕГИСТРА ДНЯ МЕСЯЦА
  MOV	 AL,CH			;ВЗЯТЬ БАЙТ 'ДЕНЬ МЕСЯЦА'
  OUT	 CMOS_PORT+1,AL 	;ЗАПОМНИТЬ
  CALL	 PORT_INC		;АДРЕС РЕГИСТРА МЕСЯЦА
  MOV	 AL,DH			;ВЗЯТЬ БАЙТ 'МЕСЯЦ'
  OUT	 CMOS_PORT+1,AL 	;ЗАПОМНИТЬ
  CALL	 PORT_INC		;АДРЕС РЕГИСТРА ГОДА
  MOV	 AL,CL			;ВЗЯТЬ БАЙТ 'ГОД'
  OUT	 CMOS_PORT+1,AL 	;ЗАПОМНИТЬ
  MOV	 DL,0AH
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;ВЗЯТЬ ТЕКУЩУЮ УСТАНОВКУ
  AND	 AL,07FH		;ОЧИСТИТЬ 'SET BIT'
  OUT	 CMOS_PORT+1,AL 	;И НАЧАТЬ ЗАПИСЬ ЧАСОВ
  POP	 CX			;ВОЗВРАТИТЬ ОБРАТНО
  MOV	 DL,31H 		;УЛАЗАТЕЛЬ НА ЗАПИСАННУЮ ОБЛАСТЬ
  CALL	 PORT_INC
  MOV	 AL,CH			;ВЗЯТЬ БАЙТ ВЕКА
  OUT	 CMOS_PORT+1,AL 	;ЗАПОМНИТЬ
  JMP	 T1			;ВОЗВРАТ
RTC_SET_DATE  ENDP

RTC_SET_ALARM  PROC  NEAR
;	org	0e506h
RTC_6:
  MOV	 DL,0AH 		;ПРОВЕРКА НА УСТАНОВЛЕННЫЙ СИГНАЛ
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;ВЗЯТЬ ТЕКУЩУЮ УСТАНОВКУ СИГНАЛА
  TEST	 AL,20H
  JZ	 RTC_6A 		;СИГНАЛ НЕ УСТАНОВЛЕН - ВЫПОЛНЕНИЕ
  XOR	 AX,AX			;
  JMP	 T1_A			;ВОЗВРАТ ЕСЛИ ОШИБКА
RTC_6A:
  CALL	 UPD_IN_PR		;ПРОВЕРКА ДЛЯ ИЗМЕНЕНИЙ В ПРОЦЕССЕ
  JNC	 RTC_6B
  CALL	 INITIALIZE_STATUS
RTC_6B:
  CLI				;ПОКА УСТАНОВКА ЗАПРЕТ ПРЕРЫВАНИЙ
  MOV	 DL,-1
  CALL	 PORT_INC_2
  MOV	 AL,DH			;ВЗЯТЬ БАЙТ СЕКУНД
  OUT	 CMOS_PORT+1,AL 	;ЗАГРУЗИТЬ БАЙТ СИГНАЛА - СЕКУНДЫ
  CALL	 PORT_INC_2
  MOV	 AL,CL			;ВЗЯТЬ ПАРАМЕТРЫ МИНУТ
  OUT	 CMOS_PORT+1,AL 	;ЗАГРУЗИТЬ БАЙТ СИГНАЛА - МИНУТЫ
  CALL	 PORT_INC_2
  MOV	 AL,CH			;ВЗЯТЬ ПАРАМЕТРЫ ЧАСОВ
  OUT	 CMOS_PORT+1,AL 	;ЗАГРУЗИТЬ БАЙТ СИГНАЛА - ЧАСЫ
  IN	 AL,0A1H		;ГАРАНТИРОВАННОЕ РАЗРЕШЕННОЕ ПРЕРЫВАНИЕ
  AND	 AL,0FEH
  OUT	 0A1H,AL
  MOV	 DL,0AH
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;ВЗЯТЬ ТЕКУЩЕЕ ЗНАЧЕНИЕ
  AND	 AL,07FH		;ГАРАНТИРОВАННАЯ УСТАНОВКА БИТА
  OR	 AL,20H 		;ВКЛЮЧИТЬ ВОЗМОЖНОСТЬ СИГНАЛА
  PUSH	 AX
  MOV	 DL,0AH
  CALL	 PORT_INC
  POP	 AX
  OUT	 CMOS_PORT+1,AL 	;СИГНАЛ ВОЗМОЖЕН
  JMP	 T1
RTC_SET_ALARM  ENDP

RTC_RESET_ALARM  PROC  NEAR
RTC_7:
  CLI				;БЛОКИРОВКА ПРЕРЫВАНИЙ ПОКА УСТАНОВКА
  MOV	 DL,0AH
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;ВЗЯТЬ БАЙТ СТАТУСА
  AND	 AL,57H 		;ВЫКЛЮЧИТЬ ВОЗМОЖНОСТЬ СИГНАЛА
  PUSH	 AX			;ЗАПОМНИТЬ
  MOV	 DL,0AH
  CALL	 PORT_INC
  POP	 AX
  OUT	 CMOS_PORT+1,AL 	;ВОСТАНОВИТЬ
  JMP	 T1
RTC_RESET_ALARM  ENDP

RTC_TIMEBIOS_SUBR  PROC  NEAR
PORT_INC:
  INC	 DL			;УВЕЛИЧИТЬ АДРЕС
  MOV	 AL,DL
  OUT	 CMOS_PORT,AL
  RET
PORT_INC_2:
  ADD	 DL,2			;УВЕЛИЧИТЬ АДРЕС
  MOV	 AL,DL
  OUT	 CMOS_PORT,AL
  RET
INITIALIZE_STATUS  PROC NEAR
  PUSH	 DX			;ЗАПОМНИТЬ
  MOV	 DL,09H
  CALL	 PORT_INC
  MOV	 AL,26H
  OUT	 CMOS_PORT+1,AL 	;ИНИЦИАЛИЗИРОВАТЬ РЕГИСТР  'A'
  CALL	 PORT_INC
  MOV	 AL,82H 		;УСТАНОВИТЬ БИТ 'SET BIT' ДЛЯ
				;ИНИЦИАЛИЗАЦИИ ЧАСОВ И 24 ЧАСОВОГО РЕЖИМА
  OUT	 CMOS_PORT+1,AL 	;ИНИЦИАЛИЗИРОВАТЬ РЕГИСТР 'B'
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;ЧТЕНИЕ РЕГИСТРА 'C' ДЛЯ ИНИЦИАЛИЗАЦИИ
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;ЧТЕНИЕ РЕГИСТРА 'D' ДЛЯ ИНИЦИАЛИЗАЦИИ
  POP	 DX			;ВОСТАНОВИТЬ
  RET
INITIALIZE_STATUS  ENDP

UPD_IN_PR:
  PUSH	 CX
  MOV	 CX,600 		;УСТАНОВИТЬ СЧЕТЧИК ЦИКЛОВ
UPDATE:
  MOV	 AL,0AH 		;АДРЕС РЕГИСТРА 'A'
  OUT	 CMOS_PORT,AL
  JMP	 SHORT $+2		;I/O ВРЕМЕННАЯ ЗАДЕРЖКА
  IN	 AL,CMOS_PORT+1 	;ЧТЕНИЕ В РЕГИСТР 'A'
  TEST	 AL,80H 		;ЕСЛИ 8XH-->UIP БИТ ВКЛЮЧЕН
				;(НЕЛЬЗЯ ЧИТАТЬ ВРЕМЯ)
  JZ	 UPD_IN_PREND
  LOOP	 UPDATE
  XOR	 AX,AX
  STC				;УСТАНОВКА CARRY ДЛЯ ОШИБКИ
UPD_IN_PREND:
  POP	 CX
  RET
RTC_TIMEBIOS_SUBR  ENDP
TIME_OF_DAY_1  ENDP


otsl_1  proc near
;отслеживание переполнения
	MOV	BX,160*2+19*2
	MOV	CX,3630H
	MOV	DX,3539H
	CALL	OTSL
	MOV	BX,160*2+16*2
	CALL	OTSL
	MOV	BX,160*4+19*2
	CALL	OTSL
	MOV	BX,160*4+16*2
	CALL	OTSL
	MOV	BX,160*2+13*2
	MOV	CX,3234H
	MOV	DX,3233H
	CALL	OTSL
	MOV	BX,160*4+13*2
	CALL	OTSL
	MOV	CX,3332H
	MOV	DX,3331H
	MOV	BX,160*3+13*2
	CALL	OTSL
	MOV	CX,3133H
	MOV	DX,3132H
	MOV	BX,160*3+16*2
	CALL	OTSL
	MOV	CX,3035H
	MOV	DX,3034H
	MOV	BX,160*6+13*2
	CALL	OTSL
	MOV	BX,160*7+13*2
	CALL	OTSL
;hard
	MOV	CX,3136H
	MOV	DX,3135H
	MOV	BX,160*8+13*2
OT_1:	CALL	OTSL
;adapter
	MOV	CX,3034H
	MOV	DX,3033H
	MOV	BX,160*9+13*2
	CALL	OTSL
	ret
otsl_1	endp	
;отслеживание
;BX-адрес,CX-максимальное значение DX=CX-1, AX-минимальное значение
OTSL	PROC  NEAR
	MOV	AL,byte ptr ES:[BX+2]
	MOV	AH,byte ptr ES:[BX]
	CMP	AX,CX
	jb	rt_1
	MOV	byte ptr ES:[BX],30H
	MOV	byte ptr ES:[BX+2],30H
RT_1:   CMP	AX,3939H
	jb	rt_2
	MOV	byte ptr ES:[BX],DH
	MOV	byte ptr ES:[BX+2],DL
RT_2:   RET
OTSL	ENDP

CMOS_MEM PROC NEAR
	call	dds
        MOV     BX,MEMORY_SIZE
	MOV	AL,16H
	OUT 	CMOS_PORT,AL
	IN	AL,CMOS_PORT+1
	MOV	AH,AL
	MOV	AL,15H
	OUT 	CMOS_PORT,AL
	IN	AL,CMOS_PORT+1
	CMP	AX,BX
	JA	WEL_1
	XCHG	AX,BX
;установка размера памяти из CMOS
	CALL	CMOS_DIAG1
	TEST	AL,0DH
	JNZ	WEL_1
	MOV     MEMORY_SIZE,BX    	;SAVE MEMORY SIZE
WEL_1:  RET
CMOS_MEM ENDP

H_ARD	DB	'Hard',0
A_DAP	DB	'Adapter',0
ROM_S	DB	'System M',0
EMS_S	DB	'EMS size',0

SOOB_2	DB	'SET_UP POISK 1991',0

DISK_0	DB	'None ',0
DISK_2  DB	'360K ',0
DISK_3  DB	'1.2M ',0
DISK_5  DB	'1.44M',0
DISK_4  DB	'720K ',0
ADAPT1	DB	'Ega,Vga   ',0
ADAPT2	DB	'Cga 40-clm',0
ADAPT3	DB	'Cga 80-clm',0
ADAPT4	DB	'Monochrome',0

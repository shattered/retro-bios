;----- INT 1A --------------------------------------------------------------
; TIME_OF_DAY
;	üפן נעועוקבמיו נןתקןלסופ ץףפבמבקליקבפר/‏יפבפר CMOC ‏בףש
; מב קטןהו
;   (AH) = 0 ‏פומיו פוכץ‎וחן תמב‏ומיס CMOS ‏בףןק
;     קןתקעבפ CX = ףפבעûיך גבךפ ף‏ופ‏יכב
;	      DX = םלבהûיך גבךפ
;	      AL = 0 וףלי מו נעןûלן 24 ‏בףןק נןףלו נןףלוהמוחן ‏פומיס
;	      <> 0 וףלי ףלוהץא‎יך הומר
;   (AH) = 1 ץףפבמןקכב תמב‏ומיס CMOS ‏בףןק
;	      CX = ףפבעûיך גבךפ ף‏ופ‏יכב
;	      DX = םלבהûיך גבךפ ף‏ופ‏יכב
; תבםו‏במיו: ף‏ופ יהופ ףן ףכןעןףפרא 1193180/65536 עבת ק ףוכץמהץ
;	(ילי ןכןלן 18.2 עבתב ק ףוכץמהץ - ףםןפעי ןנועבפןעש EQU)
;   (AH) = 2 ‏פומיו פוכץ‎וחן קעוםומי
;     קןתקעבפ CH = ‏בףש ק BCD כןהו
;	      CL = םימץפש ק BCD כןהו
;	      DH = ףוכץמהש ק BCD כןהו
;   (AH) = 3 ץףפבמןקכב פוכץ‎וחן קעוםומי
;	      CH = ‏בףש ק BCD כןהו
;	      CL = םימץפש ק BCD כןהו
;	      DH = ףוכץמהש ק BCD כןהו
;	      DL = 1 וףלי נועקבס נןלןקימב המס, ימב‏ו 0
;   (AH) = 4 ‏פומיו הבפש ית ‏בףןק CMOS
;     קןתקעבפ CH = ףפןלופיו ק BCD (19 ילי 20)
;	      CL = חןה ק BCD
;	      DH = םוףסד ק BCD
;	      DL = הומר ק BCD
;   (AH) = 5 ץףפבמןקכב הבפש ק ‏בףבט CMOS
;	      CH = ףפןלופיו ק BCD (19 OR 20)
;	      CL = חןה ק BCD
;	      DH = םוףסד ק BCD
;	      DL = הומר ק BCD
;   (AH) = 6 ץףפבמןקכב ףיחמבלב
;	     ףיחמבל םןצופ גשפר ץףפבמןקלומ נן קעוםומי הן 23:59:59
;	     ןהמב זץמכדיס ףיחמבלב םןצופ גשפר בכפיקמב ק לאגןו קעוםס
;	      CH = ‏בףש ק BCD
;	      CL = םימץפש ק BCD
;	      DH = ףוכץמהש ק BCD
;   (AH) = 7 ףגעןף ףיחמבלב
; תבםו‏במיו: הלס AH = 2, 4, 6 - זלבח CY ץףפבמןקלומ וףלי ‏בףש מו עבגןפבאפ
;	הלס AH = 6 - זלבח CY ץףפבמןקלומ וףלי ףיחמבל ץצו קכלא‏ומ
; תבםו‏במיו: הלס זץמכדיי ץףפבמןקכי ףיחמבלב (AH = 6) נןלרתןקבפולר
; הןלצומ נעבקילרמן ץףפבמןקיפר בהעוף נעועשקבמיס INT 4AH ק פבגלידו קוכפןעןק
;---------------------------------------------------------------------------

	assume	cs:code,ds:data
TIME_2:
TIME_OF_DAY_1	PROC	FAR
  STI				;עבתעוûומיו נעועשקבמיך
  push	ds
  CALL	 DDS			;SET DATA SEGMENT
  OR	 AH,AH			;AH = 0
  JZ	 T2			;READ_TIME
  DEC	 AH			;AH = 1
  JZ	 T3			;SET_TIME
  CMP	 AH,07			;נעןקועכב מב נעבקילרמןףפר
  JGE	 T1			;קןתקעבפ וףלי מופ
  JMP    short RTC_0            ;נעןקועכב העץחיט עוציםןק
T1:
  STI				;עבתעוûומיו נעועשקבמיך
  POP	 DS			;קןףפבמבקליקבום ףוחםומפ
  IRET
T1_A:
  STC				;ץףפבמןקכב ‎ûיגכי קןתקעבפב
  POP	 DS
  RET	 2
T2:				;READ_TIME
  CLI				;נןכב ‏פומיו תבנעופ נעועשקבמיך
  MOV	 AL,TIMER_OFL
  MOV	 TIMER_OFL,0		;קתספר תמב‏ומיו י ץףפבמןקיפר זלבח
  MOV	 CX,TIMER_HIGH
  MOV	 DX,TIMER_LOW
  JMP	 T1			;TOD_RETURN
T3:				;SET_TIME
  CLI				;נןכב ‏פומיו תבנעופ נעועשקבמיך
  MOV	 TIMER_LOW,DX
  MOV	 TIMER_HIGH,CX		;ץףפבמןקכב קעוםומי
  MOV	 TIMER_OFL,00		;ףגעןף זלבחב
  JMP	 T1			;TOD_RETURN
RTC_0:
  DEC	 AH			;AH = 2
  JZ	 RTC_2			;‏פומיו CMOS קעוםומי
  DEC	 AH			;AH = 3
  JZ	 RTC_3			;ץףפבמןקכב CMOS קעוםומי
  JMP	 RTC_1			;נעןקועכב ןףפבקûיטףס זץמכדיך
RTC_GET_TIME	PROC	NEAR
RTC_2:
  CALL	 UPD_IN_PR		;נעןקועכב הלס יתםומומיך ק נעןדוףףו
  JNC	 RTC_2A 		;הבלרûו וףלי OK
  JMP	 T1_A			;קןתקעבפ וףלי ןûיגכב
RTC_2A:
  CLI				;תבנעופ נעועשקבמיך
  MOV	 DL,-2
  CALL	 PORT_INC_2		;ץףפבמןקיפר בהעוף ףוכץמה
  IN	 AL,CMOS_PORT+1
  MOV	 DH,AL			;תבנןםמיפר
  CALL	 PORT_INC_2		;ץףפבמןקיפר בהעוף םימץפ
  IN	 AL,CMOS_PORT+1
  MOV	 CL,AL			;תבנןםמיפר
  CALL	 PORT_INC_2		;ץףפבמןקיפר בהעוף ‏בףןק
  IN	 AL,CMOS_PORT+1
  MOV	 CH,AL			;תבנןםמיפר
  MOV	 DL,00			;ץףפבמןקיפר DL ק 0
  JMP	 T1			;קןתקעבפ
RTC_GET_TIME	ENDP
;	ORG 0E506H
RTC_SET_TIME	PROC	NEAR
RTC_3:
  CALL	 UPD_IN_PR		;נעןקועכב הלס יתםומומיך ק נעןדוףףו
  JNC	 RTC_3A 		;נעןהןלציפר וףלי ‏בףש עבגןפבאפ
  CALL	 INITIALIZE_STATUS
RTC_3A:
  CLI				;נןכב ץףפבמןקכב תבנעופ נעועשקבמיך
  PUSH	 DX			;תבנןםמיפר
  MOV	 DL,-2			;נועקשך בהעוף
  CALL	 PORT_INC_2		;יתםומיפר בהעוף
  MOV	 AL,DH			;קתספר גיפ קעוםומי - ףוכץמהש
  OUT	 CMOS_PORT+1,AL 	;תבניףבפר גיפ
  CALL	 PORT_INC_2		;יתםומיפר בהעוף
  MOV	 AL,CL			;קתספר גיפ קעוםומי - םימץפש
  OUT	 CMOS_PORT+1,AL 	;תבניףבפר גיפ
  CALL	 PORT_INC_2		;יתםומיפר בהעוף
  MOV	 AL,CH			;קתספר גיפ קעוםומי - ‏בףש
  OUT	 CMOS_PORT+1,AL 	;תבניףבפר גיפ
  MOV	 DL,0AH
  CALL	 PORT_INC
  POP	 DX			;קןףפבמןקיפר
  IN	 AL,CMOS_PORT+1 	;קתספר פוכץ‎וו תמב‏ומיו
  AND	 AL,23H 		;םבףכב הלס נעבקילרמןך נןתידיי גיפב
  OR	 AL,DL			;קתספר DST גיפ
  OR	 AL,02			;קכלא‏יפר 24-‏בףןקןך עוצים
  PUSH	 AX
  MOV	 DL,0AH
  CALL	 PORT_INC
  POP	 AX
  OUT	 CMOS_PORT+1,AL
  JMP	 T1			;קשנןלמומן
RTC_SET_TIME	ENDP
   
RTC_GET_DATE	PROC	NEAR
RTC_4:
  CALL	 UPD_IN_PR
  JNC	 RTC_4A 		;קןתקעבפ וףלי ןûיגכב
  JMP	 T1_A
RTC_4A:
  CLI				;נןכב ץףפבמןקכב תבנעופ נעועשקבמיך
  MOV	 DL,06
  CALL	 PORT_INC		;ץכבתבפולר מב הומר
  IN	 AL,CMOS_PORT+1
  MOV	 CH,AL			;תבנןםמיפר
  CALL	 PORT_INC		;ץכבתבפולר מב םוףסד
  IN	 AL,CMOS_PORT+1
  MOV	 DH,AL			;תבנןםמיפר
  CALL	 PORT_INC		;ץכבתבפולר מב חןה
  IN	 AL,CMOS_PORT+1
  MOV	 CL,AL			;תבנןםמיפר
  MOV	 DL,31H 		;ץכבתבפולר מב גבךפ קוכב
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;קתספר תמב‏ומיו
  MOV	 DL,CH			;GET DAY BACK
  MOV	 CH,AL
  JMP	 T1			;זימיû
RTC_GET_DATE	ENDP
RTC_1:
  DEC	 AH			;AH = 4
  JZ	 RTC_4			;נען‏יפבפר הבפץ ית CMOS
  DEC	 AH			;AH = 5
  JZ	 RTC_5			;ץףפבמןקיפר הבפץ ק CMOS
  DEC	 AH			;AH = 6
  JZ	 RTC_6			;ץףפבמןקיפר ףיחמבל ק CMOS
  JMP    RTC_7                  ;ףגעןף ףיחמבלב CMOS
SOOB_1	DB	'All right reserved',0
        ORG  0E506H

RTC_SET_DATE	PROC	NEAR
RTC_5:
  CALL	 UPD_IN_PR		;נעןקועכב הלס יתםומומיך ק נעןדוףףו
  JNC	 RTC_5A 		;הבלרûו וףלי ‏בףש יתםומומש
  CALL	 INITIALIZE_STATUS
RTC_5A:
  CLI				;נןכב ץףפבמןקכב תבנעופ נעועשקבמיך
  PUSH	 CX			;תבנןםמיפר
  MOV	 CH,DL			;תבנןםמיפר הומר םוףסדב
  MOV	 DL,5			;בהעוף עוחיףפעב המס מוהולי
  CALL	 PORT_INC
  MOV	 AL,00H
  OUT	 CMOS_PORT+1,AL 	;ןגמץליפר גבךפ 'הומר מוהולי'
  CALL	 PORT_INC		;בהעוף עוחיףפעב המס םוףסדב
  MOV	 AL,CH			;קתספר גבךפ 'הומר םוףסדב'
  OUT	 CMOS_PORT+1,AL 	;תבנןםמיפר
  CALL	 PORT_INC		;בהעוף עוחיףפעב םוףסדב
  MOV	 AL,DH			;קתספר גבךפ 'םוףסד'
  OUT	 CMOS_PORT+1,AL 	;תבנןםמיפר
  CALL	 PORT_INC		;בהעוף עוחיףפעב חןהב
  MOV	 AL,CL			;קתספר גבךפ 'חןה'
  OUT	 CMOS_PORT+1,AL 	;תבנןםמיפר
  MOV	 DL,0AH
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;קתספר פוכץ‎ץא ץףפבמןקכץ
  AND	 AL,07FH		;ן‏יףפיפר 'SET BIT'
  OUT	 CMOS_PORT+1,AL 	;י מב‏בפר תבניףר ‏בףןק
  POP	 CX			;קןתקעבפיפר ןגעבפמן
  MOV	 DL,31H 		;ץלבתבפולר מב תבניףבממץא ןגלבףפר
  CALL	 PORT_INC
  MOV	 AL,CH			;קתספר גבךפ קוכב
  OUT	 CMOS_PORT+1,AL 	;תבנןםמיפר
  JMP	 T1			;קןתקעבפ
RTC_SET_DATE  ENDP

RTC_SET_ALARM  PROC  NEAR
;	org	0e506h
RTC_6:
  MOV	 DL,0AH 		;נעןקועכב מב ץףפבמןקלוממשך ףיחמבל
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;קתספר פוכץ‎ץא ץףפבמןקכץ ףיחמבלב
  TEST	 AL,20H
  JZ	 RTC_6A 		;ףיחמבל מו ץףפבמןקלומ - קשנןלמומיו
  XOR	 AX,AX			;
  JMP	 T1_A			;קןתקעבפ וףלי ןûיגכב
RTC_6A:
  CALL	 UPD_IN_PR		;נעןקועכב הלס יתםומומיך ק נעןדוףףו
  JNC	 RTC_6B
  CALL	 INITIALIZE_STATUS
RTC_6B:
  CLI				;נןכב ץףפבמןקכב תבנעופ נעועשקבמיך
  MOV	 DL,-1
  CALL	 PORT_INC_2
  MOV	 AL,DH			;קתספר גבךפ ףוכץמה
  OUT	 CMOS_PORT+1,AL 	;תבחעץתיפר גבךפ ףיחמבלב - ףוכץמהש
  CALL	 PORT_INC_2
  MOV	 AL,CL			;קתספר נבעבםופעש םימץפ
  OUT	 CMOS_PORT+1,AL 	;תבחעץתיפר גבךפ ףיחמבלב - םימץפש
  CALL	 PORT_INC_2
  MOV	 AL,CH			;קתספר נבעבםופעש ‏בףןק
  OUT	 CMOS_PORT+1,AL 	;תבחעץתיפר גבךפ ףיחמבלב - ‏בףש
  IN	 AL,0A1H		;חבעבמפיעןקבממןו עבתעוûוממןו נעועשקבמיו
  AND	 AL,0FEH
  OUT	 0A1H,AL
  MOV	 DL,0AH
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;קתספר פוכץ‎וו תמב‏ומיו
  AND	 AL,07FH		;חבעבמפיעןקבממבס ץףפבמןקכב גיפב
  OR	 AL,20H 		;קכלא‏יפר קןתםןצמןףפר ףיחמבלב
  PUSH	 AX
  MOV	 DL,0AH
  CALL	 PORT_INC
  POP	 AX
  OUT	 CMOS_PORT+1,AL 	;ףיחמבל קןתםןצומ
  JMP	 T1
RTC_SET_ALARM  ENDP

RTC_RESET_ALARM  PROC  NEAR
RTC_7:
  CLI				;גלןכיעןקכב נעועשקבמיך נןכב ץףפבמןקכב
  MOV	 DL,0AH
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;קתספר גבךפ ףפבפץףב
  AND	 AL,57H 		;קשכלא‏יפר קןתםןצמןףפר ףיחמבלב
  PUSH	 AX			;תבנןםמיפר
  MOV	 DL,0AH
  CALL	 PORT_INC
  POP	 AX
  OUT	 CMOS_PORT+1,AL 	;קןףפבמןקיפר
  JMP	 T1
RTC_RESET_ALARM  ENDP

RTC_TIMEBIOS_SUBR  PROC  NEAR
PORT_INC:
  INC	 DL			;ץקולי‏יפר בהעוף
  MOV	 AL,DL
  OUT	 CMOS_PORT,AL
  RET
PORT_INC_2:
  ADD	 DL,2			;ץקולי‏יפר בהעוף
  MOV	 AL,DL
  OUT	 CMOS_PORT,AL
  RET
INITIALIZE_STATUS  PROC NEAR
  PUSH	 DX			;תבנןםמיפר
  MOV	 DL,09H
  CALL	 PORT_INC
  MOV	 AL,26H
  OUT	 CMOS_PORT+1,AL 	;ימידיבליתיעןקבפר עוחיףפע  'A'
  CALL	 PORT_INC
  MOV	 AL,82H 		;ץףפבמןקיפר גיפ 'SET BIT' הלס
				;ימידיבליתבדיי ‏בףןק י 24 ‏בףןקןחן עוציםב
  OUT	 CMOS_PORT+1,AL 	;ימידיבליתיעןקבפר עוחיףפע 'B'
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;‏פומיו עוחיףפעב 'C' הלס ימידיבליתבדיי
  CALL	 PORT_INC
  IN	 AL,CMOS_PORT+1 	;‏פומיו עוחיףפעב 'D' הלס ימידיבליתבדיי
  POP	 DX			;קןףפבמןקיפר
  RET
INITIALIZE_STATUS  ENDP

UPD_IN_PR:
  PUSH	 CX
  MOV	 CX,600 		;ץףפבמןקיפר ף‏ופ‏יכ דיכלןק
UPDATE:
  MOV	 AL,0AH 		;בהעוף עוחיףפעב 'A'
  OUT	 CMOS_PORT,AL
  JMP	 SHORT $+2		;I/O קעוםוממבס תבהועצכב
  IN	 AL,CMOS_PORT+1 	;‏פומיו ק עוחיףפע 'A'
  TEST	 AL,80H 		;וףלי 8XH-->UIP גיפ קכלא‏ומ
				;(מולרתס ‏יפבפר קעוםס)
  JZ	 UPD_IN_PREND
  LOOP	 UPDATE
  XOR	 AX,AX
  STC				;ץףפבמןקכב CARRY הלס ןûיגכי
UPD_IN_PREND:
  POP	 CX
  RET
RTC_TIMEBIOS_SUBR  ENDP
TIME_OF_DAY_1  ENDP


otsl_1  proc near
;ÏÔÓÌÅÖÉ×ÁÎÉÅ ÐÅÒÅÐÏÌÎÅÎÉÑ
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
;ÏÔÓÌÅÖÉ×ÁÎÉÅ
;BX-ÁÄÒÅÓ,CX-ÍÁËÓÉÍÁÌØÎÏÅ ÚÎÁÞÅÎÉÅ DX=CX-1, AX-ÍÉÎÉÍÁÌØÎÏÅ ÚÎÁÞÅÎÉÅ
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
;ÕÓÔÁÎÏ×ËÁ ÒÁÚÍÅÒÁ ÐÁÍÑÔÉ ÉÚ CMOS
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

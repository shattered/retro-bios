MONITOR      PROC    FAR 
        JMP    M0 
MONITOR      ENDP 
 
; 
;--------------------------------------------- 
;   מבףפעןךכב üכעבמב - 40*25 דקופמןך 
;--------------------------------------------- 
M0: 
        SUB     AX,AX 
	MOV	SS,AX 
	MOV	SP,03FFH 
 
        mov    ax,01 
        int    10h 
;--------------------------------------------- 
;        קÙ×ÏÄ ÐÏÌÎÏÇÏ ÍÅÎÀ 
;--------------------------------------------- 
MX0:    lea    si,s0 
	mov	cx,LS0 
        call   P_MSG 
mX1:    call   read_char   ;נעיום ןפקופב 
        cmp    AH,3BH      ;עבגןפב ף כבףףופןך? 
        JZ     READ_CAS    ;הב 
        cmp    AH,3CH      ;עבגןפב ף נתץ 
        JNZ    MX1         ;מופ 
 
        PUSH   DS 
        MOV    AX,KARTR    ;(DS) - ןגלבףפר כבעפעיהצב 
        MOV    BX,0 
        MOV    DS,AX 
;נעןקועכב כלא‏ב (נועקשך גבךפ = E9מ) 
        MOV    AL,BYTE PTR DS:[BX] 
        CMP    AL,0E9H 
        POP    DS 
        JNZ    MX0          ;כלא‏ב מופ 
 
	MOV	AX,2 
	INT	10H 
        JMP     KARTRIDJ 
 
;--------------------------------------------- 
;      תÁÇÒÕÚËÁ ÆÁÊÌÁ Ó ËÁÓÓÅÔÙ 
;--------------------------------------------- 
 
READ_CAS: 
        ASSUME DS:DATA 
        MOV    AX,DATA 
        MOV    DS,AX 
	mov    AX,LOAD_ADDR   ;ץףפבמןקכב ןגלבףפי תבחעץתכי 
        mov    es,ax 
        CALL   READ_NAME   ;נעיום יםומי זבךלב 
        LEA    si,SW5 
        MOV    cx,LSW5 
          CALL    P_MSG       ;נןהחןפןקיפר םבחמיפןזןמ 
RC4:      CALL    READ_CHAR   ;נעיום ןפקופב 
          CMP     AL,13       ;חןפןק? 
          JNZ     RC4         ;מופ 
          PUSH    ES 
          LEA     BX,BUFFERM 
          MOV     AH,4 
          INT     15H 
          JC      RCERROR 
          lea     si,sX12 
          MOV     cx,LSX12 
          call    P_MSG      ;ÚÁÐÕÓËÁÔØ? 
          call    read_char 
          call    wr_1_char 
          cmp     al,'N' 
          jz      RC5 
          cmp     al,'n' 
          jz      RC5 
          cmp     al,'מ' 
	  jz	  rc5 
	  cmp	  al,'Î' 
          jz      rc5 
          MOV     AX,0 
          PUSH    AX 
          DB      0CBH         ;(RETF) נועוהבפר ץנעבקלומיו תבחעץצוממןך נעןחעבםםו 
RC5:      JMP     M0           ;×ÏÚ×ÒÁÔ × ÍÏÎÉÔÏÒ 
rcerror: 
          lea     si,sX2 
          mov     cx,LSX2   ;--------------------- 
          call    P_MSG 
          call    read_char 
	  JMP	  MX0 
 
;        נ/נ קקןהב יםומי זבךלב 
;--------------------------------------------- 
READ_NAME: 
       LEA   si,SW2 
       MOV   cx,LSW2 
       CALL  P_MSG 
       MOV   SI,0 
RN1:   MOV   BUFFERM[SI],' ' 
       INC   SI 
       CMP   SI,8 
       JNZ   RN1 
       MOV   SI,0 
RN2:   CALL  READ_CHAR 
       CMP   AL,13 
       JZ    RN3 
       CMP   AL,1BH 
       JZ    READ_NAME 
       CMP   AL,20H 
       JB    RN2 
       CALL  WR_1_CHAR 
       MOV   BUFFERM[SI],AL 
       INC   SI 
       CMP   SI,8 
       JNZ   RN2 
RN3:   RET 
 
wr_1_char    proc 
        push   cx 
        PUSH   BX 
        PUSH   DX 
        MOV    AH,14 
        INT    10H 
        POP    DX 
        POP    BX 
        pop    cx 
        ret 
wr_1_char    endp 
 
;‏ÔÅÎÉÅ ××ÅÄÅÎÎÏÇÏ ÓÉÍ×ÏÌÁ 
 
read_char    proc   near 
        mov    ah,0 
        int    16h 
r_ret:  ret 
read_char    endp 
;ףÏÏÂÝÅÎÉÑ ÍÏÎÉÔÏÒÁ 
s0:     db    13,10,0F6H,' "נןיףכ" ',0F7H,13,10 
        db    13,10 
s01:    db    'F1 - עÁÂÏÔÁ Ó ËÁÓÓÅÔÏÊ',13,10,13,10 
s03:    db    'F2 - עÁÂÏÔÁ Ó נתץ',13,10,13,10 
S05:    DB    'קÙÂÅÒÉÔÅ עוצים' 
LS05	= $ - OFFSET S05 
LS0     = $ - OFFSET S0 
sX12:   db    13,10,'תÁÐÕÓËÁÔØ?' 
LSX12	= $ - OFFSET SX12 
sX2:    db    13,10,'ןÛÉÂËÁ ÞÔÅÎÉÑ ***',13,10 
LSX2	= $ - OFFSET SX2 
SW2:    DB    13,10,'ק×ÅÄÉÔÅ ÉÍÑ ÆÁÊÌÁ:' 
LSW2	= $ - OFFSET SW2 
SW5:    DB    13,10,'קËÌ.  ÍÁÇÎÉÔÏÆÏÎ, ÎÁÖÍÉÔÅ (BK)' 
LSW5	= $ - OFFSET SW5 
fn:     db    13,10,'זÁÊÌ ÎÁÊÄÅÎ!',13,10 
LFN	= $ - OFFSET FN 

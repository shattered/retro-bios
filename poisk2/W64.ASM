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
; ιξτεςζεκσ φεστλοηο δισλα					;
;								;
;	ότα πςογεδυςα ποδδεςφιχαετ λοξτςομμες φ.δισλα       	;
;	χωπομξεξξωκ ξα  Intel'82064 δμρ	πλ ποισλ          	;
;								;
;---------------------------------------------------------------
;
;---------------------------------------------------------------
;	πςεδυπςεφδεξιε: δμρ υχεςεξξοκ ςαβοτω σ φ.δισλον         ;
;	πομψϊυκτεσψ ζυξλγιρνι οπςεδεμεξξωνι χ πςεςωχαξιι  	;
;---------------------------------------------------------------
;
; χθοδ 	(AH = HEX ϊξαώεξιε)
;
;	AH = 00	σβςοσ δισλα (DL = 80H/81H)/δισλετ
;	AH = 01 ώτεξιε στατυσα ποσμεδξεκ δισλοχοκ οπεςαγιι χ AL
;	    ϊανετιν	DL < 80H - δισλετω
;			DL > 80H - δισλ
;	AH = 02 ώτεξιε χωβςαξξοηο σελτοςα χ πανρτψ
;	AH = 03 ϊαπισψ χωβςαξξοηο σελτοςα χ πανρτψ
;	AH = 04 χωςιζιλαγιρ χωβςαξξοηο σελτοςα
;	AH = 05 ζοςνατιςοχαξιε χωβςαξξοηο τςελα
;	AH = 06 ζοςνατιςοχαξιε χωβςαξξοηο τςελα σ υσταξοχλοκ ζμαηα
;		πμοθιθ σελτοςοχ
;	AH = 07 ζοςνατιςοχαξιε δισλα ξαώιξαρ σ χωβςαξξοηο τςελα
;	AH = 08 χΟΪΧÒΑέΑΕΤ ΤΕΛΥέΙΕ ΠΑÒΑΝΕΤÒΩ ΔΙΣΛΑ
;
;	AH = 09 Initialize drive pair characteristics
;			interrupt 41 points to data block
;	AH = 0A δμιξξοε ώτεξιε
;       AH = 0B δμιξξαρ ϊαπισψ
;	   ϊανετιν	Read and Write LONG encompass 512+4 bytes ECC
;	AH = 0C ποισλ τςελα
;	AH = 0D αμψτεςξατιχξωκ σβςοσ (σνοτςι DL)
;	AH = 0E Read Sector Buffer
;	AH = 0F Write Sector Buffer
;	AH = 10 τεστ ώιταενοστι δισλα
;	AH = 11 ςελαμιβςαγιρ
;	AH = 12 διαηξοστιλα RAM λοξτςομμεςα
;	AH = 13 διαηξοστιλα δισλα
;	AH = 14 χξυτςεξξρρ διαηξοστιλα λοξτςομμεςα
;	AH = 15 ώτεξιε τιπα ξοσιτεμρ
;	AH = 16-18 ϊαςεϊεςχιςαχοξο δμρ δισλοχοδοχ
;	AH = 19 παςλοχλα ηομοχολ
;
;	ςεηιστςω ισπομψϊυενωε δμρ ζυξλγικ:
;
;		DL - ξονες δισλα     (80H-87H δμρ δισλα. ϊξαώεξιε πςοχεςρετσρ)
;		DH - ξονες ηομοχλι   (0-7 ϊξαώεξιε ξε πςοχεςρετσρ)
;		CH - ξονες γιμιξδςα  (0-1023. ϊξαώεξιε ξε πςοχεςρετσρ,σνοτςι CL)
;		CL - ξονες σελτοςα   (1-17. ϊξαώεξιε ξε πςοχεςρετσρ)
;		    ϊανετιν 	σταςϋιε 2 βακτα ξονεςα γιμιξδςα ςασπομοφεξω
;				χ 2 σταςϋιθ βακταθ ςεηιστςα CL
;				(χσεηο 10 βιτ)
;		AL - ώισμο σελτοςοχ (ναλσιναμψξοε 1-80H,
;				     δμρ δμιξξωκ ώτεξ/ϊαπισι  1-79H)
;			(ώεςεδοχαξιε σελτοςοχ δμρ ζοςνατιςοχαξιρ 1-16D)
;	     ES:BX - αδςεσ βυζεςα δμρ ώτεξιρ ι ϊαπισι
;
; χωθοδ
;	AH = στατυσ τελυύεκ οπεςαγιι
;		οπισαξιε βιτ στατυσα πςεχεδεξξο ξιφε
;	CY = 0  υσπεϋξαρ οπεςαγιρ (AH=0 πςι χοϊχςατε)
;	CY = 1  ξε υσπεϋξαρ οπεςαγιρ (AH σοδεςφιτ οϋιβλυ)
;
;     ϊανετιν	οϋιβλα 11H  πολαϊωχαετ, ώτο πςι ώτεξιι βωμα ισπςαχμεξα οϋιβ-
;		λα πο ECC αμηοςιτνυ.  πςοώιταξξωε δαξξωε χοϊνοφξο θοςοϋιε.
;		οδξαλο BIOS πολαϊωχαετ οϋιβλυ, ποότονυ χωϊωχαΰύαρ πςοηςαννα
;		δομφξα σανα χωβιςατψ αμηοςιτν οβςαβοτλι ότιθ δαξξωθ
;
;	οτχετ ξα ϊαπςοσ παςανετςοχ δισλα:
;
;	DL = ώισμο ποδλμΰώεξξωθ δισλοχ (0-2)
;		(ποδσώετ ώισμα λοξτςομμεςοχ)
;	DH = ναλσιναμψξαρ ηομοχλα
;	CH = ναλσιναμψξοε ώισμο γιμιξδςοχ
;	CL = ναλσιναμψξοε ώισμο σελτοςοχ ι 2 σταςϋιε βιτα ότο σταςϋιε
;		βιτω ώισμα γιμιξδςοχ
;
;	χσε ςεηιστςω, ϊα ισλμΰώεξιεν χοϊχςαύαΰύιθ ιξζοςναγιΰ ξε ιϊνεξρΰτσρ
;
;  ϊανετιν 	οβωώξωκ αμηοςιτν οβςαβοτλι οϋιβλι ότο σβςοσ σιστενω ι
;		ποχτοςεξιε οπεςαγιι.
;
;----------------------------------------------------------------------------
;-----------------------------------------------
;	τοώλα χθοδα                		;
;-----------------------------------------------

DISK_IO		Proc FAR
	Assume	CS:CODE, DS:DATA

	CMP	DL,80H			; τεστ φ.δισλ ιμι ηιβλικ
	JAE	HARD_DISK		; δα,φ.δισλ
	INT	40H			; οβσμυφιχαξιε δισλετ
	JMP	short RET_2		; χοϊχςατ χ χωϊωχαΰύυΰ
HARD_DISK:
	STI				; ςαϊςεϋεξιε πςεςωχαξικ
	OR	AH,AH			; λοναξδα σβςοσα ?
	JNZ	A0			; ξετ, πςοδομφεξιε
	INT	40H			; σβςοσ NEC
	XOR	AH,AH			; οβξυμεξιε
A0:
	PUSH	SI
	PUSH	DS
	PUSH	ES
        CALL	DDS    		        ; υσταξοχλα σεηνεξτα δαξξωθ BIOS
	CMP	AH,8			; λοναξδα ώτεξιρ παςανετςοχ ?
	JNE	HHA1			; ξετ
	JMP	short READ_PARMS
HHA1:
	CMP	AH,15H			; ώτεξιε DASD τιπα ?
	JNE	HHA2			; ξετ
	JMP	short RD_DASD_TYPE
HHA2:
	PUSH	BP			; ϊαπισψ υλαετεμρ
	PUSH	DI
	PUSH	DX
	PUSH	BX			; ϊαπισψ ςεηιστςοχ οπεςαγιι
	PUSH	CX
	PUSH	DS
	PUSH	AX
	AND	DL,7FH			; σβςοσ σταςϋιθ βιτ
	CMP	DL,[HF_NUM]		; πςαχιμψξωκ ξονες ?
	JAE	RET_BAD_CMD		; ξετ, ξεπςαχιμψξωκ
	CMP	AH,(H1L SHR 1)		; πμοθαρ λοναξδα ?
	JB	DIO_0			; ξετ, πςοδομφεξιε
RET_BAD_CMD:
	MOV	AH,18H			; δα, υσταξαχμιχαεν BAD_COMMAND.
DIO_0:
	MOV	AL,AH			; πομυώεξιε νμαδϋεηο βακτα
	XOR	AH,AH			; οβξυμεξιε σταςϋεηο βακτα
	SHL	AX,1			; *2 δμρ πςοσνοτςα ταβμιγω
	MOV	SI,AX			; ϊαηςυφαενχ SI δμρ πεςεθοδα πο CALL
	POP	AX			; χοσσταξοχμεξιε AX
	XOR	AH,AH
	MOV	DI,AX			; DI = σώετώιλ βμολοχ
	XCHG	AH,[HDISK_STATUS]	; σβςοσ στατυσα

	CALL	Word ptr CS:H_COM[SI]	; χωϊοχ ξεοβθοδινοκ οπεςαγιι

	PUSH	AX
	MOV	DX,HD_PORT		; αδςεσ ποςτα
	MOV	AL,(HD_RES_BIT or BF_RES_BIT or IR_DMA_EN)
	OUT	DX,AL			; ποσωμλα DX = HD_PORT
	POP	AX
	POP	DS			; χοσσταξοχμεξιε ςεηιστςα δαξξωθ
	MOV	[HDISK_STATUS],AH	; πομυώεξιε στατυσα οπεςαγιι
	POP	CX
	POP	BX
	POP	DX
	POP	DI
	POP	BP
	CMP	AH,1			; υσταξοχλα ζμαηα δμρ ιξδιλαγιι
	CMC				; υσπεθα ιμι ξευσπεθα οπεςαγιι
RET_8:
	POP     ES
	POP	DS
	POP	SI
RET_2:
	RET	2
DISK_IO		EndP

;-------------------------------------------------------
; πομυώεξιε στατυσα (AH=1)				;
;-------------------------------------------------------
HREAD_STATUS	Proc	near
	MOV	AL,AH			; AH σοδεςφιτ DISK STATUS
	XOR	AH,AH			; σβςοσ στατυσα
	RET
HREAD_STATUS	EndP
;-------------------------------------------------------
; πομυώεξιε παςανετςοχ δισλα (AH=8)			;
;-------------------------------------------------------
READ_PARMS	Proc	near
	Assume	DS:DATA

	PUSH    DS			; ϊαπισψ ςεηιστςα BIOS
	CALL	TST_DRV_NUM
	JB	RP0			; δα.
	XOR	DX,DX			; ξεπςαχιμψξωκ ξονες δισλα
	MOV	AX,700H			; INIT_FAIL οϋιβλα
	STC				; χωθοδ πο οϋιβλε
RP_RET:
	POP	DS
	MOV	[HDISK_STATUS],AH
	JMP	short   RET_8		; χωθοδ
RP0:
	LODSW				; πομυώεξιε ώισμα γιμιξδςοχ
	DEC	AX			; ξαώιξαετσρ ξυνεςαγιρ σ 0
	XCHG	AL,AH
	ROR	AL,1
	ROR	AL,1			; πομυώεξιε σταςϋιθ βιτ ώισμα γιμιξδςοχ
	OR	AL,0CH[SI]		; σνεϋιχαξιε
	XCHG	CX,AX			; AX=0
	MOV	DL,DH			; υσταξοχλα ώισμα δισλοχ
	MOV	DH,[SI]			; SI υλαϊατεμψ ξα ώισμο ηομοχολ
	DEC	DH			; ξαώιξαετσρ σ 0
	JMP	short RP_RET		; Carry = 0
READ_PARMS	EndP
;-------------------------------------------------------
; ώτεξιε τιπα DASD  (AH=15)				;
;-------------------------------------------------------
RD_DASD_TYPE	proc	near
	CALL	TST_DRV_NUM
	MOV	AX,CX			; AX=0
	MOV	DX,CX			; DX=0
	JNB	RD_RET			; ξεπςαχιμψξωκ ξονες δισλα, χωθοδ
	MOV	AL,2[SI]		; πομυώεξιε ώισμα ηομοχολ
	IMUL	byte ptr 0EH[SI]	; υνξοφεξιε ώισμα σελτοςοχ ξα
	IMUL	word ptr [SI]		; ώισμο τςελοχ
	MOV	CX,DX
	MOV	DX,AX
	MOV	AX,300H			; τιπ δισλα - ζιλσιςοχαξξωκ
RD_RET:
	JMP	short   RET_8		; χωθοδ (CY=0)
RD_DASD_TYPE	EndP
;
;------
	Assume	DS:DATA

TST_DRV_NUM:
	AND	DL,7FH			; σβςοσ σταςϋιθ βιτ
	XOR	CX,CX			; CX=0
	MOV	DH,[HF_NUM]		; ϊαπισψ ξονεςα δισλα χ DH
	CALL	SET_PARAM_PTR
	CMP	DL,DH			; πςαχιμψξωκ ξονες ?
	RET				; χοϊχςατ στατυσα
;-------------------------------------------------------
; BAD_COMMAND						;
;	ότα πςογεδυςα χοϊχςαύαετ οϋιβλυ           	;
; χοϊχςαύαετ   						;
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
; σβςοσ φ.δισλα (AH=0)					;
;-------------------------------------------------------
HDISK_RESET	proc	near
HDISK_RECAL:
	CALL	DRIVE_SELECT
	PUSH	AX
	AND	AL,not (HD_RES_BIT or BF_RES_BIT)
        CLI
	OUT	DX,AL			; σβςοσ λοξτςομμεςα
	POP	AX
	OUT	DX,AL			; χλμΰώαετ λοξτςομμες ι χωδεμρετ δισλ
	DEC	DX			; 327, ςεηιστς λοναξδ
	MOV	AL,RESTORE_CMD
	OUT	DX,AL			; σταςτ χοσσταξοχμεξιρ
	MOV	AX,TIME_OUT*256+10H	; ιξιγιαμιϊαγιρ TIME_OUT
	CALL	WAIT_START
	JC      RESET_DONE		; AH=οϋιβλα TIMEOUT
	IN	AL,DX			; πομυώεξιε στατυσα
	XOR	AH,AH			; στατυσ O.K.
	SHR	AL,1			; οϋιβλα ?
	JNC	RESET_DONE		; ξετ, χωθοδ
	MOV	AH,BAD_RESET		; δα,υσταξοχλα στατυσα BAD_RESET
RESET_DONE:
	RET
HDISK_RESET	EndP
;
;------ ότα πςογεδυςα χλμΰώαετ χωβςαξξωκ δισλ
;
DRIVE_SELECT:
	MOV	AL,DSEL_0_BIT		; DSEL_0 βιτ
	MOV	CL,DL
	SHL	AL,CL			; σδχιη δισλοχοδα
	OR	AL,(HD_RES_BIT or BF_RES_BIT or IR_DMA_EN)
	MOV	DX,HD_PORT
	OUT	DX,AL
	RET
;-------------------------------------------------------
; τεστ ώιταενοστι δισλα (AH=10)				;
;-------------------------------------------------------
TST_RDY		proc	near
	CALL    DRIVE_SELECT
	DEC	DX			; WDC ςεηιστς στατυσα
	XOR	AH,AH
	IN	AL,DX			; πομυώεξιε στατυσα
	TEST	AL,40H			; δισλ ώιταεν ?
	JNZ	TST_RDY_RET		; δα.
	MOV	AH,DRIVE_NOT_RDY	; ξετ,υσταξοχλα οϋιβλι
TST_RDY_RET:
	RET
TST_RDY		EndP
;-------------------------------------------------------
; ιξιγιαμιϊαγιρ ταβμιγω δισλα  (AH=9)			;
;-------------------------------------------------------
INIT_DRV	proc	near
RAM_DIAG:
CHK_DRV:
	XOR	AH,AH			; O.K. στατυσ
	RET
INIT_DRV	EndP
;-------------------------------------------------------
;HDISK_READ	(AH=2)					;
;	ότα πςογεδυςα χωπομξρετ ώτεξιε σ δισλα χ
;	πανρτψ δο 80H σελτοςοχ				;
;-------------------------------------------------------
HDISK_READ	proc	near
	MOV	AX,256*READ_CMD+DMA_WRITE_CMD+3	; λαξαμ φ.δισλα
	JMP	short RWVF_OPN
HDISK_READ	EndP
;-------------------------------------------------------
; HDISK_WRITE	(AH=3)					;
;-------------------------------------------------------
HDISK_WRITE	proc	near
	MOV	AX,256*WRITE_CMD+DMA_READ_CMD+3	; λαξαμ φ.δισλα
	JMP	short RWVF_OPN
HDISK_WRITE	EndP
;-------------------------------------------------------
; HDISK_VERF	(AH=4)					;
;-------------------------------------------------------
HDISK_VERF	proc	near
	MOV	AX,256*READ_CMD+DMA_READ_CMD+3	; λαξαμ φ.δισλα
	JMP	short RWVF_OPN
HDISK_VERF	EndP
;-------------------------------------------------------
; FMT_TRK	(AH=5)					;
;-------------------------------------------------------
FMT_TRK		proc	near
	MOV	AX,256*WR_FORMAT_CMD+DMA_READ_CMD+3	; λαξαμ φ.δισλα
	MOV	DI,1
	JMP	short RWVF_FMT_POINT
FMT_TRK		EndP
;-------------------------------------------------------
; RD_LONG	(AH=0A)					;
;-------------------------------------------------------
RD_LONG		proc	near
	MOV	AX,256*RD_LONG_CMD+DMA_WRITE_CMD+3	; λαξαμ φ.δισλα
	JMP	short RWVF_OPN
RD_LONG		EndP
;-------------------------------------------------------
; WR_LONG	(AH=0B)					;
;-------------------------------------------------------
WR_LONG		proc	near
	MOV	AX,256*WR_LONG_CMD+DMA_READ_CMD+3	; λαξαμ φ.δισλα
WR_LONG		EndP
;-------------------------------------------------------
; RWVF_OPN						;
;	ότα πςογεδυςα χωπομξρετ ώτεξ/ϊαπισψ/χεςιζιλ.
;	χωβςαξξοηο λ-χα σελτοςοχ χ δμιξξοκ ι ξοςναμψξοκ
;	νοδεμι
; INPUT							;
;	AH = βακτ λοναξδω δμρ Intel' 82064		;
;	CL = ξονες σελτοςα + σταςϋιε βιτω τςελα		;
;	CH = βιτω τςελα        				;
;	DL = ξονες δισλα (0..1)				;
;	DH = ηομοχλα					;
;	DI = σώετώιλ βμολα(0..80)			;
; χωθοδ 						;
;-------------------------------------------------------
RWVF_OPN         proc	near
	DEC	CX			; ξονεςα σελτοςοχ ξαώιξαΰτσρ σ 0
RWVF_FMT_POINT:
	CALL	HDMA_SETUP		; υσταξοχλα παςανετςοχ πεςεδαώι
	JNC	RWVF_CONTINUE
	MOV	AX,DMA_BOUNDARY*256	; πεςεδαώα 0 βμολα
	RET				; DMA οϋιβλα
RWVF_CONTINUE:
	PUSH	DI			; ϊαπισψ σώετώιλα βμολα
	CALL	SET_PARAM_PTR		; DS:SI υλαϊατεμψ ξα ταβμιγυ παςανετςοχ
	XCHG	CL,CH
	MOV	BX,CX
	MOV	CL,6
	SHR	BH,CL			; υσταξοχλα σταςϋιθ 2 βιτ
	XCHG	BX,DI			; DI = ξονες γιμιξδςα
					; BL = σώετώιλ βμολα
	AND	CH,3FH			; CH = ξονες σελτοςα
	MOV	BH,DSEL_0_BIT		; DSEL_0 βιτ
	MOV	CL,DL
	SHL	BH,CL			; σδχιη δισλα
	OR	BH,(HD_RES_BIT or BF_RES_BIT or IR_DMA_EN)
;
;------ δμιξξωκ τεστ,χοϊνοφεξ τομψλο δμρ 82064
;
	TEST	AH,LONG_FLAG		; δμιξξοε ?
	JZ	SHORT_RWVF		; ξετ, ξοςναμψξοε
	OR	BH,LONG_MODE_BIT	; !!!
SHORT_RWVF:
					; BH = HD_PORT βακτ
	MOV	CL,3
	SHL	DL,CL
	OR	DL,20H			; DL = SDH ςεηιστς
					; (512 βακτ/σελ, CRC νοδεμψ- δμρ 062)
					; CRC - OR   DL,20H
					; υσταξαχμιχαεν ECC νοδεμψ
					; ECC - OR   DL,0A0H 
					; DH = ηομοχλα
					; AH = λοναξδξωκ βακτ
;
;------ ημαχξωκ σώετώιλ
;
RWVF_LOOP:
	MOV	CL,0EH[SI]		; πομυώ.ώισμα σελτος/τςελ  (1..x)
	CMP	AH,WR_FORMAT_CMD	; τελυύικ CMD ότο FORMAT ?
	JNE	RWVF_A0			; ξετ
	MOV	CH,GAP_1		; δα,υσταξοχλα GAP δμιξξω
	JMP	short RWVF_S
RWVF_A0:
	SUB	CL,CH			; ναλσιναμψξωκ σελτος χτελυύεν τςελε
					; (1..x)
	CMP	CL,BL			; ποσμεδξικ τςελ δμρ πςογεσσα ?
	JB	RWVF_S			; ξετ
	MOV	CL,BL			; δα, υσταξοχλα χςενεξι χωπομξεξιρ
RWVF_S:
;
;------ ποσωμλα παςανετςοχ χ λοξτςομμες
;
	PUSH	DX			; σοθςαξεξιε DX
	MOV	AL,DL			; SDH
	OR	AL,DH			; πςιβαχμεξιε βιτ ηομοχλι
	PUSH	AX			; ποσωμλα λοναξδω ι SDH         (7,6)
;------ χωδεμεξιε δισλα
	MOV	AL,BH			; SDH δοβαχοώξωκ
	OR	AL,DH			; πςιβαχμεξιε βιτ ηομοχλι
	MOV	DX,HD_PORT
	OUT	DX,AL			; ποχοςοτ χωδεμεξξοηο δισλα
;------ ϊαηςυϊλα ζακμα ϊαδαώι  χ ςεηιστς λοναξδ
	CLI				; ϊαπςετ πςεςωχαξικ ξα χςενρ ϊαηςυϊλι
	MOV	DL,(WDC_PORT+1) and 0FFH; ποςτ ϊαπισι
	MOV	AX,5[SI]		; πομυώεξιε ιϊ ταβμιγω
	SHR	AX,1
	SHR	AX,1			; δεμιν ξα 4
	OUT	DX,AL			; ποσωμαεν Precomp γεμιξδς 		(1)
	PUSH	DI			; ποσωμαεν γιμιξδς (5,4)
	PUSH	CX			; ποσωμαεν ξονες σελτοςα ι σώετώιλ (3,2)
OUT_LOOP:
	POP	AX
	INC	DX
	OUT	DX,AL			; ποσωμλα ώετξωηο βακτα
	MOV	AL,AH
	INC	DX
	OUT	DX,AL			; ποσωμλα ξεώετξοηο βακτα
	CMP	DL,(WDC_PORT+7) AND 0FFH ; ποσμεδξικ OUT ?
	JNE	OUT_LOOP		; ξετ
;------ ςαϊςεϋεξιε DMA
	MOV	AL,3
	OUT	DMA_MASK,AL		; ςαϊςεϋεξιε λαξαμα δισλα DMA
	CALL	HWAIT_INT
	IN	AL,DX			; ςεηιστς στατυσα
	POP	DX			; χοσσταξ DX
	MOV	CH,TIME_OUT		; χςενρ χωϋμο ?
	JC	RWVF_EXIT		; δα, χςενρ χωϋμο
	AND	AL,01100101B		; σβςοσ βιτ BUSY,SC,RDQ,CIP
	XOR	AL,01000000B		; ιξχεςσιρ βιτ σβςοσα
	JNE	RWVF_ERROR		; WDC οϋιβλα
;------ χωώισμεξιε ξοχωθ παςανετςοχ
	XOR	CH,CH			; πεςχωκ σελτος ξα τςελε
	INC	DH			; χωδεμεξιε σμεδυΰύεκ ηομοχλι
	CMP	DH,2[SI]		; ναλσιναμψξαρ ηομοχλα ?
	JB      RWVF_A1			; ξετ
	XOR	DH,DH			; χωδεμεξιε 0 ηομοχλι
	INC	DI			; σμεδυΰύικ γιμιξδς
RWVF_A1:
	SUB	BL,CL			; υνεξψϋεξιε σώετώιλα
	JA	RWVF_LOOP		; οβςαβοτλα σμεδυΰύεηο τςελα
RWVF_EXIT:
	POP	AX			; χοσσταξοχμεξιε σώετώιλα βμολα
	SUB	AL,BL			; σελτοςα οβςαβοταξω O.K.
	MOV	AH,CH			; AH = λοδ οϋιβλι (0 εσμι O.K.)
	RET
RWVF_ERROR:

	PUSH	BX
	XOR	BX,BX
	SHR	AL,1			; σβςοσ ζμαηα οϋιβλι
	MOV	AH,AL
	MOV	DX,(WDC_PORT+1)		; ςεηιστς οϋιβολ
	IN	AL,DX			; πομυώεξιε οϋιβλι
ERR_SCAN:
	INC	BX
	SHL	AX,1			; βιτ οϋιβλι?
	JC	ERROR_FOUND
	JNZ	ERR_SCAN
ERROR_FOUND:
	MOV	CH,CS:(WDC_ERR_TBL-3)[BX] ; υσταξοχλα λοδα οϋιβλι
	POP	BX

	INC	DX			; 321+1
	IN	AL,DX			; πομυώεξιε σώετώιλα σελτοςοχ WDC
	SUB	CL,AL			; ώισμο υσπεϋξο οβςαβοταξξωθ σελτοςοχ
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
;	ότα πςογεδυςα υσταξαχμιχαετ υλαϊατεμψ ξα ταβμιγυ   ;
;	παςανετςοχ τελυύεηο δισλα                	   ;
;  χθοδ						           ;
;	DL = ξονες δισλα (0 ιμι 1,ϊξαώεξιε ξε πςοχεςρετσρ) ;
; OUTPUT					           ;
;    DS:SI = Pointer to parameter tbl			   ;
;-------------------------------------------------------
SET_PARAM_PTR	proc	near
	PUSH	AX
	XOR	AX,AX			; υσταξοχλα σεηνεξτα ABS0
	MOV	DS,AX

	Assume	DS:ABS0
	MOV	SI,offset HF_TBL_VEC
	OR	DL,DL			; δισλοχοδ 0 ?
	JZ	SPP_0			; δα.
	ADD	SI,(HF2_TBL_VEC - HF_TBL_VEC)
SPP_0:
	LDS	SI,[SI]
	POP	AX
	RET
SET_PARAM_PTR	EndP

;-------------------------------------------------------
; HWAIT_INT						;
;	ότα πςογεδυςα οφιδαετ χωπομξεξιρ οπεςαγιι       ;
;	ι σιηξαμιϊιςυετ, εσμι πςοιϊοϋμο πςεςωχαξιε      ;
;  χθοδ							;
;	AH = βακτ λοναξδω δμρ Intel' 82064		;
;    DS:SI = υλαϊατεμψ ξα ταβμιγυ παςανετςοχ
;  χωθοδ						;
;	CARRY = 0 - ξοςναμψξο χωπομξεξα
;	      = 1 - χςενρ χωϋμο		;
;-------------------------------------------------------
HWAIT_INT	proc	near
	MOV	AL,9[SI]		; σταξδαςτξοε TIMEOUT
	CMP	AH,I64_FMT_CMD
	JNE	WAIT_START
	MOV	AL,0AH[SI]		; Time Out πςι ζοςνατιςοχαξιι
WAIT_START:
;
;------ χ ότοκ πςεςωχαξιρ ϊαπςεύεξω !
;
	PUSH	DS
	CALL	DDS		        ; υσταξοχλα σεηνεξτα BIOS

	Assume	DS:DATA

	PUSH	AX
;
;------ ςαϊςεϋεξιε πςεςωχαξικ λοξτςομμεςα
;
	IN	AL,INT_CTL_PORT+1	; πομυώεξιε νασλι πςεςωχαξικ
	AND	AL,not FD_INT_MASK
	OUT	INT_CTL_PORT+1,AL	; ςαϊςεϋεξιε πςεςωχαξικ δισλα
;
	MOV	AX,9000H		; πςιβος ϊαξρτ
	MOV	[HF_EOI],AL		; σβςοσ EndOfInt ζμαηα
	STI				; ςαϊςεϋεξιε πςεςωχαξικ
	INT	15H			; οϋιβλα ξε οβξαςυφεξα
	POP	AX			; χοσσταξοχμεξιε βακτα CMD
	PUSH	CX
WAIT_LOOP:
	TEST	HF_EOI,80H		; οφιδαετσρ πςεςωχαξιε ?
	JNZ	WAIT_DONE		; δα. OK.
	LOOP	WAIT_LOOP		; χξυτςεξξικ γιλμ
	DEC	AL
	JNZ	WAIT_LOOP		; χξεϋξικ γιλμ
	CALL	IR_DMA_DISABLE
	STC				; υσταξοχλα ζμαηα - TIMEOUT
WAIT_DONE:
	POP	CX
	POP	DS
	RET
HWAIT_INT	EndP
;
;------ τοώλα χθοδα χ πςεςωχαξιε φ.δισλα
;
HD_INT	proc	FAR
	PUSH	AX			; σοθςαξεξιε ςεηιστςοχ
	PUSH	DS
	MOV	AL,EOI			; λοξεγ πςεςωχαξιρ
	OUT	INT_CTL_PORT,AL
	CALL	DDS          		; υσταξοχλα σεηνεξτα BIOS
	CALL	IR_DMA_DISABLE
	POP	DS
	POP	AX
	IRET
HD_INT	EndP
;
;------ ϊαπςετ πςεςωχαξικ ι λοξτςομμεςα DMA
;
IR_DMA_DISABLE:
	PUSH	AX
	IN	AL,INT_CTL_PORT+1	; πομυώεξιε νασλι πςεςωχαξικ
	OR	AL,FD_INT_MASK
	OUT	INT_CTL_PORT+1,AL	; ϊαπςετ πςεςωχαξικ δισλα
	MOV	AL,7
	OUT	DMA_MASK,AL		; υσταξοχλα DMA δμρ ϊαπςετα
	MOV	HF_EOI,80H		; υσταξοχλα ζμαηα πςεςωχαξικ δισλα
	STI				; ςαϊςεϋεξιε πςεςωχαξικ
	MOV	AX,9100H		; πςεςωχαξιρ υσταξοχμεξω
	INT	15H
	POP	AX
	RET				; ξετ οϋιβλι

;-------------------------------------------------------
; HDMA_SETUP						;
;	ότα πςογεδυςα πςοηςανιςυετ DMA          	;
;  χθοδ							;
;	   DI = σώετώιλ βμολα (0..80h, ϊξαώ πςοχες.)	;
;	   AL = βακτ δμρ DMA				;
;	   AH = LONG ζμαη (cmd δμρ WDC)			;
;	ES:BX = αδςεσ ώιταενωθ/ϊαπισωχ δαξξωθ 		;
;  χωθοδ						;
;	   BX : ςαϊςυϋεξ 				;
;	   CARRY = 0 - ξοςναμψξοε ολοξώαξιε
;		 = 1 - οϋιβλα ηςαξιγω    		;
;-------------------------------------------------------
HDMA_SETUP	proc	near
	PUSH	DX
	PUSH	AX
	PUSH	CX
;
;------ υσταξοχλα ςεφινα DMA
;
	OUT	DMA_F_F,AL		; σβςοσ στελα f/f
	MOV	CH,AH			; ϊαπισψ LONG ζμαηα ι παυϊαe
	OUT	DMA_MODE,AL		; χωχοδ βακτα ςεφινα
;
;------ χωώισμεξιε DMA ι ξονεςα ςεηιστςα στςαξιγ
;
	AND	AX,3			; ξονες λαξαμα
	MOV	DX,AX
	SHL	DX,1			; DMA βαϊοχωκ ςεηιστς (4 ιμι 6)
	PUSH	DX			; ϊαπισψ εηο
	ADD	AL,7FH			; ςεηιστς στςαξιγ (81 ιμι 82)
	PUSH	AX			; ϊαπισψ εηο
;
;------ οπςεδεμεξιε βαϊοχοηο αδςεσα ι ϊξαώεξιε στςαξιγω
;
	MOV	AX,ES			; πομυώεξιε ES ϊξαώεξιρ
	MOV	CL,4			; σδχιη σώετώιλα
	ROL	AX,CL			; χςαύεξιε χμεχο
	PUSH	AX			; ϊαπισψ σταςϋιθ 4 βιτ
	AND	AL,0F0H			; οβξυμεξιε νμαδϋεηο ξιβμα
	ADD	AX,BX			; πςιβαχμεξιε σνεύεξιρ
	OUT	DX,AL			; χωχοδ νμαδϋεηο αδςεσα
	PUSH	AX			; ϊαπισψ σταςτοχοηο αδςεσα χ BX
	POP	BX
	MOV	AL,AH
	OUT	DX,AL			; χωχοδ σταςϋεηο αδςεσα
	POP	AX			; χοσσταξοχμεξιε σταςϋιθ 4 βιτ
	ADC	AL,0			; πςι πεςεξοσε ξαδο INC
	AND	AL,0FH			; σβςοσ σταςϋεηο ξιβμα (δμρ PC AT)
	POP	DX			; χοσσταξοχμεξιε ςεηιστςα στςαξιγ
	OUT     DX,AL			; χωχοδ σταςϋιθ 4 βιτ ςεηιστςα στςαξιγ
;
;------ οπςεδεμεξιε σώετώιλα
;
	MOV	AX,512D			; ςαϊνες σελτοςα
	TEST	CH,LONG_FLAG		; δμιξξωκ ?
	JZ	SHORT_DMA		; ξετ ξοςναμψξωκ
	MOV	AL,4			; 512 + 4 βακτ ECC
SHORT_DMA:
	MUL	DI			; σώετώιλ πεςεδαώι βμολα
	POP	DX			; χοσσταξοχμεξιε DMA βαϊοχοηο ςεηιστςα
	INC	DX			; DX = DMA CNT ςεηιστς
	JNC	ADJUST_DMA		; OK, σώετώιλ πςαχιμψξωκ
	NEG	AX			; AX = 0 ?    ( = 64K )
	JC	BOUNDARY_OUT		; ξετ, οϋιβλα ( > 64K )
ADJUST_DMA:
	DEC	AX			; ςεηυμιςοχλα
	ADD	BX,AX			; τεστ δμρ 64K πεςεπομξξιρ
	OUT     DX,AL			; νμαδϋικ βακτ σώετώιλα
	MOV	AL,AH
	OUT     DX,AL			; σταςϋικ βακτ σώετώιλα
BOUNDARY_OUT:
	POP	CX			; χοσσταξοχμεξιε ςεηιστςοχ
	POP	AX
	POP	DX
	RET				; CARRY = 1 εσμι χωθοδ ϊα ηςαξιγω
HDMA_SETUP	EndP
;----------------------------------------------------------------
H_COM	label	Word			; ταβμιγα ζυξλγικ πεςεσωμλι
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
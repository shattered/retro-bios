;--------------------------------------------------------------------------
; DISK_RESET (AH=00H)                                              :
;       σβςοσ δισλοχοκ σιστενω                                     :
;                                                                  :
; χωθοδ:      DSKETTE_STATUS,CY οτςαφαετ υσπεθ οπεςαγιι            :
;---------------------------------------------------------------------------
DISK_RESET      PROC    NEAR
        MOV     DX,03F2H                ; αδςεσ χωθοδξοηο γιζςοχοηο ςεηισεςα
        CLI                             ; ϊαπςετ πςεςωχαξικ
        MOV     AL,MOTOR_STATUS         ; πομυώεξιε οβςαϊα γιζςοχοηο χωθοδξοηο
                                        ; ςεηιστςα
        AND     AL,00111111B            ; χωδεμεξιε βιτοχ σοστορξιρ νοτοςα
        PUSH    CX
        MOV	CL,4
        ROL     AL,CL
        POP	CX                      ; σοστορξιε νοτοςα χ σταςϋικ ξιβμ
                                        ; χωβος δισλοχοδα χ νμαδϋεν ξιβμε
        OR      AL,00001000B            ; ςαϊςεϋεξιε ϊαπςοσοχ πςεςωχαξικ
        OUT     DX,AL                   ; σβςοσ αδαπτεςα
        MOV     SEEK_STATUS,0           ; υσταξοχλα οτνεξω χσεθ δισλοχοδοχ
        JMP     $+2                     ; οφιδαξιε I/O
        JMP     $+2                     ; οφιδαξιε I/O (ποδστςαθοχλα)                               ;     PULSE WIDTH)
        OR      AL,00000100B            ; χλμΰώεξιε βιτα σβςοσα
        OUT     DX,AL                   ; σβςοσ αδαπτεςα
        STI                             ; ςαϊςεϋεξιε πςεςωχαξικ
        CALL    WAIT_INT                ; οφιδαξιε πςεςωχαξιρ
        JC      DR_ERR                  ; πςοχεςλα οϋιβλι (πςεςωχαξιρ ξε πςοιϊοϋμο)
        MOV     CX,11000000B            ; CL=EXPECTED NEC_STATUS

NXT_DRV:
        PUSH    CX
        MOV     AX,OFFSET DR_POP_ERR    ; ϊαηςυϊλα NEC_OUTPUT αδςεσα οϋιβλι
        PUSH    AX
        MOV     AH,08H                  ; λοναξδα υσταξοχλι στατυσα πςεςωχαξικ
        CALL    NEC_OUTPUT
        POP     AX
        CALL    RESULTS                 ; ώτεξιε ςεϊυμψτατα
        POP     CX
        JC      DR_ERR                  ; οϋιβλα - χοϊχςατ
        CMP     CL,NEC_STATUS           ; τεστ δμρ πεςεθοδα ξα ώτεξιε
        JNZ     DR_ERR                  ; χσε OK
        INC     CL                      ; σμεδυΰύικ NEC_STATUS
        CMP     CL,11000011B            ; χσε χοϊνοφξωε δισλοχοδω οώιύεξω
        JBE     NXT_DRV                 ; οϋιβλα εσμι 11000100 ιμι >

        CALL    SEND_SPEC               ; ποσωματψ σπεγιαμψξυΰ λοναξδυ χ NEC
RESBAC:
        CALL    SETUP_END               ; υσταξοχλα χςενεξι νοτοςα
        MOV     BX,SI
        MOV     AL,BL
        RET

DR_POP_ERR:
        POP     CX
DR_ERR:
        OR      DISKETTE_STATUS,BAD_NEC  ; υσταξοχλα λοδα οϋιβλι
        JMP     SHORT RESBAC            ; χωθοδ
DISK_RESET      ENDP
;-----------------------------------------------------------------------
; DISK_STATUS   (AH=01H)                                            :
;       στατυσ δισλετω .                                            :
;    χθοδ :     AH= στατυσ πςεδωδυύεκ οπεςαγιι                      :
;                                                                   :
;   χωθοδ:      DSKETTE_STATUS,CY οτςαφαετ ςεϊυμψτατ ζυξλγιι        :
;--------------------------------------------------------------------------

DISK_STATUS     PROC    NEAR
        MOV     DISKETTE_STATUS,AH      ; υσταξαχμιχαεν δμρ βεϊοϋιβοώξοηο
					; πςοθοφδεξιρ SETUP_END
	JMP	SHORT RESBAC            ; πεςεθοδ ξα :
					; CALL    SETUP_END
					; MOV     BX,SI
					; MOV     AL,BL
					; RET
DISK_STATUS     ENDP
;-------------------------------------------------------------------------
; DISK_READ     (AH=02H)                                                  :
;       ώτεξιε δισλετω
; πςι χθοδε χ ότυ ζυξλγιΰ, δαξξωε οπισωχαΰύιε ξονες δισλοχοδα, ξονες      :
; δοςοφλι ι τ.δ. πεςεηςυφεξω χ σμεδυΰύιε ςεηιστςω:
;     χθοδ:     DI      = ξονες δισλοχοδα                                 :
;               SI-στας = ξονς ηομοχλι                                    :
;               SI-νμαδ = λομιώεστχο ώιταενωθ σελτοςοχ                    :
;               ES      = βυζζεςξωκ σεηνεξτ                               :
;               [BP]    = ξονες σελτοςα                                   :
;               [BP+1]  = ξονες δοςοφλι                                   :
;               [BP+2]  = σνεύεξιε βυζεςα                                 :
;                                                                         :
;   χωθοδ:      DISKETTE_STATUS,CY στατυσ οπεςαγιι                        :
;--------------------------------------------------------------------------
DISK_READ       PROC NEAR
        AND     MOTOR_STATUS,01111111B  ; ιξδιλαγιρ οπεςαγιι ώτεξιρ
        MOV     AX,0E646H               ; AX= NEC λοναξδα, DMA λοναξδα
RD_OB:  CALL    RD_WR_VF                ; πςοηςαννα ώτεξιρ/ϊαπισι/χεςιζιλαγιι
        RET
DISK_READ       ENDP
;-------------------------------------------------------------------------
; DISK_WRITE    (AH=03H)                                                  :
;       ϊαπισψ δισλετω.                                                  :
;     χθοδ:     DI      =  ξονες δισλοχοδα                                :
;               SI-HI   =  ξονς ηομοχλι                                   :
;               SI-LOW  =  λομιώεστχο ώιταενωθ σελτοςοχ                   :
;               ES      =  βυζζεςξωκ σεηνεξτ                              :
;               [BP]    =  ξονες σελτοςα                                  :
;               [BP+1]  =  ξονες δοςοφλι                                  :
;               [BP+2]  =  σνεύεξιε βυζεςα                                :
;                                                                         :
;   χωθοδ:      DSKETTE_STATUS,CY στατυσ οπεςαγιι                         :
;--------------------------------------------------------------------------
DISK_WRITE      PROC NEAR
        MOV     AX,0C54AH               ; AX= NEC λοναξδα, DMA λοναξδα
        OR      MOTOR_STATUS,10000000B  ; ιξδιλαγιρ οπεςαγιι ϊαπισι
	JMP	SHORT RD_OB
DISK_WRITE      ENDP
;-------------------------------------------------------------------------
; DISK_VERF     (AH=04H)                                                  :
;       χεςιζιλαγιρ δισλετω                                               :
;     χθοδ:     DI      =  ξονες δισλοχοδα                                :
;               SI-HI   =  ξονς ηομοχλι                                   :
;               SI-LOW  =  λομιώεστχο ώιταενωθ σελτοςοχ                   :
;               ES      =  βυζζεςξωκ σεηνεξτ                              :
;               [BP]    =  ξονες σελτοςα                                  :
;               [BP+1]  =  ξονες δοςοφλι                                  :
;               [BP+2]  =  σνεύεξιε βυζεςα                                :
;                                                                         :
;   χωθοδ:      DSKETTE_STATUS,CY στατυσ οπεςαγιι                         :
;--------------------------------------------------------------------------
DISK_VERF       PROC NEAR
        AND     MOTOR_STATUS,01111111B  ; ιξδιλαγιρ οπεςαγιι ώτεξιρ
        MOV     AX,0E642H               ; AX= NEC λοναξδα, DMA λοναξδα
	JMP	SHORT RD_OB
DISK_VERF       ENDP
;-------------------------------------------------------------------------
; DISK_FORMAT   (AH=02H)                                                  :
;       ζοςνατιςοχαξιε δισλετω                                            :
;     χθοδ:     DI      = ξονες δισλοχοδα                                 :
;               SI-HI   = ξονς ηομοχλι                                    :
;               SI-LOW  = λομιώεστχο ώιταενωθ σελτοςοχ                    :
;               ES      = βυζζεςξωκ σεηνεξτ                               :
;               [BP]    = ξονες σελτοςα                                   :
;               [BP+1]  = ξονες δοςοφλι                                   :
;               [BP+2]  = σνεύεξιε βυζεςα                                 :
;               DISK_POINTER υλαϊωχαετ ξα ταβμιγυ παςανετςοχ ότοηο        :
;                               δισλοχοδα                                 :
;                                                                         :
;   χωθοδ:      DSKETTE_STATUS,CY στατυσ οπεςαγιι                         :
;--------------------------------------------------------------------------
DISK_FORMAT    PROC NEAR
        CALL    XLAT_NEW                ; πεςεδαώα σοστορξιρ δμρ απποςατξοκ σοχνεστινοστι
        CALL    FMT_INIT                ; υσταξοχλα σοστορξιρ, εσμι ξεοπςεδεμεξο
        OR      MOTOR_STATUS,10000000B  ; ιξδιλαγιρ οπεςαγιι ϊαπισι
        CALL    MED_CHANGE              ; πςοχεςλα σνεξω ξοσιτεμρ
        JC      FM_DON                  ; ξε νεξρμι, πςοπυσλ πςοχεςολ
        CALL    SEND_SPEC               ; σπεγιαμψξαρ λοναξδα  NEC
        CALL    CHK_LASTRATE            ; ZF=1 πςοχεςλα, σλοςοστψ τα φε ?
        JZ      FM_WR                   ; δα, πςοπυσλ σπεγιαμψξοκ λοναξδω
        CALL    SEND_RATE               ; υσταξοχλα σλοςοστι χςαύεξιρ
FM_WR:
        CALL    FMTDMA_SET              ; υσταξοχλα DMA δμρ ζοςνατιςοχαξιρ
        JC      FM_DON                  ; χοϊχςατ σ οϋιβλοκ
        MOV     AH,4DH                  ; υσταξοχλα λοναξδω ζοςνατιςοχαξιρ
        CALL    NEC_INIT                ; ιξιγιαμιϊαγιρ NEC
        JC      FM_DON                  ; οϋιβλα - χωθοδ
        MOV     AX,OFFSET FM_DON        ; ϊαηςυϊλα αδςεσα οϋιβλι
        PUSH    AX                      ; PUSH NEC_OUT οϋιβλι
        MOV     DL,3                    ; BYTES/SECTOR ϊξαώεξιε δμρ NEC
        CALL    GET_PARM
        CALL    NEC_OUTPUT
        MOV     DL,4                    ; SECTORS/TRACK
        CALL    GET_PARM
        CALL    NEC_OUTPUT
        MOV     DL,7                    ; GAP LENGTH
        CALL    GET_PARM
        CALL    NEC_OUTPUT
        MOV     DL,8                    ; FILLER BYTE
        CALL    GET_PARM
        CALL    NEC_OUTPUT
        POP     AX                      ; χοϊχςαύεξιε οϋιβλι
        CALL    NEC_TERM                ; ϊαχεςϋεξιε ι πομυώεξιε στατυσα
FM_DON:
        CALL    XLAT_OLD                ; πεςεδαώα σοστορξιρ δμρ σοχνεστινοκ νοδεμι
        CALL    SETUP_END               ; οώιστλα
        MOV     BX,SI
        MOV     AL,BL
        RET
DISK_FORMAT     ENDP
;--------------------------------------------------------------------------
; FNC_ERR                                                                 :
;       ξεπςαχιμψξαρ ζυξλγιρ ιμι ξεπςαχιμψξωκ δισλοχοδ                    :
;       υσταξοχλα ξεπςαχιμψξοκ λοναξδω χ στατυσε                          :
;                                                                         :
;   χωθοδ:      DSKETTE_STATUS,CY στατυσ οπεςαγιι                         :
;--------------------------------------------------------------------------
FNC_ERR          PROC    NEAR
        MOV     AX,SI
        MOV     AH,BAD_CMD
        MOV     DISKETTE_STATUS,AH
        STC                             ; υσταξοχλα ζμαηα οϋιβλι
        RET
FNC_ERR          ENDP
;----------------------------------------------------------------
; DISK_PARMS  (AH=08H)                                           :
;       ώτεξιε παςανετςοχ δισλοχοδα                              :
;     χθοδ:                                                      :
;       DI = ξονες δισλοχοδα                                     :
;   χωθοδ:                                                       :
;       CL/[BP]  = βιτω 7&6 σταςϋιε 2 βιτα ναλσ. ώισμο γιμιξδςοχ :
;                  βιτω 0-5 ναλσ σελτος/τςελ                     :
;       CH/[BP+1]= νμ. 8 βιτ ναλσ. ώισμα γιμιξδςοχ               :
;       BL/[BP+2]= βιτω 7-4 = 0                                  :
;                  βιτω 3-0 = τιπ δισλοχοδα ιϊ λνοπ              :
;       BH/[BP+3]= 0                                             :
;       DL/[BP+4]= λ-χο ποδλμΰώεξξωθ δισλοχοδοχ                  :
;       DH/[BP+5]= ναλσιναμψξοε ώισμο ηομοχολ                    :
;       DI/[BP+6]= σνεύεξιε ταβμιγω ξοσιτεμψ/δισλοχοδ            :
;       ES       = σεηνεξτ ταβμιγω                               :
;       AX       = 0                                             :
; NOTE  : ϊανετιν, ώτο ιξζοςναγιΰ πομψϊοχατεμψ νοφετ ιϊχμεώ ιϊ   :
;         στελα χ ξεοβθοδινωε ενυ ςεηιστςω, ποσμε χοϊχςατα ιϊ    :
;         πςογεδυςω                                              :
;----------------------------------------------------------------
DISK_PARMS          PROC    NEAR
        CALL    XLAT_NEW                ; σοστορξιε ποδλμΰώεξξοηο αδαπτεςα
        MOV     WORD PTR [BP+2],0       ; τιπ δισλοχοδα = 0
        MOV     AX,EQUIP_FLAG           ; ώτεξιε σμοχα οβοςυδοχαξιρ δμρ οπςεδε
        AND     AL,11000001B            ; μεξιρ ώισμα δισλοχοδοχ
        MOV     DL,2                    ; δισλοχοδω = 2
        CMP     AL,01000001B            ; ποδλμΰώεξο 2 ?
        JZ      STO_DL                  ; πεςεθοδ εσμι δα
        DEC     DL                      ; δισλοχοδ =1
        CMP     AL,00000001B            ; ποδλμΰώεξ 1?
        JNZ     NON_DRV                 ; πεςεθοδ εσμι ξε οδξοηο
STO_DL:
        MOV     [BP+4],DL               ; χοσσταξοχμεξιε ώισμα δισλοχοδοχ
        CMP     DI,1                    ; πςοχεςλα πςαχιμψξοστι ξονεςα δισλοχοδα
        JA      NON_DRV1                ; ξεπςαχιμψξο
        MOV     BYTE PTR[BP+5],1        ; ναλσιναμψξοε ώισμο ηομοχολ = 1
        CALL    CMOS_TYPE               ; τιπ δισλοχοδα χ AL
        JC      CHK_EST                 ; οϋιβλα λνοπ
        OR      AL,AL                   ; τεστ οτσυτστχιρ δισλοχοδα
        JZ      CHK_EST                 ; πεςεθοδ εσμι οτσυτστχυετ
        CALL    DR_TYPE_CHECK           ; πομυώεξιε SEG:OFFSET ταβμιγω ξοσ/δισλ.
        JC      CHK_EST                 ; JMP εσμι ξεσοοτχετστχιε τιπα
        MOV     [BP+2],AL               ; χοσσταξοχμεξιε τιπα ιϊ λνοπ
        MOV     CL,CS:[BX].MD_SEC_TRK   ; πομυώεξιε σελτος/δοςοφλα
        MOV     CH,CS:[BX].MD_MAX_TRK   ; πομυώεξιε ναλσιναμψξοηο ώισμα σελτοςοχ
        JMP     SHORT STO_CX            ; λνοπ πςαχιμψ.,ισπομψϊυεν λνοπ
CHK_EST:
        MOV     AH,DSK_STATE[DI]        ; ϊαηςυϊλα σοστορξιρ ότοηο δισλοχοδα
        TEST    AH,MED_DET              ; πςοχεςλα υσταξοχλι σοστορξιρ
        JZ      NON_DRV1                ; οϋιβλα λνοπ

USE_EST:
        AND     AH,RATE_MSK             ; χωδεμεξιε σλοςοστι
        CMP     AH,RATE_250             ; σλοςοστψ ? 250
        JNE     USE_EST2                ; ξετ, πςοχεςλα δςυηιθ σλοςοστεκ

;----σλοςοστψ 250 KBS, πςοχεςλα ταβμιγω 360 KB
        MOV     AL,01                   ; τιπ δισλοχοδα 1 (360KB)
        CALL    DR_TYPE_CHECK           ; πομυώεξιε CX:BX = ταβμιγω παςανετςοχ
        MOV     CL,CS:[BX].MD_SEC_TRK   ; πομυώεξιε σελτος/δος.
        MOV     CH,CS:[BX].MD_MAX_TRK   ; ναλσιν. ώισμο σελτοςοχ
        TEST    DSK_STATE[DI],TRK_CAPA  ; 80 δος. ?
        JZ      STO_CX                  ; δομφεξ βωτψ 360KB δισλοχοδ

; ---εσμι ότο 1.44 δισλοχοδ

PARM144:
        MOV     AL,04                   ; τιπ 4 (1.44MB)
        CALL    DR_TYPE_CHECK           ; πομυώεξιε CX:BX = ταβμιγω παςανετςοχ
        MOV     CL,CS:[BX].MD_SEC_TRK   ; πομυώεξιε σελτος/δος.
        MOV     CH,CS:[BX].MD_MAX_TRK   ; ναλσιν. ώισμο σελτοςοχ
STO_CX:
        MOV     [BP],CX                 ; ϊαπισψ χ στελ δμρ χοϊχςατα
        MOV     [BP+6],BX               ; αδςεσ ταβμιγω
        MOV     AX,CS                   ; σεηνεξτ ταβμιγω
        MOV     ES,AX                   ; ES σεηνεξτ
DP_OUT:
        CALL    XLAT_OLD                ; δμρ σοχνεστινοστι
        XOR     AX,AX                   ; οώιστλα
        CLC
        RET

;-------- οτςαβοτλα οτσυτστχιρ δισλοχοδα

NON_DRV:
        MOV     BYTE PTR [BP+4],0       ; οώιστλα ώισμα δισλοχοδοχ
NON_DRV1:
        CMP     DI,80H                  ; πςοχεςλα ϊαπςοσα φεστλοηο δισλα
        JB      NON_DRV2                ; πςοδομφεξιε εσμι ξε φεστλικ

;--------φεστλικ δισλ, οϋιβλα ϊαπςοσα

        CALL    XLAT_OLD                ; εύε δμρ σοχνεστινοστι
        MOV     AX,SI                   ; χοσσταξοχμεξιε AL
        MOV     AH,BAD_CMD              ; υσταξοχλα οϋιβλι - ξεπςαχιμψξαρ λοναξδα
        STC                             ; υσταξοχλα οϋιβλι
        RET

NON_DRV2:
        XOR     AX,AX                ; οώιστλα παςανετςοχ εσμι ξετ δισλοχοδα
				     ; ιμι οϋιβλα λνοπ
        MOV     [BP],AX              ; δοςοφελ, σελτος/δοςοφ = 0
        MOV     [BP+5],AH            ; ηομ. = 0
        MOV     [BP+6],AX            ; σνεύεξιε DISK_BASE = 0
        MOV     ES,AX                ; σεηνεξτ
        JMP     SHORT DP_OUT

;------- σλοςοστψ χςαύεξιρ 300KBS ιμι 500 KBS,ποπωτλα ταβμιγω 1.2 MB

USE_EST2:
        MOV     AL,02                   ; τιπ δισλοχ. 1 (1.2MB)
        CALL    DR_TYPE_CHECK           ; αμς CX:BX = ξοσιτ/δισλοχοδ ταβμιγω
        MOV     CL,CS:[BX].MD_SEC_TRK   ; πομυώεξιε σελτος/δος.
        MOV     CH,CS:[BX].MD_MAX_TRK   ; ναλσ. ώισμο δοςοφελ
        CMP     AH,RATE_300             ; σλος 300 ?
        JE      STO_CX                  ; δομφεξ βωτψ 1.2MB δισλοχοδ
        JMP     SHORT PARM144           ; εύε νοφετ βωτψ 1.44MB δισλοχοδ

DISK_PARMS          ENDP

;-----------------------------------------------------------------
;  DISK_TYPE    (AH=15H)                                         :
;       ότα πςογεδυςα χοϊχςαύαετ τιπ δισλοχοδα                   :
;       χθοδ:   DI = ξονες δισλοχοδα                             :
;                                                                :
;     χωθοδ:    AH = τιπ δισλοχοδα, CY=0                         :
;-----------------------------------------------------------------
DISK_TYPE          PROC    NEAR
        CALL    XLAT_NEW                ; δμρ σοχνεστινοστι
        MOV     AL,DSK_STATE[DI]        ; πομυώεξιε σοστορξιρ
        OR      AL,AL                   ; πςοχεςλα ξαμιώιρ δισλοχοδα
        JZ      NO_DRV
        MOV     AH,NOCHGLN              ; ξετ μιξιι σνεξω δισλα δμρ 40 δοςοφ.δισ.
        TEST    AL,TRK_CAPA             ; ιμι ότο 80 τςελοχωκ?
        JZ      DT_BACK                 ; εσμι ξετ JUMP
        MOV     AH,CHGLN

DT_BACK:
        PUSH    AX                      ; ϊαπισψ χοϊχςαύαενοηο ϊξαώεξιρ
        CALL    XLAT_OLD                ; δμρ σοχνεστινοστι
        POP     AX                      ; χοσσταξοχμεξιε χοϊχςαύαενωθ ϊξαώεξικ
        CLC                             ; ξετ οϋιβλι
        MOV     BX,SI                   ;
        MOV     AL,BL                   ;
        RET

NO_DRV:
        XOR     AH,AH                   ; ξετ δισλοχοδα ιμι ξεοπςεδεμεξξωκ τιπ
        JMP     SHORT DT_BACK
DISK_TYPE          ENDP
;-----------------------------------------------------------------
;  DISK_CHANGE  (AH=16H)                                         :
;       ότα πςογεδυςα χοϊχςαύαετ σοστορξιε μιξιι σνεξω δισλα     :
;                                                                :
;      χθοδ:    DI = ξονες δισλοχοδα                             :
;                                                                :
;    χωθοδ:     AH = DSCETTE_STATUS                              :
;                    00 - μιξιρ ξεαλτιχξα, CY = 0                :
;                    06 - μιξιρ αλτιχξα  , CY = 1                :
;-----------------------------------------------------------------
DISK_CHANGE          PROC    NEAR
	not	uppp
        CALL    XLAT_NEW                ; δμρ σοχνεστινοστι
        MOV     AL,DSK_STATE[DI]        ; πομυώεξιε ιξζοςναγιι
        OR      AL,AL                   ; δισλοχοδ πςισυτστχυετ?
        JZ      DC_NON                  ; πεςεθοδ εσμι ξετ
        TEST    AL,TRK_CAPA             ; 80 δοςοφεώξωκ ?
        JZ      SETIT                   ; εσμι ταλ, πςοχεςλα μιξιι σνεξω δισλα

DCO:    CALL    READ_DSKCHNG            ; πομυώεξιε σοστορξιρ μιξιι
        JZ      FINIS                   ; μιξιρ ξεαλτιχξα

SETIT:  MOV     DISKETTE_STATUS,MEDIA_CHANGE    ; ιξδιλαγιρ σνεξω

FINIS:  CALL    XLAT_OLD                ; δμρ σοχνεστινοστι
        CALL    SETUP_END               ; οώιστλα
        MOV     BX,SI
        MOV     AL,BL
        RET

DC_NON:
        OR      DISKETTE_STATUS,TIME_OUT        ; υσταξοχλα TIMEOUT,ξετ δισλοχοδα
        JMP     SHORT FINIS
DISK_CHANGE     ENDP

;----------------------------------------------------------------
;  FORMAT_SET   (AH=17H)                                         :
;       ότα πςογεδυςα ισπομψϊυετσρ δμρ οπςεδεμεξιρ τιπα          :
;       ξοσιτεμρ πςι οπεςαγιι ζοςνατιςοχαξιρ                     :
;                                                                :
;      χθοδ:    SI νμ. = τιπ ζοςνατα                             :
;               DI     = ξονες δισλοχοδα                         :
;                                                                :
;    χωθοδ:     DSKETTE_STATUS οτςαφαετ στατυσ οπεςαγιι          :
;               AH = DSKETTE_STATUS                              :
;               CY = 1 εσμι οϋιβλα                               ;
;-----------------------------------------------------------------
FORMAT_SET          PROC    NEAR
        CALL    XLAT_NEW                ; δμρ σοχνεστινοστι
        PUSH    SI                      ; ϊαπισψ τιπ ξοσιτεμρ
        MOV     AX,SI                   ; AH = ? , AL = τιπ ξοσιτεμρ
        XOR     AH,AH                   ; AH = 0 , AL = τιπ ξοσιτεμρ
        MOV     SI,AX                   ; SI = τιπ ξοσιτεμρ
        AND     DSK_STATE[DI],NOT MED_DET+DBL_STEP+RATE_MSK     ; οώιστλα σοστ.
        DEC     SI                      ; πςοχ.δμρ 320/360K ξοσιτεμρ
        JNZ     NOT_320                 ; οβθοδ εσμι ξετ
        OR      DSK_STATE[DI],MED_DET+RATE_250          ; υσταξοχλα 320/360
        JMP     SHORT SO
NOT_320:
        CALL    MED_CHANGE              ; πςοχ. δμρ TIME_OUT
        CMP     DISKETTE_STATUS,TIME_OUT
        JZ      SO                      ; εσμι χςενρ χωϋμο χωθοδ

ss3:     DEC     SI                     ; πςοχεςλα δμρ 320/360K χ 1.2
        JNZ     NOT_320_12              ; οβθοδ εσμι ξετ
        OR      DSK_STATE[DI],MED_DET+DBL_STEP+RATE_300  ; υσταξοχλα σοστορξιρ
        JMP     SHORT SO
NOT_320_12:
        DEC     SI                      ; πςοχεςλα δμρ 1.2M δισλυε.χ 1.2M δισλοχ.
        JNZ     NOT_12                  ; οβθοδ εσμι ξετ
        OR      DSK_STATE[DI],MED_DET+RATE_500  ; υσταξοχλα πεςενεξξοηο σοστορξιρ
        JMP     SHORT SO                ; χοϊχςατ
NOT_12:
        DEC     SI                      ; πςοχεςλα 4 τιπα ξοσιτεμρ
        JNZ     FS_ERR                  ; ξεπςαχιμψξαρ λοναξδα,ξοσιτ. χωθοδ

        TEST    DSK_STATE[DI],DRV_DET   ; δισλοχοδ οπςεδεμ.?
        JZ      ASSUM                   ; εσμι ξεοπςεδεμεξ, το πςεδπομοηαεν
					; νεδμεξξωκ
        MOV     AL,MED_DET+RATE_300
        TEST    DSK_STATE[DI],FMT_CAPA  ; χοϊνοφξοστψ νξοηοζοςνατξοηο ?
        JNZ     OR_IT_IN                ; εσμι 1.2M τοηδα σλοςοστψ 300
ASSUM:
        MOV     AL,MED_DET+RATE_250    ; υσταξοχλα
OR_IT_IN:
        OR      DSK_STATE[DI],AL        ; OR πςι λοςςελτξον σοστορξιι
SO:
        CALL    XLAT_OLD                ; δμρ σοχνεστινοστι
        CALL    SETUP_END               ; οώιστλα
        POP     BX
        MOV     AL,BL
        RET
FS_ERR:
        MOV     DISKETTE_STATUS,BAD_CMD  ; ξεοπςεδεμεξξοε σοστορξιε, ξεπςαχ.λοναξδα
        JMP     SHORT SO                ;
FORMAT_SET          ENDP

; ----------------------------------------------------------------
;  SET_MEDIA    (AH=18)                                          :
;       ότα πςογεδυςα υσταξαχμιχαετ τιπ ξοσιτεμρ ι σλοςοστψ      :
;       χςαύεξιρ ισπομψϊυενωε πςι ζοςνατιςοχαξιι                 :
;      χθοδ:                                                     :
;       [BP]   = σελτοςοχ ξα τςελ                                :
;       [BP+1] = ξονες τςελα                                     :
;       DI     = ξονες δισλοχοδα                                 :
;    χωθοδ:                                                      :
;       DSKETTE_STATUS οτςαφαετ στατυσ                           :
;       εσμι ξετ οϋιβλι:                                         :
;               AH = 0                                           :
;               CY = 0                                           :
;               ES = σεηνεξτ ταβμιγω ξοσιτεμψ/δισλοχοδ           :
;               DI/[BP+6] = σνεύεξιε                             :
;      εσμι οϋιβλα:                                              :
;               AH = DSKETTE_STATUS                              :
;               CY = 1                                           :
;-----------------------------------------------------------------
SET_MEDIA          PROC    NEAR
        CALL    XLAT_NEW                ; δμρ σοχνεστινοστι
        TEST    DSK_STATE[DI],TRK_CAPA  ; πςοχεςλα ξαμιώιρ μιξιι σνεξω δισλα
        JZ      SM_CMOS                 ; JUMP εσμι 40 δοςοφεώξωκ
        CALL    MED_CHANGE              ; πςοχεςλα χςενεξι
        CMP     DISKETTE_STATUS,TIME_OUT   ; χωθοδ εσμι χςενρ χωϋμο
        JE      SM_RTN
        MOV     DISKETTE_STATUS,0        ; οώιστλα στατυσα
SM_CMOS:
        CALL    CMOS_TYPE               ; τιπ δισλοχοδα χ (AL)
        JC      MD_NOT_FND              ; οϋιβλα λνοπ
        OR      AL,AL                   ; τεστ ξαμιώιρ δνσλοχοδα
        JZ      SM_RTN                  ; χωθοδ εσμι ξετ
        CALL    DR_TYPE_CHECK           ; αδς CX:BX = ταβμιγω ξοσιτεμψ/δισλοχοδ
        JC      MD_NOT_FND              ; τιπ χ ταβμιγε ξεοπςεδεμεξ, οϋιβλα λνοπ
        PUSH    DI
        XOR     BX,BX                   ; BX = ιξδελσ DRV_TYPE ταβμιγω
        MOV     CX,6                    ; CX = σώετώιλ ποχτοςεξικ

DR_SEARCH:
        MOV     AH,CS:DR_TYPE[BX]       ; πομυώεξιε τιπα δισλοχοδα(F000:20E9=1)
        AND     AH,BIT7OFF              ; νασλα
        CMP     AL,AH                   ; σςαχξεξιε τιπα δισλοχοδα ?
        JNE     NXT_MD                  ; ξετ, πςοχεςλα ποσμεδξεηο τιπα δισλοχοδα

        MOV     DI,CS:WORD PTR DR_TYPE[BX+1]    ; DI=ξοσιτεμψ/δισλοχοδ
        MOV     AH,CS:[DI].MD_SEC_TRK   ; πομυώεξιε σελτος/δοςοφ.
        CMP     [BP],AH                 ; σςαχξεξιε ?
        JNE     NXT_MD                  ; ξετ, πςοχεςλα σμεδ.ξοσιτεμρ
        MOV     AH,CS:[DI].MD_MAX_TRK   ; πςοχεςλα ναλσ. ώισμα δοςοφελ
        CMP     [BP+1],AH               ; σςαχ. ?
        JE      MD_FND                  ; δα, πομυώεξιε σλοςοστι χςαύεξιρ
NXT_MD:
        ADD     BX,3                    ; πςοχεςλα σμεδυΰύεηο τιπα δισλοχοδα
        LOOP    DR_SEARCH
        POP     DI                      ; χοσσταξοχμεξιε
MD_NOT_FND:
        MOV     DISKETTE_STATUS,MED_NOT_FND  ; οϋιβλα, δισλετα δαξξοηο τιπα ξε ξακδεξα
        JMP     SHORT SM_RTN                 ; χωθοδ
MD_FND:
        MOV     AL,CS:[DI].MD_RATE      ; πομυώεξιε σλοςοστι
        CMP     AL,RATE_300             ; δχοκξοκ ϋαη δμρ σλοςοστι 300
        JNE     MD_SET
        OR      AL,DBL_STEP
MD_SET:
        MOV     [BP+6],DI               ; ϊαπισψ ταβμιγω υλαϊατεμεκ χ στελ
        OR      AL,MED_DET              ; υσταξοχλα "νεϋαξιξω"
        POP     DI                      ; χοσσταξοχμεξιε ςεηιστςοχ
        AND     DSK_STATE[DI],NOT MED_DET+DBL_STEP+RATE_MSK  ; οώιστλα σοστορξιρ
        OR      DSK_STATE[DI],AL        ; υσταξοχλα σοστορξιρ
        MOV     AX,CS                   ; σεηνεξτ ξοσιτεμψ/δισλοχοδ
        MOV     ES,AX                   ; ES σεηνεξτ
SM_RTN:
        CALL    XLAT_OLD
        CALL    SETUP_END
        RET
SET_MEDIA          ENDP

; ----------------------------------------------------------------
;  DR_TYPE_CHECK                                                 :
;       πςοχεςλα σοοτχετστχιρ τιπα δισλοχοδα χ  (AL)             :
;       ταβμιγαν θςαξρύινσρ χ BIOS                               :
;      χθοδ:                                                     :
;       AL = τιπ δισλοχοδα                                       :
;    χωθοδ:                                                      :
;       CS = σεηνεξτ ταβμιγω ξοσιτεμψ/δισλοχοδ                   :
;       CY = 0 δαξξωκ τιπ δισλοχοδα ποδδεςφιχαετσρ               :
;               BX = σνεύεξιε ταβμιγω                            :
;       CY = 1  τιπ δισλοχοδα ξεποδδεςφιχαετσρ                   :
;  ςαϊςυϋεξ:  BX                                                 :
;-----------------------------------------------------------------
DR_TYPE_CHECK          PROC    NEAR
        PUSH    AX
        PUSH    CX
        XOR     BX,BX                   ; BX = ιξδελσ χ DR_TYPE ταβμιγε
        MOV     CX,DR_CNT               ; CX = σώετώιλ ποχτοςεξικ

TYPE_CHK:
        MOV     AH,CS:DR_TYPE[BX]       ; πομυώεξιε τιπα δισλοχοδα (F000:20E9=1)
        CMP     AL,AH                   ; σςαχξεξιε τιπα ιϊ λνοπ ι ταβμιώξοηο
        JE      DR_TYPE_VALID           ; δα, χωθοδ σ σβςοϋεξξων ζμαηον
        ADD     BX,3                    ; πςοχεςλα σμεδυΰύεηο τιπα δισλοχοδα
        LOOP    TYPE_CHK
        STC                             ; δαξξωκ τιπ δισλοχοδα ξε ξακδεξ χ ταβ.
        JMP     SHORT TYPE_RTN
DR_TYPE_VALID:
        MOV     BX,CS:WORD PTR DR_TYPE[BX+1]    ; BX = σνεύεξιε ταβμιγω ξοσιτ/δισ.
TYPE_RTN:
        POP     CX
        POP     AX
        RET
DR_TYPE_CHECK          ENDP

; ----------------------------------------------------------------
;  SEND_SPEC                                                        :
;       ποσωμαετ σπεγιαμψξυΰ λοναξδυ χ λοξτςομμες ισπομψϊυρ δαξ-    :
;       ξωε ιϊ ταβμιγω παςανετςοχ ξα λοτοςωε υλαϊωχαετ DISK_POINTER :
;  χθοδ:    DISK_POINTER = ταβμιγα παςανετςοχ δισλοχοδα             :
;  χωθοδ:     ξετ                                                   :
;  ιϊνεξεξω:  CX,BX                                                 :
;-----------------------------------------------------------------
SEND_SPEC          PROC    NEAR
        PUSH    AX
        MOV     AX,OFFSET SPECBAC       ; ϊαηςυϊλα αδςεσα οϋιβλι
        PUSH    AX
        MOV     AH,03H                  ; σπεγιαμψξαρ λοναξδα
        CALL    NEC_OUTPUT              ; πςοηςανιςοχαξιε NEC
        SUB     DL,DL                   ; πεςχωκ βακτ παςανετςοχ
        CALL    GET_PARM                ; πομυώεξιε παςανετςα χ AH
        CALL    NEC_OUTPUT              ; χωχοδ λοναδω
        MOV     DL,1                    ; σμεδυΰύικ βακτ     
        CALL    GET_PARM                ; πομυώεξιε παςανετςα χ AH
        CALL    NEC_OUTPUT              ; χωχοδ λοναξδω     
        POP     AX                      
SPECBAC:
        POP     AX                      
        RET
SEND_SPEC          ENDP

; ----------------------------------------------------------------
;  SEND_SPEC_MD                                                  :
;       ποσωμλα σπεγιαμψξοκ λοναξδω χ λοξτςομμες,ισπομψϊυΰύεκ    :
;       δαξξωε ιϊ ταβμιγω ξοσιτεμψ/δισλοχοδ σ υλαϊ.(CX:BX)       :
;      χθοδ:    CX:BX = υλαϊατεμψξα ταβμιγυ                      :
;    χωθοδ:     ξετ                                              :
;-----------------------------------------------------------------
SEND_SPEC_MD          PROC    NEAR
        PUSH    AX                      
        MOV     AX,OFFSET SPEC_ESBAC    ; ϊαηςυϊλα αδςεσα οϋιβολ
        PUSH    AX                      ; σοθςαξεξιε αδςεσα        
        MOV     AH,03H                  ; σπεγιαμψξαρ λοναξδα
        CALL    NEC_OUTPUT              ; χωχοδ λοναξδω     
        MOV     AH,CS:[BX].MD_SPEC1     ; πομυώεξιε πεςχοηο σπεγιαμψξοηο βακτα
        CALL    NEC_OUTPUT              ; χωχοδ λοναξδω     
        MOV     AH,CS:[BX].MD_SPEC2     ; πομυώεξιε σπεγιαμψξοηο βακτα
        CALL    NEC_OUTPUT              ; χωχοδ λοναξδω     
        POP     AX                      
SPEC_ESBAC:
        POP     AX                      
        RET
SEND_SPEC_MD          ENDP              

; ----------------------------------------------------------------
;  XLAT_NEW                                                      :
;       τςαξσμιςυετ οβμαστψ μολαγιι δισλετω δμρ αππαςατξοκ       :
;       σοχνεστινοστι                                            :
;      χθοδ:    DI:δισλοχοδ                                      :
;-----------------------------------------------------------------

XLAT_NEW          PROC    NEAR
        CMP     DI,1                    ; πςαχιμψξωκ ξονες δισλοχοδα ?
        JA      XN_OUT                  ; οϋιβοώξωκ
        CMP     DSK_STATE[DI],0         ; οπςεδεμεξ ?
        JZ      DO_DET                  ; εσμι ξετ ποπωτλα οπςεδεμεξιρ
        MOV     CX,DI                   ; CX = ξονες δισλοχοδα
        SHL     CL,1                    ; CL = σδχιη  ,A=0,B=4
        SHL	CL,1
        MOV     AL,HF_CNTRL             ; ιξζοςναγιρ ο δισλοχοδε
        ROR     AL,CL                   ; χωδιμεξιε σοοτχετστχυΰύεηο ξιβμα
        AND     AL,DRV_DET+FMT_CAPA+TRK_CAPA    ; χωδεμεξιε ξεοβθοδινωθ βιτ
        AND     DSK_STATE[DI],NOT DRV_DET+FMT_CAPA+TRK_CAPA
        OR      DSK_STATE[DI],AL        ; ιϊνεξεξιε σοστορξιρ δισλοχοδα
XN_OUT:
                RET
DO_DET:
                CALL    DRIVE_DET       ; οπςεδεμεξιε δισλοχοδα
                RET
XLAT_NEW          ENDP

; ----------------------------------------------------------------
;  XLAT_OLD                                                      :
;       πεςεδαώα ςασπομοφεξιρ ταβμιγω ξοσιτεμψ/δισλοχοδ          :
;       ιϊ δςυηοκ αςθιτελτυςω δμρ ποδδεςφαξιρ σοχνεστινοστι      :
;      χθοδ:    DI:δισλοχοδ                                      :
;-----------------------------------------------------------------
XLAT_OLD          PROC    NEAR
        CMP     DI,1                    ; πςαχιμψξοστψ ξονεςα δισλοχοδα ?
        JA      XN_OUT                  ; εσμι ξεπςαχιμψξωκ
        CMP     DSK_STATE[DI],0         ; ξετ δισλοχοδα ?
        JE      XN_OUT                  ; εσμι ξετ

;-------   τεστ εσμι ιξζοςναγιρ ο δισλοχοδε υφε υσταξοχμεξα

        MOV     CX,DI                   ; CX = ξονες δισλοχοδα
        SHL     CL,1                    ; CL = σδχιη ,A=0,B=4
        SHL	CL,1
        MOV     AH,FMT_CAPA             ; ϊαηςυϊλα νασλι νξοηοζοςνατξοηο δισλοχ.
        ROR     AH,CL                   ; χςαύεξιε νασλι
        TEST    HF_CNTRL,AH             ; υσταξξοχμεξ μι ςεφιν νξοηοσλοςοστ. ?
        JNZ     SAVE_SET                ; εσμι δα, το ξε ξυφδαετσρ χ πεςευσταξοχλε

;-------  στιςατψ βιτ δισλοχοδα χ HF_CNTRL δμρ ότοηο δισλοχοδα

        MOV     AH,DRV_DET+FMT_CAPA+TRK_CAPA    ; νασλα
        ROR     AH,CL
        NOT     AH
        AND     HF_CNTRL,AH

;-------  δοστυπ λ τελυύενυ δισλοχοδυ ι υσταξοχλα χ HF_CNTRL

        MOV     AL,DSK_STATE[DI]        ; πομυώεξιε σοστορξιρ
        AND     AL,DRV_DET+FMT_CAPA+TRK_CAPA    ; χωδεμεξιε βιτ δισλοχοδα
        ROR     AL,CL                   ; δμρ χωβςαξξοηο δισλοχοδα
        OR      HF_CNTRL,AL             ; ϊαπισψ ιϊνεξεξξοηο σοστορξιρ

;------πεςεδαώα δμρ σοχνεστινοστι    

SAVE_SET:
        MOV     AH,DSK_STATE[DI]        ; δοστυπ λ σοστορξιΰ
        MOV     BH,AH                   ; χ BH δμρ σςαχξεξιρ
        AND     AH,RATE_MSK             ; χωδεμεξιε σλοςοστι
        CMP     AH,RATE_500             ; σλος 500 ?
        JZ      CHK_144                 ; δα 1.2/1.2 ιμι 1.44/1.44
        MOV     AL,M3D1U                ; AL =360 χ 1.2 
        CMP     AH,RATE_300             ; σλος 300 ?
        JNZ     CHK_250                 ; ξετ,360/360,720/720 ιμι 720/1.44
        TEST    BH,DBL_STEP             ; δα,δχοκξοκ ϋαη ?
        JNZ     TST_DET                 ; δα, ότο 360 χ 1.2 
UNKNO:
        MOV     AL,MED_UNK              ; 'ξιλτο ξε βομψϋε'
        JMP     SHORT AL_SET            ; πςογεσσ ϊαχεςϋεξ
CHK_144:
        CALL    CMOS_TYPE               ; τιπ δισλοχοδα χ (AL)
        JC      UNKNO                   ; οϋιβλα υσταξοχλα 'ξε βομψϋε'
        CMP     AL,02                   ; 1.2MB δισλοχοδ ?
        JNE     UNKNO                   ; ξετ,υσταξοχλα 'ξιλτο ξε βομψϋε'
        MOV     AL,M1D1U                ; AL = 1.2 χ 1.2
        JMP     SHORT TST_DET
CHK_250:
        MOV     AL,M3D3U                ; AL = 360 χ 360 
        CMP     AH,RATE_250             ; σλος 250 ?
        JNE     UNKNO                   ; εσμι ξετ
        TEST    BH,TRK_CAPA             ; 80 τςελοχ  ?
        JNZ     UNKNO                   
TST_DET:
        TEST    BH,MED_DET              ; οπςεδεμεξ ?
        JZ      AL_SET                  ; εσμι ξετ, τοηδα υσταξαχμιχαεν
        ADD     AL,3                    ; δεμαξν οπςεδεμεξ/υσταξοχμεξ
AL_SET:
        AND     DSK_STATE[DI],NOT DRV_DET+FMT_CAPA+TRK_CAPA     ; οώιστλα δισλοχοδα
        OR      DSK_STATE[DI],AL        ; λοπιςοχαξιε δμρ σοχνεστινοκ νοδεμι
XO_OUT:
        RET
XLAT_OLD          ENDP

; ----------------------------------------------------------------
;  RD_WR_VF                                                      :
;       πςογεδυςα ώτεξιρ, ϊαπισι ι χεςιζιλαγιι                   :
;       οσξοχξοκ γιλμ δμρ ποχτοςεξιρ                             :
;      χθοδ:    AH : παςανετςω NEC δμρ ώτεξιρ, ϊαπισι, χεςιζιλ.  :
;               AL : παςανετςω DMA δμρ ώτεξιρ, ϊαπισι, χεςιζιλ.  :
;    χωθοδ:     DSKETTE_STATUS, CY στατυσ οπεςαγιι               :
;-----------------------------------------------------------------

RD_WR_VF          PROC    NEAR
        PUSH    AX                      ; σοθςαξεξιε παςανετςοχ DMA ι NEC
        CALL    XLAT_NEW                ; τςαξσμιςυετ σοστορξιε ποδλμΰώ. δισλ.
        CALL    SETUP_STATE             ; ιξιγιαμιϊιςυετ ξαώαμψξυΰ ι λοξεώξυΰ
					; σλοςοστψ χ σμυώαε ξεοπςεδεμεξξοστι
					; δισλοχοδα ι τιπα ξοσιτεμρ
        POP     AX                      ; χοσσταξοχμεξιε
DO_AGAIN:
        PUSH    AX                      ; σοθςαξεξιε παςανετςοχ DMA ι NEC
        CALL    MED_CHANGE              ; πςοχεςλα σνεξω δισλετω ι σβςοσα

        POP     AX
        JNC     RWV
        JMP     RWV_END
RWV:
        PUSH    AX
        MOV     DH,DSK_STATE[DI]        ; πομυώεξιε σλοςοστι
        AND     DH,RATE_MSK
        CALL    CMOS_TYPE               ; τιπ δισλοχοδα χ (AL)
        JC      RWV_ASSUME              ; οϋιβλα χ CMOS
        CMP     AL,1                    ; 40 τςελοχωκ δισλοχοδ ?
        JNE     RWV_1                   ; ξετ, οβθοδ λοςςελτξοστι CMOS
        TEST    DSK_STATE[DI],TRK_CAPA  ; πςοχεςλα δμρ 40 τςελοχοηο δισλοχοδα
        JZ      RWV_2                   ; δα, CMOS λοςςελτξο
        MOV     AL,2                    ; σνεξα 1.2M
        JMP     SHORT RWV_2             ; πςοδομφεξιε
RWV_1:
        JB      RWV_2                   ; δισλοχοδ ξε οπςεδεμεξ
        TEST    DSK_STATE[DI],1         ; εσμι ότο 40 τςελοχωκ ?
        JNZ     RWV_2                   ; ξετ 80 τςελοχ
        MOV     AL,1                    ; εσμι 40 τςελοχ, το ισπςαχμεξιε CMOS
RWV_2:
        OR      AL,AL
        JZ      RWV_ASSUME              ; πςεδπομοηαεν ναλσιναμψξοε λ-χο δοςοφελ
        CALL    DR_TYPE_CHECK           ; CX:BX = ταβμιγα παςανετςοχ ξοσιτεμψ/δισλοχοδ
        JC      RWV_ASSUME              ; τιπα ξετ χ ταβμιγε(οϋιβλα CMOS)

;------ ποισλ δμρ ταβμιγω παςανετςοχ ξοσιτεμψ/δισλοχοδ

        PUSH    DI                      ; σοθςαξεξιε ξονεςα δισλοχοδα
        XOR     BX,BX                   ; BX = ιξδλσ χ DR_TYPE ταβμιγε
        MOV     CX,DR_CNT               ; CX = σώετώιλ ποχτοςεξικ
RWV_DR_SEARCH:
        MOV     AH,CS:DR_TYPE[BX]       ; πομυώεξιε τιπα δισλοχοδα
        AND     AH,BIT7OFF              ; νασλα 7 βιτα
        CMP     AL,AH                   ; τιπ σοχποδαετ ?
        JNE     RWV_NXT_MD              ; ξετ πςοχεςλα σμεδυΰύεηο τιπα
RWV_RR_FND:
        MOV     DI,WORD PTR CS:DR_TYPE[BX+1]    ; ξοσιτεμψ/δισλοχοδ ταβμιγα παςανετςοχ
RWV_MD_SEARCH:
        CMP     DH,CS:[DI].MD_RATE      ; σοχπαδαΰτ ?
        JE      RWV_MD_FND              ; δα, πομυώεξιε πεςχοηο βακτα
RWV_NXT_MD:
        ADD     BX,3                    ; πςοχεςλα σμεδυΰύεηο δισλοχοδα
        LOOP    RWV_DR_SEARCH
        POP     DI                      ; χοσσταξοχμεξιε ξονεςα δισλοχοδα

;------- πςεδπομοηαεν ώτο πεςχωκ δισλοχοδ χεδυύικ

RWV_ASSUME:
        MOV     BX,OFFSET MD_TBL1       ; υλαϊατεμψ ξα 40 δος ι σλοςοστψ 250
        TEST    DSK_STATE[DI],TRK_CAPA  ; τεστ δμρ 80 δοςοφελ
        JZ      RWV_MD_FND1             ; νοφετ βωτψ 40 δοςοφελ
        MOV     BX,OFFSET MD_TBL3       ; υλαϊατεμψ ξα 80 τς 500 KBS
	JMP     short RWV_MD_FND1             ; πομυώεξιε σπεγιαμψξωθ παςανετςοχ

;------- CS:BX υλαϊατεμψ ξα ταβμιγυ ξοσιτεμψ/δισλοχοδ

RWV_MD_FND:
        MOV     BX,DI
	POP     DI                      ; χοσσταξοχμεξιε ξονεςα δισλοχοδα
RWV_MD_FND1:

;-------- ποσωμλα σπεγιαμψξοκ λοναξδω χ NEC λοξτςομμες

        CALL    SEND_SPEC_MD
        CALL    CHK_LASTRATE            ; ZF = 1 ποπωτλα σλοςοστι λαλ χ ποσμ-
					; μεδξεκ οπεςαγιι
        JZ      RWV_DBL                 ; δα, πςοπυσλ λοναξδω υσταξοχλι σλοςοστι
        CALL    SEND_RATE               ; υσταξοχλα σλοςοστι χςαύεξιρ
RWV_DBL:
        PUSH    BX                      ; σοθςαξεξιε αδςεσα ταβμιγω
        CALL    SETUP_DBL               ; πςοχεςλα δμρ δχοκξοηο ϋαηα
        POP     BX                      ; χοσσταξοχμεξιε αδςεσα
        JC      CHK_RET                 ; οϋιβλα ώτεξιρ, χοϊνοφξο ποχτοςεξιε
        POP     AX                      ; χοσσταξοχμεξιε NEC, DMA λοναξδ
        PUSH    AX                      ; σοθςαξεξιε
        PUSH    BX
        CALL    DMA_SETUP               ; πςοηςανιςοχαξιε DMA
        POP     BX
        POP     AX                      ; χοσσταξοχμεξιε NEC λοναξδω
        JC      RWV_BAC                 ; πςοχεςλα οϋιβλι DMA
        PUSH    AX                      ; σοθςαξεξιε NEC λοναξδω
        PUSH    BX                      ; σοθςαξεξιε αδςεσα
        CALL    NEC_INIT                ; ιξιγιαμιϊαγιρ NEC
        POP     BX                      ; χοσσταξοχμεξιε αδςεσα
        JC      CHK_RET                 ; χωθοδ-οϋιβλα
        CALL    RWV_COM                 ; λοδ ώτεξιρ/ϊαπισι/χεςιζιλαγιι
        JC      CHK_RET                 ; χωθοδ-οϋιβλα
        CALL    NEC_TERM                ; ϊαχεςϋεξιε πομυώεξιε στατυσα
CHK_RET:
        CALL    RETRY                   ; πςοχεςλα δμρ ποχτοςα
        POP     AX                      ; χοσσταξοχμεξιε παςανετςοχ ώτ/ϊαπ/χες
        JNC     RWV_END                 ; CY = 0 ξε ποχτοςρτψ
        JMP     DO_AGAIN                ; CY = 1 ποχτοςρτψ
RWV_END:
        CALL    DSTATE                  ; υσταξοχλα σοστορξιρ, εσμι υσπεθ
        CALL    NUM_TRANS               ; AL = πεςεσωμαενοε ώισμο
RWV_BAC:
        PUSH    AX                      ; σοθςαξεξιε
        CALL    XLAT_OLD                ; πεςεδαώα δμρ σοχνεστινοστι
        POP     AX
        CALL    SETUP_END               ; οώιστλα
        RET
RD_WR_VF          ENDP
;--------------------------------------------------------------------
;  SETUP_STATE:    ιιγιαμιϊαγιρ ξαώαμψξοκ ι λοξεώξοκ σλοςοστι        :
;--------------------------------------------------------------------
SETUP_STATE          PROC    NEAR
        TEST    DSK_STATE[DI],MED_DET   ; δισλετα οπςεδεμεξα ?
        JNZ     J1C                     ; πςοπυσλ, εσμι οπςεδεμεξα
        MOV     AX,0040H                ; AH = σταςτοχαρ σλοςοστψ_500,
					; AL=λοξεώξαρ σλοςοστψ_300
        TEST    DSK_STATE[DI],DRV_DET   ; δισλοχοδ οπςεδεμεξ ?
        JZ      AX_SET                  ; ξε ξαδο οπςεδεμρτψ
        TEST    DSK_STATE[DI],FMT_CAPA  ; νξοηο-σλοςοστξοκ (1.2M) ?
        JNZ     AX_SET                  ; JUMP εσμι δα
        MOV     AX,8080H                ; σταςτοχαρ σλοςοστψ = 250 δμρ 360 δισλοχοδα
AX_SET:
        AND     DSK_STATE[DI],NOT RATE_MSK+DBL_STEP     ; χωλμΰώεξιε βιτοχ σλοςοστι
        OR      DSK_STATE[DI],AH        ; υσταξοχλα σλοςοστι 250
        AND     LASTRATE,NOT STRT_MSK   ; στιςαξιε ποσμεδξεηο βιτα σλοςοστι
        PUSH    CX
        MOV	CL,4
        ROR     AL,CL
        POP	CX                      ; ποσμεδξρρ σλοςοστψ
        OR      LASTRATE,AL
J1C:
        RET
SETUP_STATE          ENDP
;--------------------------------------------------------------------
;  FMT_INIT: υσταξοχλα σοστορξιρ, εσμι χςενρ ζοςνατιςοχαξιρ ξε υσταξοχμεξο
;--------------------------------------------------------------------
FMT_INIT        PROC    NEAR
        TEST    DSK_STATE[DI],MED_DET   ; ξοσιτεμψ υσταξοχμεξ
        JNZ     FI_OUT                  ; εσμι ταλ - χωθοδ
        CALL    CMOS_TYPE               ; τιπ δισλοχοδα χ AL
        JC      CL_DRV                  ; οϋιβλα λνοπ, πςεδπομοηαεν οτσυτσ-
					; τχιε δισλοχοδα
        DEC     AL                      ; υσταξοχλα ξαώαμψξοηο σοστορξιρ
        JS      CL_DRV                  ; ξετ δισλοχοδα εσμι 0
        MOV     AH,DSK_STATE[DI]        ; AH = τελυύεε σοστορξιε
        AND     AH,NOT MED_DET+DBL_STEP+RATE_MSK        ; οώιστλα
        OR      AL,AL                   ; πςοχεςλα δμρ 360
        JNZ     N_360                   ; εσμι 360 το 0
        OR      AH,MED_DET+RATE_250     ; υσταξοχλα ξοσιτεμρ
        JMP     SHORT SKP_STATE         ; πςοπυσλ δςυηιθ οβςαβοτολ
N_360:
        DEC     AL                      ; 1.2 M δισλοχοδ
        JNZ     N_12                    ; JUMP εσμι ξετ
FI_RATE:
        OR      AH,MED_DET+RATE_500     ; υσταξοχλα σλοςοστι ζοςνατιςοχαξιρ
        JMP     SHORT SKP_STATE         ; πςοπυσ δςυηιθ οβςαβοτολ
N_12:
        DEC     AL                      ; πςοχεςλα 3 τιπα
        JNZ     N_720                   ; JUMP εσμι ξετ
        TEST    AH,DRV_DET              ; δισλοχοδ οπςεδεμεξ
        JZ      ISNT_12                 ; οβςαύεξιε λαλ ξε 1.2
        TEST    AH,FMT_CAPA             ; 1.2 M
        JZ      ISNT_12                 ; JUMP εσμι ξετ
        OR      AH,MED_DET+RATE_300     ; 300
        JMP     SHORT SKP_STATE         ; πςοδομφεξιε
N_720:
        DEC     AL                      ; πςοχεςλα δμρ τιπα 4
        JNZ     CL_DRV                  ; ξετ δισλοχοδα, οϋιβλα λνοπ
        JMP     SHORT FI_RATE
ISNT_12:
        OR      AH,MED_DET+RATE_250     ; σλοςοστψ 250
SKP_STATE:
        MOV     DSK_STATE[DI],AH        ; υσταξοχλα
FI_OUT:
        RET
CL_DRV:
        XOR     AH,AH                   ; οώιστλα σοστορξιρ
        JMP     SHORT SKP_STATE         ; ϊαπισψ εηο
FMT_INIT        ENDP
; ----------------------------------------------------------------
;  MED_CHANGE                                                    :
;       πςοχεςλα σνεξω δισλετω, σβςοσ μιξιι σνεξω δισλετω        :
;       ι σξοχα πςοχεςλα σνεξω                                   :
;                                                                :
;    χωθοδ:     CY = 1 δισλετα σνεξεξα ιμι χςενρ χωϋμο           :
;               DSKETTE_STATUS = λοδ οϋιβλι                      :
;-----------------------------------------------------------------
MED_CHANGE          PROC    NEAR
        CALL    READ_DSKCHNG            ; ώτεξιε σοστορξιρ μιξιι σνεξω δισλετω
        JZ      MC_OUT                  ; οβθοδ εσμι ξε σνεξεα
        AND     DSK_STATE[DI],NOT MED_DET       ; οώιστλα σοστορξιρ δμρ ϊαπςα-
						; ϋιχαενοηο δισλοχοδα


        MOV     CX,DI                   ; CL = ξονες δισλοχοδα
        MOV     AL,1                    ; βιτ νασλι νοτοςα
        SHL     AL,CL                   ; σοοτχετστχυΰύαρ ποϊιγιρ
        NOT     AL
        CLI                             ; ϊαπςετ πςεςωχαξικ
        AND     MOTOR_STATUS,AL         ; ποχοςοτ νοτοςα δμρ ιξδιλαγιι
        STI                             ; ςαϊςεϋεξιε πςεςωχαξικ
        CALL    MOTOR_ON                ; ποχοςοτ νοτοςα

;--------  σβςοσ σιηξαμα

        CALL    DISK_RESET              ; σβςοσ
        MOV     CH,01H                  ; πεςεδχιφεξιε ξα 1 δοςοφλυ
        CALL    SEEK                    ; χωπομξεξιε πεςεδχιφεξιρ
        XOR     CH,CH                   ; πεςεδχιφεξιε ξα 0 δοςοφλυ
        CALL    SEEK                    ; χωπομξεξιε πεςεδχιφεξιρ
        MOV     DISKETTE_STATUS,MEDIA_CHANGE    ; σοθςαξεξιε χ στατυσε

OK1:    CALL    READ_DSKCHNG            ; πςοχεςλα σνεξω σξοχα
        JZ	MC_OUT                  ; ???
;        JZ      OK2                     ; IF ACTIVE, NO DISKETTE, TIMEOUT

OK4:    MOV     DISKETTE_STATUS,TIME_OUT  ; χςενρ χωϋμο εσμι δισλοχοδ πυστ
OK2:
        STC                             ; σνεξεξα, υσταξοχλα CY
        RET
MC_OUT:
        CLC                             ; ξε σνεξεξα
        RET
MED_CHANGE          ENDP
; ----------------------------------------------------------------
;  SEND_RATE                                                     :
;       ποσωμλα σλοςοστι χςαύεξιρ χ NEC                          :
;      χθοδ:    DI = ξονες δισλοχοδα                             :
;    χωθοδ:     ξετ                                              :
;  ιϊνεξεξ:     DX                                               :
;-----------------------------------------------------------------
SEND_RATE          PROC    NEAR

        PUSH    AX
        AND     LASTRATE,NOT SEND_MSK   ; οώιστλα σλοςοστι ποσμεδξεηο οβςαύεξιρ
        MOV     AL,DSK_STATE[DI]        ; πομυώεξιε σλοςοστι δαξξοηο δισλοχοδα
        AND     AL,SEND_MSK             ; οσταχιτψτομψλο βιτω σλοςοστι
        OR      LASTRATE,AL             ; σοθςαξεξιε ξοχοκ σλοςοστι δμρ σμεδυ-
					; ΰύεκ πςοχεςλι
        ROL     AL,1                    ; πεςεδχιφεξιε βιτοχ χ ξυφξυΰ ποϊιγιΰ
        ROL	AL,1
        MOV     DX,03F7H                ; υσταξοχλα ξοχοκ σλοςοστι
        OUT     DX,AL
        POP     AX
        RET
SEND_RATE          ENDP

; ----------------------------------------------------------------
;  CHK_LASTRATE                                                  :
;       πςοχεςλα πςεδωδυύεκ σλοςοστι χςαύεξιρ                    :
;      χθοδ:                                                     :
;       DI = ξονες δισλοχοδα                                     :
;    χωθοδ:                                                      :
;       ZF = 1 σλοςοστψ τα φε, ώτο ι χ πςεδωδυύεκ οπεςαγιι       :
;       ZF = 0 δςυηαρ                                            :
;  ιϊνεξεξ:  BX                                                  :
;-----------------------------------------------------------------
CHK_LASTRATE          PROC    NEAR
        PUSH    AX
        MOV     AH,LASTRATE             ; πομυώεξιε σλοςοστι πςεδωδυύεκ οπεςαγιι
        MOV     AL,DSK_STATE[DI]        ; πομυώεξιε σλοςοστι ότοηο δισλοχοδα
        AND     AX,0C0C0H ;SEND_MSK*X   ; τομψλο βιτω σλοςοστι
        CMP     AL,AH                   ; σςαχξεξιε σ πςεδωδυύεκ
                                        ; ZF = 1 σλοςοστψ τα φε
        POP     AX
        RET
CHK_LASTRATE          ENDP

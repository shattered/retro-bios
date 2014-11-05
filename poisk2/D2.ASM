;--------------------------------------------------------------------------
; DISK_RESET (AH=00H)                                              :
;       СБРОС ДИСКОВОЙ СИСТЕМЫ                                     :
;                                                                  :
; ВЫХОД:      DSKETTE_STATUS,CY ОТРАЖАЕТ УСПЕХ ОПЕРАЦИИ            :
;---------------------------------------------------------------------------
DISK_RESET      PROC    NEAR
        MOV     DX,03F2H                ; АДРЕС ВЫХОДНОГО ЦИФРОВОГО РЕГИСЕРА
        CLI                             ; ЗАПРЕТ ПРЕРЫВАНИЙ
        MOV     AL,MOTOR_STATUS         ; ПОЛУЧЕНИЕ ОБРАЗА ЦИФРОВОГО ВЫХОДНОГО
                                        ; РЕГИСТРА
        AND     AL,00111111B            ; ВЫДЕЛЕНИЕ БИТОВ СОСТОЯНИЯ МОТОРА
        PUSH    CX
        MOV	CL,4
        ROL     AL,CL
        POP	CX                      ; СОСТОЯНИЕ МОТОРА В СТАРШИЙ НИБЛ
                                        ; ВЫБОР ДИСКОВОДА В МЛАДШЕМ НИБЛЕ
        OR      AL,00001000B            ; РАЗРЕШЕНИЕ ЗАПРОСОВ ПРЕРЫВАНИЙ
        OUT     DX,AL                   ; СБРОС АДАПТЕРА
        MOV     SEEK_STATUS,0           ; УСТАНОВКА ОТМЕНЫ ВСЕХ ДИСКОВОДОВ
        JMP     $+2                     ; ОЖИДАНИЕ I/O
        JMP     $+2                     ; ОЖИДАНИЕ I/O (ПОДСТРАХОВКА)                               ;     PULSE WIDTH)
        OR      AL,00000100B            ; ВКЛЮЧЕНИЕ БИТА СБРОСА
        OUT     DX,AL                   ; СБРОС АДАПТЕРА
        STI                             ; РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ
        CALL    WAIT_INT                ; ОЖИДАНИЕ ПРЕРЫВАНИЯ
        JC      DR_ERR                  ; ПРОВЕРКА ОШИБКИ (ПРЕРЫВАНИЯ НЕ ПРОИЗОШЛО)
        MOV     CX,11000000B            ; CL=EXPECTED NEC_STATUS

NXT_DRV:
        PUSH    CX
        MOV     AX,OFFSET DR_POP_ERR    ; ЗАГРУЗКА NEC_OUTPUT АДРЕСА ОШИБКИ
        PUSH    AX
        MOV     AH,08H                  ; КОМАНДА УСТАНОВКИ СТАТУСА ПРЕРЫВАНИЙ
        CALL    NEC_OUTPUT
        POP     AX
        CALL    RESULTS                 ; ЧТЕНИЕ РЕЗУЛЬТАТА
        POP     CX
        JC      DR_ERR                  ; ОШИБКА - ВОЗВРАТ
        CMP     CL,NEC_STATUS           ; ТЕСТ ДЛЯ ПЕРЕХОДА НА ЧТЕНИЕ
        JNZ     DR_ERR                  ; ВСЕ OK
        INC     CL                      ; СЛЕДУЮЩИЙ NEC_STATUS
        CMP     CL,11000011B            ; ВСЕ ВОЗМОЖНЫЕ ДИСКОВОДЫ ОЧИЩЕНЫ
        JBE     NXT_DRV                 ; ОШИБКА ЕСЛИ 11000100 ИЛИ >

        CALL    SEND_SPEC               ; ПОСЫЛАТЬ СПЕЦИАЛЬНУЮ КОМАНДУ В NEC
RESBAC:
        CALL    SETUP_END               ; УСТАНОВКА ВРЕМЕНИ МОТОРА
        MOV     BX,SI
        MOV     AL,BL
        RET

DR_POP_ERR:
        POP     CX
DR_ERR:
        OR      DISKETTE_STATUS,BAD_NEC  ; УСТАНОВКА КОДА ОШИБКИ
        JMP     SHORT RESBAC            ; ВЫХОД
DISK_RESET      ENDP
;-----------------------------------------------------------------------
; DISK_STATUS   (AH=01H)                                            :
;       СТАТУС ДИСКЕТЫ .                                            :
;    ВХОД :     AH= СТАТУС ПРЕДЫДУЩЕЙ ОПЕРАЦИИ                      :
;                                                                   :
;   ВЫХОД:      DSKETTE_STATUS,CY ОТРАЖАЕТ РЕЗУЛЬТАТ ФУНКЦИИ        :
;--------------------------------------------------------------------------

DISK_STATUS     PROC    NEAR
        MOV     DISKETTE_STATUS,AH      ; УСТАНАВЛИВАЕМ ДЛЯ БЕЗОШИБОЧНОГО
					; ПРОХОЖДЕНИЯ SETUP_END
	JMP	SHORT RESBAC            ; ПЕРЕХОД НА :
					; CALL    SETUP_END
					; MOV     BX,SI
					; MOV     AL,BL
					; RET
DISK_STATUS     ENDP
;-------------------------------------------------------------------------
; DISK_READ     (AH=02H)                                                  :
;       ЧТЕНИЕ ДИСКЕТЫ
; ПРИ ВХОДЕ В ЭТУ ФУНКЦИЮ, ДАННЫЕ ОПИСЫВАЮЩИЕ НОМЕР ДИСКОВОДА, НОМЕР      :
; ДОРОЖКИ И Т.Д. ПЕРЕГРУЖЕНЫ В СЛЕДУЮЩИЕ РЕГИСТРЫ:
;     ВХОД:     DI      = НОМЕР ДИСКОВОДА                                 :
;               SI-СТАР = НОМР ГОЛОВКИ                                    :
;               SI-МЛАД = КОЛИЧЕСТВО ЧИТАЕМЫХ СЕКТОРОВ                    :
;               ES      = БУФФЕРНЫЙ СЕГМЕНТ                               :
;               [BP]    = НОМЕР СЕКТОРА                                   :
;               [BP+1]  = НОМЕР ДОРОЖКИ                                   :
;               [BP+2]  = СМЕЩЕНИЕ БУФЕРА                                 :
;                                                                         :
;   ВЫХОД:      DISKETTE_STATUS,CY СТАТУС ОПЕРАЦИИ                        :
;--------------------------------------------------------------------------
DISK_READ       PROC NEAR
        AND     MOTOR_STATUS,01111111B  ; ИНДИКАЦИЯ ОПЕРАЦИИ ЧТЕНИЯ
        MOV     AX,0E646H               ; AX= NEC КОМАНДА, DMA КОМАНДА
RD_OB:  CALL    RD_WR_VF                ; ПРОГРАММА ЧТЕНИЯ/ЗАПИСИ/ВЕРИФИКАЦИИ
        RET
DISK_READ       ENDP
;-------------------------------------------------------------------------
; DISK_WRITE    (AH=03H)                                                  :
;       ЗАПИСЬ ДИСКЕТЫ.                                                  :
;     ВХОД:     DI      =  НОМЕР ДИСКОВОДА                                :
;               SI-HI   =  НОМР ГОЛОВКИ                                   :
;               SI-LOW  =  КОЛИЧЕСТВО ЧИТАЕМЫХ СЕКТОРОВ                   :
;               ES      =  БУФФЕРНЫЙ СЕГМЕНТ                              :
;               [BP]    =  НОМЕР СЕКТОРА                                  :
;               [BP+1]  =  НОМЕР ДОРОЖКИ                                  :
;               [BP+2]  =  СМЕЩЕНИЕ БУФЕРА                                :
;                                                                         :
;   ВЫХОД:      DSKETTE_STATUS,CY СТАТУС ОПЕРАЦИИ                         :
;--------------------------------------------------------------------------
DISK_WRITE      PROC NEAR
        MOV     AX,0C54AH               ; AX= NEC КОМАНДА, DMA КОМАНДА
        OR      MOTOR_STATUS,10000000B  ; ИНДИКАЦИЯ ОПЕРАЦИИ ЗАПИСИ
	JMP	SHORT RD_OB
DISK_WRITE      ENDP
;-------------------------------------------------------------------------
; DISK_VERF     (AH=04H)                                                  :
;       ВЕРИФИКАЦИЯ ДИСКЕТЫ                                               :
;     ВХОД:     DI      =  НОМЕР ДИСКОВОДА                                :
;               SI-HI   =  НОМР ГОЛОВКИ                                   :
;               SI-LOW  =  КОЛИЧЕСТВО ЧИТАЕМЫХ СЕКТОРОВ                   :
;               ES      =  БУФФЕРНЫЙ СЕГМЕНТ                              :
;               [BP]    =  НОМЕР СЕКТОРА                                  :
;               [BP+1]  =  НОМЕР ДОРОЖКИ                                  :
;               [BP+2]  =  СМЕЩЕНИЕ БУФЕРА                                :
;                                                                         :
;   ВЫХОД:      DSKETTE_STATUS,CY СТАТУС ОПЕРАЦИИ                         :
;--------------------------------------------------------------------------
DISK_VERF       PROC NEAR
        AND     MOTOR_STATUS,01111111B  ; ИНДИКАЦИЯ ОПЕРАЦИИ ЧТЕНИЯ
        MOV     AX,0E642H               ; AX= NEC КОМАНДА, DMA КОМАНДА
	JMP	SHORT RD_OB
DISK_VERF       ENDP
;-------------------------------------------------------------------------
; DISK_FORMAT   (AH=02H)                                                  :
;       ФОРМАТИРОВАНИЕ ДИСКЕТЫ                                            :
;     ВХОД:     DI      = НОМЕР ДИСКОВОДА                                 :
;               SI-HI   = НОМР ГОЛОВКИ                                    :
;               SI-LOW  = КОЛИЧЕСТВО ЧИТАЕМЫХ СЕКТОРОВ                    :
;               ES      = БУФФЕРНЫЙ СЕГМЕНТ                               :
;               [BP]    = НОМЕР СЕКТОРА                                   :
;               [BP+1]  = НОМЕР ДОРОЖКИ                                   :
;               [BP+2]  = СМЕЩЕНИЕ БУФЕРА                                 :
;               DISK_POINTER УКАЗЫВАЕТ НА ТАБЛИЦУ ПАРАМЕТРОВ ЭТОГО        :
;                               ДИСКОВОДА                                 :
;                                                                         :
;   ВЫХОД:      DSKETTE_STATUS,CY СТАТУС ОПЕРАЦИИ                         :
;--------------------------------------------------------------------------
DISK_FORMAT    PROC NEAR
        CALL    XLAT_NEW                ; ПЕРЕДАЧА СОСТОЯНИЯ ДЛЯ АППОРАТНОЙ СОВМЕСТИМОСТИ
        CALL    FMT_INIT                ; УСТАНОВКА СОСТОЯНИЯ, ЕСЛИ НЕОПРЕДЕЛЕНО
        OR      MOTOR_STATUS,10000000B  ; ИНДИКАЦИЯ ОПЕРАЦИИ ЗАПИСИ
        CALL    MED_CHANGE              ; ПРОВЕРКА СМЕНЫ НОСИТЕЛЯ
        JC      FM_DON                  ; НЕ МЕНЯЛИ, ПРОПУСК ПРОВЕРОК
        CALL    SEND_SPEC               ; СПЕЦИАЛЬНАЯ КОМАНДА  NEC
        CALL    CHK_LASTRATE            ; ZF=1 ПРОВЕРКА, СКОРОСТЬ ТА ЖЕ ?
        JZ      FM_WR                   ; ДА, ПРОПУСК СПЕЦИАЛЬНОЙ КОМАНДЫ
        CALL    SEND_RATE               ; УСТАНОВКА СКОРОСТИ ВРАЩЕНИЯ
FM_WR:
        CALL    FMTDMA_SET              ; УСТАНОВКА DMA ДЛЯ ФОРМАТИРОВАНИЯ
        JC      FM_DON                  ; ВОЗВРАТ С ОШИБКОЙ
        MOV     AH,4DH                  ; УСТАНОВКА КОМАНДЫ ФОРМАТИРОВАНИЯ
        CALL    NEC_INIT                ; ИНИЦИАЛИЗАЦИЯ NEC
        JC      FM_DON                  ; ОШИБКА - ВЫХОД
        MOV     AX,OFFSET FM_DON        ; ЗАГРУЗКА АДРЕСА ОШИБКИ
        PUSH    AX                      ; PUSH NEC_OUT ОШИБКИ
        MOV     DL,3                    ; BYTES/SECTOR ЗНАЧЕНИЕ ДЛЯ NEC
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
        POP     AX                      ; ВОЗВРАЩЕНИЕ ОШИБКИ
        CALL    NEC_TERM                ; ЗАВЕРШЕНИЕ И ПОЛУЧЕНИЕ СТАТУСА
FM_DON:
        CALL    XLAT_OLD                ; ПЕРЕДАЧА СОСТОЯНИЯ ДЛЯ СОВМЕСТИМОЙ МОДЕЛИ
        CALL    SETUP_END               ; ОЧИСТКА
        MOV     BX,SI
        MOV     AL,BL
        RET
DISK_FORMAT     ENDP
;--------------------------------------------------------------------------
; FNC_ERR                                                                 :
;       НЕПРАВИЛЬНАЯ ФУНКЦИЯ ИЛИ НЕПРАВИЛЬНЫЙ ДИСКОВОД                    :
;       УСТАНОВКА НЕПРАВИЛЬНОЙ КОМАНДЫ В СТАТУСЕ                          :
;                                                                         :
;   ВЫХОД:      DSKETTE_STATUS,CY СТАТУС ОПЕРАЦИИ                         :
;--------------------------------------------------------------------------
FNC_ERR          PROC    NEAR
        MOV     AX,SI
        MOV     AH,BAD_CMD
        MOV     DISKETTE_STATUS,AH
        STC                             ; УСТАНОВКА ФЛАГА ОШИБКИ
        RET
FNC_ERR          ENDP
;----------------------------------------------------------------
; DISK_PARMS  (AH=08H)                                           :
;       ЧТЕНИЕ ПАРАМЕТРОВ ДИСКОВОДА                              :
;     ВХОД:                                                      :
;       DI = НОМЕР ДИСКОВОДА                                     :
;   ВЫХОД:                                                       :
;       CL/[BP]  = БИТЫ 7&6 СТАРШИЕ 2 БИТА МАКС. ЧИСЛО ЦИЛИНДРОВ :
;                  БИТЫ 0-5 МАКС СЕКТОР/ТРЕК                     :
;       CH/[BP+1]= МЛ. 8 БИТ МАКС. ЧИСЛА ЦИЛИНДРОВ               :
;       BL/[BP+2]= БИТЫ 7-4 = 0                                  :
;                  БИТЫ 3-0 = ТИП ДИСКОВОДА ИЗ КМОП              :
;       BH/[BP+3]= 0                                             :
;       DL/[BP+4]= К-ВО ПОДКЛЮЧЕННЫХ ДИСКОВОДОВ                  :
;       DH/[BP+5]= МАКСИМАЛЬНОЕ ЧИСЛО ГОЛОВОК                    :
;       DI/[BP+6]= СМЕЩЕНИЕ ТАБЛИЦЫ НОСИТЕЛЬ/ДИСКОВОД            :
;       ES       = СЕГМЕНТ ТАБЛИЦЫ                               :
;       AX       = 0                                             :
; NOTE  : ЗАМЕТИМ, ЧТО ИНФОРМАЦИЮ ПОЛЬЗОВАТЕЛЬ МОЖЕТ ИЗВЛЕЧ ИЗ   :
;         СТЕКА В НЕОБХОДИМЫЕ ЕМУ РЕГИСТРЫ, ПОСЛЕ ВОЗВРАТА ИЗ    :
;         ПРОЦЕДУРЫ                                              :
;----------------------------------------------------------------
DISK_PARMS          PROC    NEAR
        CALL    XLAT_NEW                ; СОСТОЯНИЕ ПОДКЛЮЧЕННОГО АДАПТЕРА
        MOV     WORD PTR [BP+2],0       ; ТИП ДИСКОВОДА = 0
        MOV     AX,EQUIP_FLAG           ; ЧТЕНИЕ СЛОВА ОБОРУДОВАНИЯ ДЛЯ ОПРЕДЕ
        AND     AL,11000001B            ; ЛЕНИЯ ЧИСЛА ДИСКОВОДОВ
        MOV     DL,2                    ; ДИСКОВОДЫ = 2
        CMP     AL,01000001B            ; ПОДКЛЮЧЕНО 2 ?
        JZ      STO_DL                  ; ПЕРЕХОД ЕСЛИ ДА
        DEC     DL                      ; ДИСКОВОД =1
        CMP     AL,00000001B            ; ПОДКЛЮЧЕН 1?
        JNZ     NON_DRV                 ; ПЕРЕХОД ЕСЛИ НЕ ОДНОГО
STO_DL:
        MOV     [BP+4],DL               ; ВОССТАНОВЛЕНИЕ ЧИСЛА ДИСКОВОДОВ
        CMP     DI,1                    ; ПРОВЕРКА ПРАВИЛЬНОСТИ НОМЕРА ДИСКОВОДА
        JA      NON_DRV1                ; НЕПРАВИЛЬНО
        MOV     BYTE PTR[BP+5],1        ; МАКСИМАЛЬНОЕ ЧИСЛО ГОЛОВОК = 1
        CALL    CMOS_TYPE               ; ТИП ДИСКОВОДА В AL
        JC      CHK_EST                 ; ОШИБКА КМОП
        OR      AL,AL                   ; ТЕСТ ОТСУТСТВИЯ ДИСКОВОДА
        JZ      CHK_EST                 ; ПЕРЕХОД ЕСЛИ ОТСУТСТВУЕТ
        CALL    DR_TYPE_CHECK           ; ПОЛУЧЕНИЕ SEG:OFFSET ТАБЛИЦЫ НОС/ДИСК.
        JC      CHK_EST                 ; JMP ЕСЛИ НЕСООТВЕТСТВИЕ ТИПА
        MOV     [BP+2],AL               ; ВОССТАНОВЛЕНИЕ ТИПА ИЗ КМОП
        MOV     CL,CS:[BX].MD_SEC_TRK   ; ПОЛУЧЕНИЕ СЕКТОР/ДОРОЖКА
        MOV     CH,CS:[BX].MD_MAX_TRK   ; ПОЛУЧЕНИЕ МАКСИМАЛЬНОГО ЧИСЛА СЕКТОРОВ
        JMP     SHORT STO_CX            ; КМОП ПРАВИЛЬ.,ИСПОЛЬЗУЕМ КМОП
CHK_EST:
        MOV     AH,DSK_STATE[DI]        ; ЗАГРУЗКА СОСТОЯНИЯ ЭТОГО ДИСКОВОДА
        TEST    AH,MED_DET              ; ПРОВЕРКА УСТАНОВКИ СОСТОЯНИЯ
        JZ      NON_DRV1                ; ОШИБКА КМОП

USE_EST:
        AND     AH,RATE_MSK             ; ВЫДЕЛЕНИЕ СКОРОСТИ
        CMP     AH,RATE_250             ; СКОРОСТЬ ? 250
        JNE     USE_EST2                ; НЕТ, ПРОВЕРКА ДРУГИХ СКОРОСТЕЙ

;----СКОРОСТЬ 250 KBS, ПРОВЕРКА ТАБЛИЦЫ 360 KB
        MOV     AL,01                   ; ТИП ДИСКОВОДА 1 (360KB)
        CALL    DR_TYPE_CHECK           ; ПОЛУЧЕНИЕ CX:BX = ТАБЛИЦЫ ПАРАМЕТРОВ
        MOV     CL,CS:[BX].MD_SEC_TRK   ; ПОЛУЧЕНИЕ СЕКТОР/ДОР.
        MOV     CH,CS:[BX].MD_MAX_TRK   ; МАКСИМ. ЧИСЛО СЕКТОРОВ
        TEST    DSK_STATE[DI],TRK_CAPA  ; 80 ДОР. ?
        JZ      STO_CX                  ; ДОЛЖЕН БЫТЬ 360KB ДИСКОВОД

; ---ЕСЛИ ЭТО 1.44 ДИСКОВОД

PARM144:
        MOV     AL,04                   ; ТИП 4 (1.44MB)
        CALL    DR_TYPE_CHECK           ; ПОЛУЧЕНИЕ CX:BX = ТАБЛИЦЫ ПАРАМЕТРОВ
        MOV     CL,CS:[BX].MD_SEC_TRK   ; ПОЛУЧЕНИЕ СЕКТОР/ДОР.
        MOV     CH,CS:[BX].MD_MAX_TRK   ; МАКСИМ. ЧИСЛО СЕКТОРОВ
STO_CX:
        MOV     [BP],CX                 ; ЗАПИСЬ В СТЕК ДЛЯ ВОЗВРАТА
        MOV     [BP+6],BX               ; АДРЕС ТАБЛИЦЫ
        MOV     AX,CS                   ; СЕГМЕНТ ТАБЛИЦЫ
        MOV     ES,AX                   ; ES СЕГМЕНТ
DP_OUT:
        CALL    XLAT_OLD                ; ДЛЯ СОВМЕСТИМОСТИ
        XOR     AX,AX                   ; ОЧИСТКА
        CLC
        RET

;-------- ОТРАБОТКА ОТСУТСТВИЯ ДИСКОВОДА

NON_DRV:
        MOV     BYTE PTR [BP+4],0       ; ОЧИСТКА ЧИСЛА ДИСКОВОДОВ
NON_DRV1:
        CMP     DI,80H                  ; ПРОВЕРКА ЗАПРОСА ЖЕСТКОГО ДИСКА
        JB      NON_DRV2                ; ПРОДОЛЖЕНИЕ ЕСЛИ НЕ ЖЕСТКИЙ

;--------ЖЕСТКИЙ ДИСК, ОШИБКА ЗАПРОСА

        CALL    XLAT_OLD                ; ЕЩЕ ДЛЯ СОВМЕСТИМОСТИ
        MOV     AX,SI                   ; ВОССТАНОВЛЕНИЕ AL
        MOV     AH,BAD_CMD              ; УСТАНОВКА ОШИБКИ - НЕПРАВИЛЬНАЯ КОМАНДА
        STC                             ; УСТАНОВКА ОШИБКИ
        RET

NON_DRV2:
        XOR     AX,AX                ; ОЧИСТКА ПАРАМЕТРОВ ЕСЛИ НЕТ ДИСКОВОДА
				     ; ИЛИ ОШИБКА КМОП
        MOV     [BP],AX              ; ДОРОЖЕК, СЕКТОР/ДОРОЖ = 0
        MOV     [BP+5],AH            ; ГОЛ. = 0
        MOV     [BP+6],AX            ; СМЕЩЕНИЕ DISK_BASE = 0
        MOV     ES,AX                ; СЕГМЕНТ
        JMP     SHORT DP_OUT

;------- СКОРОСТЬ ВРАЩЕНИЯ 300KBS ИЛИ 500 KBS,ПОПЫТКА ТАБЛИЦЫ 1.2 MB

USE_EST2:
        MOV     AL,02                   ; ТИП ДИСКОВ. 1 (1.2MB)
        CALL    DR_TYPE_CHECK           ; АЛР CX:BX = НОСИТ/ДИСКОВОД ТАБЛИЦЫ
        MOV     CL,CS:[BX].MD_SEC_TRK   ; ПОЛУЧЕНИЕ СЕКТОР/ДОР.
        MOV     CH,CS:[BX].MD_MAX_TRK   ; МАКС. ЧИСЛО ДОРОЖЕК
        CMP     AH,RATE_300             ; СКОР 300 ?
        JE      STO_CX                  ; ДОЛЖЕН БЫТЬ 1.2MB ДИСКОВОД
        JMP     SHORT PARM144           ; ЕЩЕ МОЖЕТ БЫТЬ 1.44MB ДИСКОВОД

DISK_PARMS          ENDP

;-----------------------------------------------------------------
;  DISK_TYPE    (AH=15H)                                         :
;       ЭТА ПРОЦЕДУРА ВОЗВРАЩАЕТ ТИП ДИСКОВОДА                   :
;       ВХОД:   DI = НОМЕР ДИСКОВОДА                             :
;                                                                :
;     ВЫХОД:    AH = ТИП ДИСКОВОДА, CY=0                         :
;-----------------------------------------------------------------
DISK_TYPE          PROC    NEAR
        CALL    XLAT_NEW                ; ДЛЯ СОВМЕСТИМОСТИ
        MOV     AL,DSK_STATE[DI]        ; ПОЛУЧЕНИЕ СОСТОЯНИЯ
        OR      AL,AL                   ; ПРОВЕРКА НАЛИЧИЯ ДИСКОВОДА
        JZ      NO_DRV
        MOV     AH,NOCHGLN              ; НЕТ ЛИНИИ СМЕНЫ ДИСКА ДЛЯ 40 ДОРОЖ.ДИС.
        TEST    AL,TRK_CAPA             ; ИЛИ ЭТО 80 ТРЕКОВЫЙ?
        JZ      DT_BACK                 ; ЕСЛИ НЕТ JUMP
        MOV     AH,CHGLN

DT_BACK:
        PUSH    AX                      ; ЗАПИСЬ ВОЗВРАЩАЕМОГО ЗНАЧЕНИЯ
        CALL    XLAT_OLD                ; ДЛЯ СОВМЕСТИМОСТИ
        POP     AX                      ; ВОССТАНОВЛЕНИЕ ВОЗВРАЩАЕМЫХ ЗНАЧЕНИЙ
        CLC                             ; НЕТ ОШИБКИ
        MOV     BX,SI                   ;
        MOV     AL,BL                   ;
        RET

NO_DRV:
        XOR     AH,AH                   ; НЕТ ДИСКОВОДА ИЛИ НЕОПРЕДЕЛЕННЫЙ ТИП
        JMP     SHORT DT_BACK
DISK_TYPE          ENDP
;-----------------------------------------------------------------
;  DISK_CHANGE  (AH=16H)                                         :
;       ЭТА ПРОЦЕДУРА ВОЗВРАЩАЕТ СОСТОЯНИЕ ЛИНИИ СМЕНЫ ДИСКА     :
;                                                                :
;      ВХОД:    DI = НОМЕР ДИСКОВОДА                             :
;                                                                :
;    ВЫХОД:     AH = DSCETTE_STATUS                              :
;                    00 - ЛИНИЯ НЕАКТИВНА, CY = 0                :
;                    06 - ЛИНИЯ АКТИВНА  , CY = 1                :
;-----------------------------------------------------------------
DISK_CHANGE          PROC    NEAR
	not	uppp
        CALL    XLAT_NEW                ; ДЛЯ СОВМЕСТИМОСТИ
        MOV     AL,DSK_STATE[DI]        ; ПОЛУЧЕНИЕ ИНФОРМАЦИИ
        OR      AL,AL                   ; ДИСКОВОД ПРИСУТСТВУЕТ?
        JZ      DC_NON                  ; ПЕРЕХОД ЕСЛИ НЕТ
        TEST    AL,TRK_CAPA             ; 80 ДОРОЖЕЧНЫЙ ?
        JZ      SETIT                   ; ЕСЛИ ТАК, ПРОВЕРКА ЛИНИИ СМЕНЫ ДИСКА

DCO:    CALL    READ_DSKCHNG            ; ПОЛУЧЕНИЕ СОСТОЯНИЯ ЛИНИИ
        JZ      FINIS                   ; ЛИНИЯ НЕАКТИВНА

SETIT:  MOV     DISKETTE_STATUS,MEDIA_CHANGE    ; ИНДИКАЦИЯ СМЕНЫ

FINIS:  CALL    XLAT_OLD                ; ДЛЯ СОВМЕСТИМОСТИ
        CALL    SETUP_END               ; ОЧИСТКА
        MOV     BX,SI
        MOV     AL,BL
        RET

DC_NON:
        OR      DISKETTE_STATUS,TIME_OUT        ; УСТАНОВКА TIMEOUT,НЕТ ДИСКОВОДА
        JMP     SHORT FINIS
DISK_CHANGE     ENDP

;----------------------------------------------------------------
;  FORMAT_SET   (AH=17H)                                         :
;       ЭТА ПРОЦЕДУРА ИСПОЛЬЗУЕТСЯ ДЛЯ ОПРЕДЕЛЕНИЯ ТИПА          :
;       НОСИТЕЛЯ ПРИ ОПЕРАЦИИ ФОРМАТИРОВАНИЯ                     :
;                                                                :
;      ВХОД:    SI МЛ. = ТИП ФОРМАТА                             :
;               DI     = НОМЕР ДИСКОВОДА                         :
;                                                                :
;    ВЫХОД:     DSKETTE_STATUS ОТРАЖАЕТ СТАТУС ОПЕРАЦИИ          :
;               AH = DSKETTE_STATUS                              :
;               CY = 1 ЕСЛИ ОШИБКА                               ;
;-----------------------------------------------------------------
FORMAT_SET          PROC    NEAR
        CALL    XLAT_NEW                ; ДЛЯ СОВМЕСТИМОСТИ
        PUSH    SI                      ; ЗАПИСЬ ТИП НОСИТЕЛЯ
        MOV     AX,SI                   ; AH = ? , AL = ТИП НОСИТЕЛЯ
        XOR     AH,AH                   ; AH = 0 , AL = ТИП НОСИТЕЛЯ
        MOV     SI,AX                   ; SI = ТИП НОСИТЕЛЯ
        AND     DSK_STATE[DI],NOT MED_DET+DBL_STEP+RATE_MSK     ; ОЧИСТКА СОСТ.
        DEC     SI                      ; ПРОВ.ДЛЯ 320/360K НОСИТЕЛЯ
        JNZ     NOT_320                 ; ОБХОД ЕСЛИ НЕТ
        OR      DSK_STATE[DI],MED_DET+RATE_250          ; УСТАНОВКА 320/360
        JMP     SHORT SO
NOT_320:
        CALL    MED_CHANGE              ; ПРОВ. ДЛЯ TIME_OUT
        CMP     DISKETTE_STATUS,TIME_OUT
        JZ      SO                      ; ЕСЛИ ВРЕМЯ ВЫШЛО ВЫХОД

ss3:     DEC     SI                     ; ПРОВЕРКА ДЛЯ 320/360K В 1.2
        JNZ     NOT_320_12              ; ОБХОД ЕСЛИ НЕТ
        OR      DSK_STATE[DI],MED_DET+DBL_STEP+RATE_300  ; УСТАНОВКА СОСТОЯНИЯ
        JMP     SHORT SO
NOT_320_12:
        DEC     SI                      ; ПРОВЕРКА ДЛЯ 1.2M ДИСКУЕ.В 1.2M ДИСКОВ.
        JNZ     NOT_12                  ; ОБХОД ЕСЛИ НЕТ
        OR      DSK_STATE[DI],MED_DET+RATE_500  ; УСТАНОВКА ПЕРЕМЕННОГО СОСТОЯНИЯ
        JMP     SHORT SO                ; ВОЗВРАТ
NOT_12:
        DEC     SI                      ; ПРОВЕРКА 4 ТИПА НОСИТЕЛЯ
        JNZ     FS_ERR                  ; НЕПРАВИЛЬНАЯ КОМАНДА,НОСИТ. ВЫХОД

        TEST    DSK_STATE[DI],DRV_DET   ; ДИСКОВОД ОПРЕДЕЛ.?
        JZ      ASSUM                   ; ЕСЛИ НЕОПРЕДЕЛЕН, ТО ПРЕДПОЛОГАЕМ
					; МЕДЛЕННЫЙ
        MOV     AL,MED_DET+RATE_300
        TEST    DSK_STATE[DI],FMT_CAPA  ; ВОЗМОЖНОСТЬ МНОГОФОРМАТНОГО ?
        JNZ     OR_IT_IN                ; ЕСЛИ 1.2M ТОГДА СКОРОСТЬ 300
ASSUM:
        MOV     AL,MED_DET+RATE_250    ; УСТАНОВКА
OR_IT_IN:
        OR      DSK_STATE[DI],AL        ; OR ПРИ КОРРЕКТНОМ СОСТОЯНИИ
SO:
        CALL    XLAT_OLD                ; ДЛЯ СОВМЕСТИМОСТИ
        CALL    SETUP_END               ; ОЧИСТКА
        POP     BX
        MOV     AL,BL
        RET
FS_ERR:
        MOV     DISKETTE_STATUS,BAD_CMD  ; НЕОПРЕДЕЛЕННОЕ СОСТОЯНИЕ, НЕПРАВ.КОМАНДА
        JMP     SHORT SO                ;
FORMAT_SET          ENDP

; ----------------------------------------------------------------
;  SET_MEDIA    (AH=18)                                          :
;       ЭТА ПРОЦЕДУРА УСТАНАВЛИВАЕТ ТИП НОСИТЕЛЯ И СКОРОСТЬ      :
;       ВРАЩЕНИЯ ИСПОЛЬЗУЕМЫЕ ПРИ ФОРМАТИРОВАНИИ                 :
;      ВХОД:                                                     :
;       [BP]   = СЕКТОРОВ НА ТРЕК                                :
;       [BP+1] = НОМЕР ТРЕКА                                     :
;       DI     = НОМЕР ДИСКОВОДА                                 :
;    ВЫХОД:                                                      :
;       DSKETTE_STATUS ОТРАЖАЕТ СТАТУС                           :
;       ЕСЛИ НЕТ ОШИБКИ:                                         :
;               AH = 0                                           :
;               CY = 0                                           :
;               ES = СЕГМЕНТ ТАБЛИЦЫ НОСИТЕЛЬ/ДИСКОВОД           :
;               DI/[BP+6] = СМЕЩЕНИЕ                             :
;      ЕСЛИ ОШИБКА:                                              :
;               AH = DSKETTE_STATUS                              :
;               CY = 1                                           :
;-----------------------------------------------------------------
SET_MEDIA          PROC    NEAR
        CALL    XLAT_NEW                ; ДЛЯ СОВМЕСТИМОСТИ
        TEST    DSK_STATE[DI],TRK_CAPA  ; ПРОВЕРКА НАЛИЧИЯ ЛИНИИ СМЕНЫ ДИСКА
        JZ      SM_CMOS                 ; JUMP ЕСЛИ 40 ДОРОЖЕЧНЫЙ
        CALL    MED_CHANGE              ; ПРОВЕРКА ВРЕМЕНИ
        CMP     DISKETTE_STATUS,TIME_OUT   ; ВЫХОД ЕСЛИ ВРЕМЯ ВЫШЛО
        JE      SM_RTN
        MOV     DISKETTE_STATUS,0        ; ОЧИСТКА СТАТУСА
SM_CMOS:
        CALL    CMOS_TYPE               ; ТИП ДИСКОВОДА В (AL)
        JC      MD_NOT_FND              ; ОШИБКА КМОП
        OR      AL,AL                   ; ТЕСТ НАЛИЧИЯ ДМСКОВОДА
        JZ      SM_RTN                  ; ВЫХОД ЕСЛИ НЕТ
        CALL    DR_TYPE_CHECK           ; АДР CX:BX = ТАБЛИЦЫ НОСИТЕЛЬ/ДИСКОВОД
        JC      MD_NOT_FND              ; ТИП В ТАБЛИЦЕ НЕОПРЕДЕЛЕН, ОШИБКА КМОП
        PUSH    DI
        XOR     BX,BX                   ; BX = ИНДЕКС DRV_TYPE ТАБЛИЦЫ
        MOV     CX,6                    ; CX = СЧЕТЧИК ПОВТОРЕНИЙ

DR_SEARCH:
        MOV     AH,CS:DR_TYPE[BX]       ; ПОЛУЧЕНИЕ ТИПА ДИСКОВОДА(F000:20E9=1)
        AND     AH,BIT7OFF              ; МАСКА
        CMP     AL,AH                   ; СРАВНЕНИЕ ТИПА ДИСКОВОДА ?
        JNE     NXT_MD                  ; НЕТ, ПРОВЕРКА ПОСЛЕДНЕГО ТИПА ДИСКОВОДА

        MOV     DI,CS:WORD PTR DR_TYPE[BX+1]    ; DI=НОСИТЕЛЬ/ДИСКОВОД
        MOV     AH,CS:[DI].MD_SEC_TRK   ; ПОЛУЧЕНИЕ СЕКТОР/ДОРОЖ.
        CMP     [BP],AH                 ; СРАВНЕНИЕ ?
        JNE     NXT_MD                  ; НЕТ, ПРОВЕРКА СЛЕД.НОСИТЕЛЯ
        MOV     AH,CS:[DI].MD_MAX_TRK   ; ПРОВЕРКА МАКС. ЧИСЛА ДОРОЖЕК
        CMP     [BP+1],AH               ; СРАВ. ?
        JE      MD_FND                  ; ДА, ПОЛУЧЕНИЕ СКОРОСТИ ВРАЩЕНИЯ
NXT_MD:
        ADD     BX,3                    ; ПРОВЕРКА СЛЕДУЮЩЕГО ТИПА ДИСКОВОДА
        LOOP    DR_SEARCH
        POP     DI                      ; ВОССТАНОВЛЕНИЕ
MD_NOT_FND:
        MOV     DISKETTE_STATUS,MED_NOT_FND  ; ОШИБКА, ДИСКЕТА ДАННОГО ТИПА НЕ НАЙДЕНА
        JMP     SHORT SM_RTN                 ; ВЫХОД
MD_FND:
        MOV     AL,CS:[DI].MD_RATE      ; ПОЛУЧЕНИЕ СКОРОСТИ
        CMP     AL,RATE_300             ; ДВОЙНОЙ ШАГ ДЛЯ СКОРОСТИ 300
        JNE     MD_SET
        OR      AL,DBL_STEP
MD_SET:
        MOV     [BP+6],DI               ; ЗАПИСЬ ТАБЛИЦЫ УКАЗАТЕЛЕЙ В СТЕК
        OR      AL,MED_DET              ; УСТАНОВКА "МЕШАНИНЫ"
        POP     DI                      ; ВОССТАНОВЛЕНИЕ РЕГИСТРОВ
        AND     DSK_STATE[DI],NOT MED_DET+DBL_STEP+RATE_MSK  ; ОЧИСТКА СОСТОЯНИЯ
        OR      DSK_STATE[DI],AL        ; УСТАНОВКА СОСТОЯНИЯ
        MOV     AX,CS                   ; СЕГМЕНТ НОСИТЕЛЬ/ДИСКОВОД
        MOV     ES,AX                   ; ES СЕГМЕНТ
SM_RTN:
        CALL    XLAT_OLD
        CALL    SETUP_END
        RET
SET_MEDIA          ENDP

; ----------------------------------------------------------------
;  DR_TYPE_CHECK                                                 :
;       ПРОВЕРКА СООТВЕТСТВИЯ ТИПА ДИСКОВОДА В  (AL)             :
;       ТАБЛИЦАМ ХРАНЯЩИМСЯ В BIOS                               :
;      ВХОД:                                                     :
;       AL = ТИП ДИСКОВОДА                                       :
;    ВЫХОД:                                                      :
;       CS = СЕГМЕНТ ТАБЛИЦЫ НОСИТЕЛЬ/ДИСКОВОД                   :
;       CY = 0 ДАННЫЙ ТИП ДИСКОВОДА ПОДДЕРЖИВАЕТСЯ               :
;               BX = СМЕЩЕНИЕ ТАБЛИЦЫ                            :
;       CY = 1  ТИП ДИСКОВОДА НЕПОДДЕРЖИВАЕТСЯ                   :
;  РАЗРУШЕН:  BX                                                 :
;-----------------------------------------------------------------
DR_TYPE_CHECK          PROC    NEAR
        PUSH    AX
        PUSH    CX
        XOR     BX,BX                   ; BX = ИНДЕКС В DR_TYPE ТАБЛИЦЕ
        MOV     CX,DR_CNT               ; CX = СЧЕТЧИК ПОВТОРЕНИЙ

TYPE_CHK:
        MOV     AH,CS:DR_TYPE[BX]       ; ПОЛУЧЕНИЕ ТИПА ДИСКОВОДА (F000:20E9=1)
        CMP     AL,AH                   ; СРАВНЕНИЕ ТИПА ИЗ КМОП И ТАБЛИЧНОГО
        JE      DR_TYPE_VALID           ; ДА, ВЫХОД С СБРОШЕННЫМ ФЛАГОМ
        ADD     BX,3                    ; ПРОВЕРКА СЛЕДУЮЩЕГО ТИПА ДИСКОВОДА
        LOOP    TYPE_CHK
        STC                             ; ДАННЫЙ ТИП ДИСКОВОДА НЕ НАЙДЕН В ТАБ.
        JMP     SHORT TYPE_RTN
DR_TYPE_VALID:
        MOV     BX,CS:WORD PTR DR_TYPE[BX+1]    ; BX = СМЕЩЕНИЕ ТАБЛИЦЫ НОСИТ/ДИС.
TYPE_RTN:
        POP     CX
        POP     AX
        RET
DR_TYPE_CHECK          ENDP

; ----------------------------------------------------------------
;  SEND_SPEC                                                        :
;       ПОСЫЛАЕТ СПЕЦИАЛЬНУЮ КОМАНДУ В КОНТРОЛЛЕР ИСПОЛЬЗУЯ ДАН-    :
;       НЫЕ ИЗ ТАБЛИЦЫ ПАРАМЕТРОВ НА КОТОРЫЕ УКАЗЫВАЕТ DISK_POINTER :
;  ВХОД:    DISK_POINTER = ТАБЛИЦА ПАРАМЕТРОВ ДИСКОВОДА             :
;  ВЫХОД:     НЕТ                                                   :
;  ИЗМЕНЕНЫ:  CX,BX                                                 :
;-----------------------------------------------------------------
SEND_SPEC          PROC    NEAR
        PUSH    AX
        MOV     AX,OFFSET SPECBAC       ; ЗАГРУЗКА АДРЕСА ОШИБКИ
        PUSH    AX
        MOV     AH,03H                  ; СПЕЦИАЛЬНАЯ КОМАНДА
        CALL    NEC_OUTPUT              ; ПРОГРАМИРОВАНИЕ NEC
        SUB     DL,DL                   ; ПЕРВЫЙ БАЙТ ПАРАМЕТРОВ
        CALL    GET_PARM                ; ПОЛУЧЕНИЕ ПАРАМЕТРА В AH
        CALL    NEC_OUTPUT              ; ВЫВОД КОМАДЫ
        MOV     DL,1                    ; СЛЕДУЮЩИЙ БАЙТ     
        CALL    GET_PARM                ; ПОЛУЧЕНИЕ ПАРАМЕТРА В AH
        CALL    NEC_OUTPUT              ; ВЫВОД КОМАНДЫ     
        POP     AX                      
SPECBAC:
        POP     AX                      
        RET
SEND_SPEC          ENDP

; ----------------------------------------------------------------
;  SEND_SPEC_MD                                                  :
;       ПОСЫЛКА СПЕЦИАЛЬНОЙ КОМАНДЫ В КОНТРОЛЛЕР,ИСПОЛЬЗУЮЩЕЙ    :
;       ДАННЫЕ ИЗ ТАБЛИЦЫ НОСИТЕЛЬ/ДИСКОВОД С УКАЗ.(CX:BX)       :
;      ВХОД:    CX:BX = УКАЗАТЕЛЬНА ТАБЛИЦУ                      :
;    ВЫХОД:     НЕТ                                              :
;-----------------------------------------------------------------
SEND_SPEC_MD          PROC    NEAR
        PUSH    AX                      
        MOV     AX,OFFSET SPEC_ESBAC    ; ЗАГРУЗКА АДРЕСА ОШИБОК
        PUSH    AX                      ; СОХРАНЕНИЕ АДРЕСА        
        MOV     AH,03H                  ; СПЕЦИАЛЬНАЯ КОМАНДА
        CALL    NEC_OUTPUT              ; ВЫВОД КОМАНДЫ     
        MOV     AH,CS:[BX].MD_SPEC1     ; ПОЛУЧЕНИЕ ПЕРВОГО СПЕЦИАЛЬНОГО БАЙТА
        CALL    NEC_OUTPUT              ; ВЫВОД КОМАНДЫ     
        MOV     AH,CS:[BX].MD_SPEC2     ; ПОЛУЧЕНИЕ СПЕЦИАЛЬНОГО БАЙТА
        CALL    NEC_OUTPUT              ; ВЫВОД КОМАНДЫ     
        POP     AX                      
SPEC_ESBAC:
        POP     AX                      
        RET
SEND_SPEC_MD          ENDP              

; ----------------------------------------------------------------
;  XLAT_NEW                                                      :
;       ТРАНСЛИРУЕТ ОБЛАСТЬ ЛОКАЦИИ ДИСКЕТЫ ДЛЯ АППАРАТНОЙ       :
;       СОВМЕСТИМОСТИ                                            :
;      ВХОД:    DI:ДИСКОВОД                                      :
;-----------------------------------------------------------------

XLAT_NEW          PROC    NEAR
        CMP     DI,1                    ; ПРАВИЛЬНЫЙ НОМЕР ДИСКОВОДА ?
        JA      XN_OUT                  ; ОШИБОЧНЫЙ
        CMP     DSK_STATE[DI],0         ; ОПРЕДЕЛЕН ?
        JZ      DO_DET                  ; ЕСЛИ НЕТ ПОПЫТКА ОПРЕДЕЛЕНИЯ
        MOV     CX,DI                   ; CX = НОМЕР ДИСКОВОДА
        SHL     CL,1                    ; CL = СДВИГ  ,A=0,B=4
        SHL	CL,1
        MOV     AL,HF_CNTRL             ; ИНФОРМАЦИЯ О ДИСКОВОДЕ
        ROR     AL,CL                   ; ВЫДИЛЕНИЕ СООТВЕТСТВУЮЩЕГО НИБЛА
        AND     AL,DRV_DET+FMT_CAPA+TRK_CAPA    ; ВЫДЕЛЕНИЕ НЕОБХОДИМЫХ БИТ
        AND     DSK_STATE[DI],NOT DRV_DET+FMT_CAPA+TRK_CAPA
        OR      DSK_STATE[DI],AL        ; ИЗМЕНЕНИЕ СОСТОЯНИЯ ДИСКОВОДА
XN_OUT:
                RET
DO_DET:
                CALL    DRIVE_DET       ; ОПРЕДЕЛЕНИЕ ДИСКОВОДА
                RET
XLAT_NEW          ENDP

; ----------------------------------------------------------------
;  XLAT_OLD                                                      :
;       ПЕРЕДАЧА РАСПОЛОЖЕНИЯ ТАБЛИЦЫ НОСИТЕЛЬ/ДИСКОВОД          :
;       ИЗ ДРУГОЙ АРХИТЕКТУРЫ ДЛЯ ПОДДЕРЖАНИЯ СОВМЕСТИМОСТИ      :
;      ВХОД:    DI:ДИСКОВОД                                      :
;-----------------------------------------------------------------
XLAT_OLD          PROC    NEAR
        CMP     DI,1                    ; ПРАВИЛЬНОСТЬ НОМЕРА ДИСКОВОДА ?
        JA      XN_OUT                  ; ЕСЛИ НЕПРАВИЛЬНЫЙ
        CMP     DSK_STATE[DI],0         ; НЕТ ДИСКОВОДА ?
        JE      XN_OUT                  ; ЕСЛИ НЕТ

;-------   ТЕСТ ЕСЛИ ИНФОРМАЦИЯ О ДИСКОВОДЕ УЖЕ УСТАНОВЛЕНА

        MOV     CX,DI                   ; CX = НОМЕР ДИСКОВОДА
        SHL     CL,1                    ; CL = СДВИГ ,A=0,B=4
        SHL	CL,1
        MOV     AH,FMT_CAPA             ; ЗАГРУЗКА МАСКИ МНОГОФОРМАТНОГО ДИСКОВ.
        ROR     AH,CL                   ; ВРАЩЕНИЕ МАСКИ
        TEST    HF_CNTRL,AH             ; УСТАННОВЛЕН ЛИ РЕЖИМ МНОГОСКОРОСТ. ?
        JNZ     SAVE_SET                ; ЕСЛИ ДА, ТО НЕ НУЖДАЕТСЯ В ПЕРЕУСТАНОВКЕ

;-------  СТИРАТЬ БИТ ДИСКОВОДА В HF_CNTRL ДЛЯ ЭТОГО ДИСКОВОДА

        MOV     AH,DRV_DET+FMT_CAPA+TRK_CAPA    ; МАСКА
        ROR     AH,CL
        NOT     AH
        AND     HF_CNTRL,AH

;-------  ДОСТУП К ТЕКУЩЕМУ ДИСКОВОДУ И УСТАНОВКА В HF_CNTRL

        MOV     AL,DSK_STATE[DI]        ; ПОЛУЧЕНИЕ СОСТОЯНИЯ
        AND     AL,DRV_DET+FMT_CAPA+TRK_CAPA    ; ВЫДЕЛЕНИЕ БИТ ДИСКОВОДА
        ROR     AL,CL                   ; ДЛЯ ВЫБРАННОГО ДИСКОВОДА
        OR      HF_CNTRL,AL             ; ЗАПИСЬ ИЗМЕНЕННОГО СОСТОЯНИЯ

;------ПЕРЕДАЧА ДЛЯ СОВМЕСТИМОСТИ    

SAVE_SET:
        MOV     AH,DSK_STATE[DI]        ; ДОСТУП К СОСТОЯНИЮ
        MOV     BH,AH                   ; В BH ДЛЯ СРАВНЕНИЯ
        AND     AH,RATE_MSK             ; ВЫДЕЛЕНИЕ СКОРОСТИ
        CMP     AH,RATE_500             ; СКОР 500 ?
        JZ      CHK_144                 ; ДА 1.2/1.2 ИЛИ 1.44/1.44
        MOV     AL,M3D1U                ; AL =360 В 1.2 
        CMP     AH,RATE_300             ; СКОР 300 ?
        JNZ     CHK_250                 ; НЕТ,360/360,720/720 ИЛИ 720/1.44
        TEST    BH,DBL_STEP             ; ДА,ДВОЙНОЙ ШАГ ?
        JNZ     TST_DET                 ; ДА, ЭТО 360 В 1.2 
UNKNO:
        MOV     AL,MED_UNK              ; 'НИКТО НЕ БОЛЬШЕ'
        JMP     SHORT AL_SET            ; ПРОЦЕСС ЗАВЕРШЕН
CHK_144:
        CALL    CMOS_TYPE               ; ТИП ДИСКОВОДА В (AL)
        JC      UNKNO                   ; ОШИБКА УСТАНОВКА 'НЕ БОЛЬШЕ'
        CMP     AL,02                   ; 1.2MB ДИСКОВОД ?
        JNE     UNKNO                   ; НЕТ,УСТАНОВКА 'НИКТО НЕ БОЛЬШЕ'
        MOV     AL,M1D1U                ; AL = 1.2 В 1.2
        JMP     SHORT TST_DET
CHK_250:
        MOV     AL,M3D3U                ; AL = 360 В 360 
        CMP     AH,RATE_250             ; СКОР 250 ?
        JNE     UNKNO                   ; ЕСЛИ НЕТ
        TEST    BH,TRK_CAPA             ; 80 ТРЕКОВ  ?
        JNZ     UNKNO                   
TST_DET:
        TEST    BH,MED_DET              ; ОПРЕДЕЛЕН ?
        JZ      AL_SET                  ; ЕСЛИ НЕТ, ТОГДА УСТАНАВЛИВАЕМ
        ADD     AL,3                    ; ДЕЛАНМ ОПРЕДЕЛЕН/УСТАНОВЛЕН
AL_SET:
        AND     DSK_STATE[DI],NOT DRV_DET+FMT_CAPA+TRK_CAPA     ; ОЧИСТКА ДИСКОВОДА
        OR      DSK_STATE[DI],AL        ; КОПИРОВАНИЕ ДЛЯ СОВМЕСТИМОЙ МОДЕЛИ
XO_OUT:
        RET
XLAT_OLD          ENDP

; ----------------------------------------------------------------
;  RD_WR_VF                                                      :
;       ПРОЦЕДУРА ЧТЕНИЯ, ЗАПИСИ И ВЕРИФИКАЦИИ                   :
;       ОСНОВНОЙ ЦИКЛ ДЛЯ ПОВТОРЕНИЯ                             :
;      ВХОД:    AH : ПАРАМЕТРЫ NEC ДЛЯ ЧТЕНИЯ, ЗАПИСИ, ВЕРИФИК.  :
;               AL : ПАРАМЕТРЫ DMA ДЛЯ ЧТЕНИЯ, ЗАПИСИ, ВЕРИФИК.  :
;    ВЫХОД:     DSKETTE_STATUS, CY СТАТУС ОПЕРАЦИИ               :
;-----------------------------------------------------------------

RD_WR_VF          PROC    NEAR
        PUSH    AX                      ; СОХРАНЕНИЕ ПАРАМЕТРОВ DMA И NEC
        CALL    XLAT_NEW                ; ТРАНСЛИРУЕТ СОСТОЯНИЕ ПОДКЛЮЧ. ДИСК.
        CALL    SETUP_STATE             ; ИНИЦИАЛИЗИРУЕТ НАЧАЛЬНУЮ И КОНЕЧНУЮ
					; СКОРОСТЬ В СЛУЧАЕ НЕОПРЕДЕЛЕННОСТИ
					; ДИСКОВОДА И ТИПА НОСИТЕЛЯ
        POP     AX                      ; ВОССТАНОВЛЕНИЕ
DO_AGAIN:
        PUSH    AX                      ; СОХРАНЕНИЕ ПАРАМЕТРОВ DMA И NEC
        CALL    MED_CHANGE              ; ПРОВЕРКА СМЕНЫ ДИСКЕТЫ И СБРОСА

        POP     AX
        JNC     RWV
        JMP     RWV_END
RWV:
        PUSH    AX
        MOV     DH,DSK_STATE[DI]        ; ПОЛУЧЕНИЕ СКОРОСТИ
        AND     DH,RATE_MSK
        CALL    CMOS_TYPE               ; ТИП ДИСКОВОДА В (AL)
        JC      RWV_ASSUME              ; ОШИБКА В CMOS
        CMP     AL,1                    ; 40 ТРЕКОВЫЙ ДИСКОВОД ?
        JNE     RWV_1                   ; НЕТ, ОБХОД КОРРЕКТНОСТИ CMOS
        TEST    DSK_STATE[DI],TRK_CAPA  ; ПРОВЕРКА ДЛЯ 40 ТРЕКОВОГО ДИСКОВОДА
        JZ      RWV_2                   ; ДА, CMOS КОРРЕКТНО
        MOV     AL,2                    ; СМЕНА 1.2M
        JMP     SHORT RWV_2             ; ПРОДОЛЖЕНИЕ
RWV_1:
        JB      RWV_2                   ; ДИСКОВОД НЕ ОПРЕДЕЛЕН
        TEST    DSK_STATE[DI],1         ; ЕСЛИ ЭТО 40 ТРЕКОВЫЙ ?
        JNZ     RWV_2                   ; НЕТ 80 ТРЕКОВ
        MOV     AL,1                    ; ЕСЛИ 40 ТРЕКОВ, ТО ИСПРАВЛЕНИЕ CMOS
RWV_2:
        OR      AL,AL
        JZ      RWV_ASSUME              ; ПРЕДПОЛОГАЕМ МАКСИМАЛЬНОЕ К-ВО ДОРОЖЕК
        CALL    DR_TYPE_CHECK           ; CX:BX = ТАБЛИЦА ПАРАМЕТРОВ НОСИТЕЛЬ/ДИСКОВОД
        JC      RWV_ASSUME              ; ТИПА НЕТ В ТАБЛИЦЕ(ОШИБКА CMOS)

;------ ПОИСК ДЛЯ ТАБЛИЦЫ ПАРАМЕТРОВ НОСИТЕЛЬ/ДИСКОВОД

        PUSH    DI                      ; СОХРАНЕНИЕ НОМЕРА ДИСКОВОДА
        XOR     BX,BX                   ; BX = ИНДКС В DR_TYPE ТАБЛИЦЕ
        MOV     CX,DR_CNT               ; CX = СЧЕТЧИК ПОВТОРЕНИЙ
RWV_DR_SEARCH:
        MOV     AH,CS:DR_TYPE[BX]       ; ПОЛУЧЕНИЕ ТИПА ДИСКОВОДА
        AND     AH,BIT7OFF              ; МАСКА 7 БИТА
        CMP     AL,AH                   ; ТИП СОВПОДАЕТ ?
        JNE     RWV_NXT_MD              ; НЕТ ПРОВЕРКА СЛЕДУЮЩЕГО ТИПА
RWV_RR_FND:
        MOV     DI,WORD PTR CS:DR_TYPE[BX+1]    ; НОСИТЕЛЬ/ДИСКОВОД ТАБЛИЦА ПАРАМЕТРОВ
RWV_MD_SEARCH:
        CMP     DH,CS:[DI].MD_RATE      ; СОВПАДАЮТ ?
        JE      RWV_MD_FND              ; ДА, ПОЛУЧЕНИЕ ПЕРВОГО БАЙТА
RWV_NXT_MD:
        ADD     BX,3                    ; ПРОВЕРКА СЛЕДУЮЩЕГО ДИСКОВОДА
        LOOP    RWV_DR_SEARCH
        POP     DI                      ; ВОССТАНОВЛЕНИЕ НОМЕРА ДИСКОВОДА

;------- ПРЕДПОЛОГАЕМ ЧТО ПЕРВЫЙ ДИСКОВОД ВЕДУЩИЙ

RWV_ASSUME:
        MOV     BX,OFFSET MD_TBL1       ; УКАЗАТЕЛЬ НА 40 ДОР И СКОРОСТЬ 250
        TEST    DSK_STATE[DI],TRK_CAPA  ; ТЕСТ ДЛЯ 80 ДОРОЖЕК
        JZ      RWV_MD_FND1             ; МОЖЕТ БЫТЬ 40 ДОРОЖЕК
        MOV     BX,OFFSET MD_TBL3       ; УКАЗАТЕЛЬ НА 80 ТР 500 KBS
	JMP     short RWV_MD_FND1             ; ПОЛУЧЕНИЕ СПЕЦИАЛЬНЫХ ПАРАМЕТРОВ

;------- CS:BX УКАЗАТЕЛЬ НА ТАБЛИЦУ НОСИТЕЛЬ/ДИСКОВОД

RWV_MD_FND:
        MOV     BX,DI
	POP     DI                      ; ВОССТАНОВЛЕНИЕ НОМЕРА ДИСКОВОДА
RWV_MD_FND1:

;-------- ПОСЫЛКА СПЕЦИАЛЬНОЙ КОМАНДЫ В NEC КОНТРОЛЛЕР

        CALL    SEND_SPEC_MD
        CALL    CHK_LASTRATE            ; ZF = 1 ПОПЫТКА СКОРОСТИ КАК В ПОСЛ-
					; ЛЕДНЕЙ ОПЕРАЦИИ
        JZ      RWV_DBL                 ; ДА, ПРОПУСК КОМАНДЫ УСТАНОВКИ СКОРОСТИ
        CALL    SEND_RATE               ; УСТАНОВКА СКОРОСТИ ВРАЩЕНИЯ
RWV_DBL:
        PUSH    BX                      ; СОХРАНЕНИЕ АДРЕСА ТАБЛИЦЫ
        CALL    SETUP_DBL               ; ПРОВЕРКА ДЛЯ ДВОЙНОГО ШАГА
        POP     BX                      ; ВОССТАНОВЛЕНИЕ АДРЕСА
        JC      CHK_RET                 ; ОШИБКА ЧТЕНИЯ, ВОЗМОЖНО ПОВТОРЕНИЕ
        POP     AX                      ; ВОССТАНОВЛЕНИЕ NEC, DMA КОМАНД
        PUSH    AX                      ; СОХРАНЕНИЕ
        PUSH    BX
        CALL    DMA_SETUP               ; ПРОГРАМИРОВАНИЕ DMA
        POP     BX
        POP     AX                      ; ВОССТАНОВЛЕНИЕ NEC КОМАНДЫ
        JC      RWV_BAC                 ; ПРОВЕРКА ОШИБКИ DMA
        PUSH    AX                      ; СОХРАНЕНИЕ NEC КОМАНДЫ
        PUSH    BX                      ; СОХРАНЕНИЕ АДРЕСА
        CALL    NEC_INIT                ; ИНИЦИАЛИЗАЦИЯ NEC
        POP     BX                      ; ВОССТАНОВЛЕНИЕ АДРЕСА
        JC      CHK_RET                 ; ВЫХОД-ОШИБКА
        CALL    RWV_COM                 ; КОД ЧТЕНИЯ/ЗАПИСИ/ВЕРИФИКАЦИИ
        JC      CHK_RET                 ; ВЫХОД-ОШИБКА
        CALL    NEC_TERM                ; ЗАВЕРШЕНИЕ ПОЛУЧЕНИЕ СТАТУСА
CHK_RET:
        CALL    RETRY                   ; ПРОВЕРКА ДЛЯ ПОВТОРА
        POP     AX                      ; ВОССТАНОВЛЕНИЕ ПАРАМЕТРОВ ЧТ/ЗАП/ВЕР
        JNC     RWV_END                 ; CY = 0 НЕ ПОВТОРЯТЬ
        JMP     DO_AGAIN                ; CY = 1 ПОВТОРЯТЬ
RWV_END:
        CALL    DSTATE                  ; УСТАНОВКА СОСТОЯНИЯ, ЕСЛИ УСПЕХ
        CALL    NUM_TRANS               ; AL = ПЕРЕСЫЛАЕМОЕ ЧИСЛО
RWV_BAC:
        PUSH    AX                      ; СОХРАНЕНИЕ
        CALL    XLAT_OLD                ; ПЕРЕДАЧА ДЛЯ СОВМЕСТИМОСТИ
        POP     AX
        CALL    SETUP_END               ; ОЧИСТКА
        RET
RD_WR_VF          ENDP
;--------------------------------------------------------------------
;  SETUP_STATE:    ИИЦИАЛИЗАЦИЯ НАЧАЛЬНОЙ И КОНЕЧНОЙ СКОРОСТИ        :
;--------------------------------------------------------------------
SETUP_STATE          PROC    NEAR
        TEST    DSK_STATE[DI],MED_DET   ; ДИСКЕТА ОПРЕДЕЛЕНА ?
        JNZ     J1C                     ; ПРОПУСК, ЕСЛИ ОПРЕДЕЛЕНА
        MOV     AX,0040H                ; AH = СТАРТОВАЯ СКОРОСТЬ_500,
					; AL=КОНЕЧНАЯ СКОРОСТЬ_300
        TEST    DSK_STATE[DI],DRV_DET   ; ДИСКОВОД ОПРЕДЕЛЕН ?
        JZ      AX_SET                  ; НЕ НАДО ОПРЕДЕЛЯТЬ
        TEST    DSK_STATE[DI],FMT_CAPA  ; МНОГО-СКОРОСТНОЙ (1.2M) ?
        JNZ     AX_SET                  ; JUMP ЕСЛИ ДА
        MOV     AX,8080H                ; СТАРТОВАЯ СКОРОСТЬ = 250 ДЛЯ 360 ДИСКОВОДА
AX_SET:
        AND     DSK_STATE[DI],NOT RATE_MSK+DBL_STEP     ; ВЫКЛЮЧЕНИЕ БИТОВ СКОРОСТИ
        OR      DSK_STATE[DI],AH        ; УСТАНОВКА СКОРОСТИ 250
        AND     LASTRATE,NOT STRT_MSK   ; СТИРАНИЕ ПОСЛЕДНЕГО БИТА СКОРОСТИ
        PUSH    CX
        MOV	CL,4
        ROR     AL,CL
        POP	CX                      ; ПОСЛЕДНЯЯ СКОРОСТЬ
        OR      LASTRATE,AL
J1C:
        RET
SETUP_STATE          ENDP
;--------------------------------------------------------------------
;  FMT_INIT: УСТАНОВКА СОСТОЯНИЯ, ЕСЛИ ВРЕМЯ ФОРМАТИРОВАНИЯ НЕ УСТАНОВЛЕНО
;--------------------------------------------------------------------
FMT_INIT        PROC    NEAR
        TEST    DSK_STATE[DI],MED_DET   ; НОСИТЕЛЬ УСТАНОВЛЕН
        JNZ     FI_OUT                  ; ЕСЛИ ТАК - ВЫХОД
        CALL    CMOS_TYPE               ; ТИП ДИСКОВОДА В AL
        JC      CL_DRV                  ; ОШИБКА КМОП, ПРЕДПОЛОГАЕМ ОТСУТС-
					; ТВИЕ ДИСКОВОДА
        DEC     AL                      ; УСТАНОВКА НАЧАЛЬНОГО СОСТОЯНИЯ
        JS      CL_DRV                  ; НЕТ ДИСКОВОДА ЕСЛИ 0
        MOV     AH,DSK_STATE[DI]        ; AH = ТЕКУЩЕЕ СОСТОЯНИЕ
        AND     AH,NOT MED_DET+DBL_STEP+RATE_MSK        ; ОЧИСТКА
        OR      AL,AL                   ; ПРОВЕРКА ДЛЯ 360
        JNZ     N_360                   ; ЕСЛИ 360 ТО 0
        OR      AH,MED_DET+RATE_250     ; УСТАНОВКА НОСИТЕЛЯ
        JMP     SHORT SKP_STATE         ; ПРОПУСК ДРУГИХ ОБРАБОТОК
N_360:
        DEC     AL                      ; 1.2 M ДИСКОВОД
        JNZ     N_12                    ; JUMP ЕСЛИ НЕТ
FI_RATE:
        OR      AH,MED_DET+RATE_500     ; УСТАНОВКА СКОРОСТИ ФОРМАТИРОВАНИЯ
        JMP     SHORT SKP_STATE         ; ПРОПУС ДРУГИХ ОБРАБОТОК
N_12:
        DEC     AL                      ; ПРОВЕРКА 3 ТИПА
        JNZ     N_720                   ; JUMP ЕСЛИ НЕТ
        TEST    AH,DRV_DET              ; ДИСКОВОД ОПРЕДЕЛЕН
        JZ      ISNT_12                 ; ОБРАЩЕНИЕ КАК НЕ 1.2
        TEST    AH,FMT_CAPA             ; 1.2 M
        JZ      ISNT_12                 ; JUMP ЕСЛИ НЕТ
        OR      AH,MED_DET+RATE_300     ; 300
        JMP     SHORT SKP_STATE         ; ПРОДОЛЖЕНИЕ
N_720:
        DEC     AL                      ; ПРОВЕРКА ДЛЯ ТИПА 4
        JNZ     CL_DRV                  ; НЕТ ДИСКОВОДА, ОШИБКА КМОП
        JMP     SHORT FI_RATE
ISNT_12:
        OR      AH,MED_DET+RATE_250     ; СКОРОСТЬ 250
SKP_STATE:
        MOV     DSK_STATE[DI],AH        ; УСТАНОВКА
FI_OUT:
        RET
CL_DRV:
        XOR     AH,AH                   ; ОЧИСТКА СОСТОЯНИЯ
        JMP     SHORT SKP_STATE         ; ЗАПИСЬ ЕГО
FMT_INIT        ENDP
; ----------------------------------------------------------------
;  MED_CHANGE                                                    :
;       ПРОВЕРКА СМЕНЫ ДИСКЕТЫ, СБРОС ЛИНИИ СМЕНЫ ДИСКЕТЫ        :
;       И СНОВА ПРОВЕРКА СМЕНЫ                                   :
;                                                                :
;    ВЫХОД:     CY = 1 ДИСКЕТА СМЕНЕНА ИЛИ ВРЕМЯ ВЫШЛО           :
;               DSKETTE_STATUS = КОД ОШИБКИ                      :
;-----------------------------------------------------------------
MED_CHANGE          PROC    NEAR
        CALL    READ_DSKCHNG            ; ЧТЕНИЕ СОСТОЯНИЯ ЛИНИИ СМЕНЫ ДИСКЕТЫ
        JZ      MC_OUT                  ; ОБХОД ЕСЛИ НЕ СМЕНЕА
        AND     DSK_STATE[DI],NOT MED_DET       ; ОЧИСТКА СОСТОЯНИЯ ДЛЯ ЗАПРА-
						; ШИВАЕМОГО ДИСКОВОДА


        MOV     CX,DI                   ; CL = НОМЕР ДИСКОВОДА
        MOV     AL,1                    ; БИТ МАСКИ МОТОРА
        SHL     AL,CL                   ; СООТВЕТСТВУЮЩАЯ ПОЗИЦИЯ
        NOT     AL
        CLI                             ; ЗАПРЕТ ПРЕРЫВАНИЙ
        AND     MOTOR_STATUS,AL         ; ПОВОРОТ МОТОРА ДЛЯ ИНДИКАЦИИ
        STI                             ; РАЗРЕШЕНИЕ ПРЕРЫВАНИЙ
        CALL    MOTOR_ON                ; ПОВОРОТ МОТОРА

;--------  СБРОС СИГНАЛА

        CALL    DISK_RESET              ; СБРОС
        MOV     CH,01H                  ; ПЕРЕДВИЖЕНИЕ НА 1 ДОРОЖКУ
        CALL    SEEK                    ; ВЫПОЛНЕНИЕ ПЕРЕДВИЖЕНИЯ
        XOR     CH,CH                   ; ПЕРЕДВИЖЕНИЕ НА 0 ДОРОЖКУ
        CALL    SEEK                    ; ВЫПОЛНЕНИЕ ПЕРЕДВИЖЕНИЯ
        MOV     DISKETTE_STATUS,MEDIA_CHANGE    ; СОХРАНЕНИЕ В СТАТУСЕ

OK1:    CALL    READ_DSKCHNG            ; ПРОВЕРКА СМЕНЫ СНОВА
        JZ	MC_OUT                  ; ???
;        JZ      OK2                     ; IF ACTIVE, NO DISKETTE, TIMEOUT

OK4:    MOV     DISKETTE_STATUS,TIME_OUT  ; ВРЕМЯ ВЫШЛО ЕСЛИ ДИСКОВОД ПУСТ
OK2:
        STC                             ; СМЕНЕНА, УСТАНОВКА CY
        RET
MC_OUT:
        CLC                             ; НЕ СМЕНЕНА
        RET
MED_CHANGE          ENDP
; ----------------------------------------------------------------
;  SEND_RATE                                                     :
;       ПОСЫЛКА СКОРОСТИ ВРАЩЕНИЯ В NEC                          :
;      ВХОД:    DI = НОМЕР ДИСКОВОДА                             :
;    ВЫХОД:     НЕТ                                              :
;  ИЗМЕНЕН:     DX                                               :
;-----------------------------------------------------------------
SEND_RATE          PROC    NEAR

        PUSH    AX
        AND     LASTRATE,NOT SEND_MSK   ; ОЧИСТКА СКОРОСТИ ПОСЛЕДНЕГО ОБРАЩЕНИЯ
        MOV     AL,DSK_STATE[DI]        ; ПОЛУЧЕНИЕ СКОРОСТИ ДАННОГО ДИСКОВОДА
        AND     AL,SEND_MSK             ; ОСТАВИТЬТОЛЬКО БИТЫ СКОРОСТИ
        OR      LASTRATE,AL             ; СОХРАНЕНИЕ НОВОЙ СКОРОСТИ ДЛЯ СЛЕДУ-
					; ЮЩЕЙ ПРОВЕРКИ
        ROL     AL,1                    ; ПЕРЕДВИЖЕНИЕ БИТОВ В НУЖНУЮ ПОЗИЦИЮ
        ROL	AL,1
        MOV     DX,03F7H                ; УСТАНОВКА НОВОЙ СКОРОСТИ
        OUT     DX,AL
        POP     AX
        RET
SEND_RATE          ENDP

; ----------------------------------------------------------------
;  CHK_LASTRATE                                                  :
;       ПРОВЕРКА ПРЕДЫДУЩЕЙ СКОРОСТИ ВРАЩЕНИЯ                    :
;      ВХОД:                                                     :
;       DI = НОМЕР ДИСКОВОДА                                     :
;    ВЫХОД:                                                      :
;       ZF = 1 СКОРОСТЬ ТА ЖЕ, ЧТО И В ПРЕДЫДУЩЕЙ ОПЕРАЦИИ       :
;       ZF = 0 ДРУГАЯ                                            :
;  ИЗМЕНЕН:  BX                                                  :
;-----------------------------------------------------------------
CHK_LASTRATE          PROC    NEAR
        PUSH    AX
        MOV     AH,LASTRATE             ; ПОЛУЧЕНИЕ СКОРОСТИ ПРЕДЫДУЩЕЙ ОПЕРАЦИИ
        MOV     AL,DSK_STATE[DI]        ; ПОЛУЧЕНИЕ СКОРОСТИ ЭТОГО ДИСКОВОДА
        AND     AX,0C0C0H ;SEND_MSK*X   ; ТОЛЬКО БИТЫ СКОРОСТИ
        CMP     AL,AH                   ; СРАВНЕНИЕ С ПРЕДЫДУЩЕЙ
                                        ; ZF = 1 СКОРОСТЬ ТА ЖЕ
        POP     AX
        RET
CHK_LASTRATE          ENDP

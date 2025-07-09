//----------MOV
MOV R1, #7              ; R1 = 7 (0x7)
MOV R2, #100            ; R2 = 100 (0x64)
STR R1, [R2]

//----------CMP
MOV R1, #5              ; R1 = 5 (0x5)
MOV R2, #2              ; R2 = 2 (0x2)
ADD R3, R1, R2          ; R3 = 7 (0x7)
MOV R4, #10             ; R4 = 10 (0xA)
MOV R5, #100            ; R5 = 100 (0x64)
CMP R4, R3              ; Compara 10 e 7
BGT valor_maior         ; Salta (10 > 7)
MOV R3, #0              ; Esta linha é pulada
valor_maior:
STR R3, [R5]            ; Salva R3 (que vale 7) no endereço 100 (0x64)

//----------TST
MOV R1, #5              ; R1 = 5 (0b0101)
MOV R2, #10             ; R2 = 10 (0b1010)
TST R1, R2              ; Testa 0b0101 & 0b1010. Resultado é 0, Zero Flag = 1
BEQ   tst_skip
MOV R1, #7              ; Esta linha é pulada
tst_skip:
MOV R2, #100
STR R1, [R2]

//----------EOR
MOV R1, #10             ; R1 = 10 (0xA)
MOV R2, #12             ; R2 = 12 (0xC)
EOR R3, R1, R2          ; R3 = 6 (0x6)

//----------LSL
MOV R1, #5              ; R1 = 5 (0b101)
LSL R3, R1, #2          ; R3 = R1 << 2 = 20 (0x14)

//----------ASR
MOV R1, #0              ; R1 = 0
SUB R1, R1, #4          ; R1 = 0 - 4 = -4 (0xFFFFFFFC)
ASR R3, R1, #1          ; R3 = -4 >> 1 = -2 (0xFFFFFFFE)

//-Deslocamento na instrução
MOV R1, #10
MOV R2, #5
ADD R3, R1, R2, LSL #2  ; R3 = 10 + (20) = 30 (0x1E)

//---------BL
MOV R1, #0
BL  sub_rotina          ; Chama a sub-rotina, LR = 0x90
ADD R1, R1, #1          ; (Ponto de retorno) R1 = 100 + 1 = 101 (0x65)
B   fim_do_codigo
sub_rotina:
ADD R1, R1, #100        ; R1 = 0 + 100 = 100 (0x64)
MOV PC, LR              ; Retorna para 0x90
fim_do_codigo:
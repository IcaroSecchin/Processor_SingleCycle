// Progrma rápido para testar novas funções

mov r1, #5
mov r2, #0xa
tst r1, r2
beq #0x14
b #0x10
mov r1, #7
mov r2, #0x64
str r1, [r2]
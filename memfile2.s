    MOV R1, #0      // Zera o registrador R1 para começar o teste.                      00
    BL  subrotina   // Chama a sub-rotina. Deve salvar o endereço 0x08 em R14.          04
    
    // Esta linha só é alcançada se o retorno funcionar
    ADD R1, R1, #1  // Incrementa R1. Se o valor final for 101, tudo funcionou.         08
    
    B   fim         // Pula para o final.                                               0c

// A sub-rotina está mais para frente na memória para ser um teste claro.
subrotina:          // Endereço 0x10                                                    
    ADD R1, R1, #100 // Adiciona 100 a R1. Prova que entramos na sub-rotina.            10
    MOV PC, LR      // Retorna usando o endereço salvo em R14 (que deve ser 0x08).      14

fim:                // Endereço 0x18                                                    
    B   fim         // Para o processador aqui para inspeção.                           18
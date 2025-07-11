module testbench();
  logic        clk;
  logic        reset;
  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;

  // Instancia o dispositivo sob teste
  top dut(clk, reset, WriteData, DataAdr, MemWrite);
  
  // Inicializa o teste
  initial begin
    reset <= 1; #22; reset <= 0;
  end

  // Gera o clock para sequenciar os testes
  always begin
    clk <= 1; #5; clk <= 0; #5;
  end

endmodule


module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite);

  logic [31:0] PC, Instr, ReadData;
  
  arm  arm(clk, reset, PC, Instr, MemWrite, DataAdr, WriteData, ReadData);
  imem imem(PC, Instr);
  dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData);
endmodule


module dmem(input  logic        clk, we,
            input  logic [31:0] a, wd,
            output logic [31:0] rd);
  logic [31:0] RAM[63:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule


module imem(input  logic [31:0] a,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  initial
    $readmemh("memfile2.dat", RAM); // Carrega o arquivo de memória

  assign rd = RAM[a[31:2]]; // Alinhado por palavra
endmodule

module arm(input  logic        clk, reset,
           output logic [31:0] PC,
           input  logic [31:0] Instr,
           output logic        MemWrite,
           output logic [31:0] ALUResult, WriteData,
           input  logic [31:0] ReadData);

  logic [3:0] ALUFlags;
  logic       RegWrite, ALUSrc, MemtoReg, PCSrc;
  logic [1:0] RegSrc, ImmSrc;
  logic [2:0] ALUControl;

  controller c(clk, reset, Instr, ALUFlags, 
               RegSrc, RegWrite, ImmSrc, 
               ALUSrc, ALUControl,
               MemWrite, MemtoReg, PCSrc, LinkWrite);
               
  datapath dp(clk, reset, 
              RegSrc, RegWrite, ImmSrc,
              ALUSrc, ALUControl,
              MemtoReg, PCSrc,
              ALUFlags, PC, Instr,
              ALUResult, WriteData, ReadData, LinkWrite);
endmodule

module controller(input  logic        clk, reset,
                  input  logic [31:0] Instr,      // Porta com 32 bits, "tava dando erro de out of range"
                  input  logic [3:0]  ALUFlags,
                  output logic [1:0]  RegSrc,
                  output logic        RegWrite,
                  output logic [1:0]  ImmSrc,
                  output logic        ALUSrc, 
                  output logic [2:0]  ALUControl, //Porta de saída com 3 bits para aumentar a quantidade de instruções possiveis
                  output logic        MemWrite, MemtoReg,
                  output logic        PCSrc,
                  output logic        LinkWrite);

  logic [1:0] FlagW;
  logic       PCS, RegW, MemW;
  
  
  decoder dec(Instr[27:26], Instr[25:20], Instr[15:12], Instr[24],
              FlagW, PCS, RegW, MemW,
              MemtoReg, ALUSrc, ImmSrc, RegSrc, ALUControl, LinkWrite);
  condlogic cl(clk, reset, Instr[31:28], ALUFlags,
               FlagW, PCS, RegW, MemW,
               PCSrc, RegWrite, MemWrite);
endmodule

module decoder(input  logic [1:0] Op,
               input  logic [5:0] Funct,
               input  logic [3:0] Rd,
               input  logic       BLFlag, //Flag responsavel pra saber que é um Branch Linkado
               output logic [1:0] FlagW,
               output logic       PCS, RegW, MemW,
               output logic       MemtoReg, ALUSrc,
               output logic [1:0] ImmSrc, RegSrc,
               output logic [2:0] ALUControl,
               output logic       LinkWrite);

  logic [10:0] controls;
  logic       Branch, ALUOp;

  always_comb
    case(Op)
      2'b00: // Data-processing
        // Verifica se é uma instrução de teste (que não escreve resultado)
        if ( (Funct[4:1] == 4'b1000) || (Funct[4:1] == 4'b1010) ) begin // TST or CMP
          if (Funct[5]) controls = 11'b00000100001; // Imediato (RegW=0)
          else          controls = 11'b00000000001; // Registrador (RegW=0)
        end else begin // Para TODAS as outras instruções DP (ADD, SUB, MOV, LSL, etc.)
          if (Funct[5]) controls = 11'b00000101001; // Imediato (RegW=1)
          else          controls = 11'b00000001001; // Registrador (RegW=1)
        end         
      2'b01: if (Funct[0]) controls = 11'b00001111000; // LDR
            else controls = 11'b01001110100; // STR


      2'b10: if(BLFlag == 0) controls = 11'b00110100010; // B
              else           controls = 11'b10110101010; // BL (Aciona o RegW para 1 ja que precisa escrever em um Registrador)


      default:            controls = 11'bxxxxxxxxxxx;
    endcase

  assign {LinkWrite, RegSrc, ImmSrc, ALUSrc, MemtoReg, RegW, MemW, Branch, ALUOp} = controls;
  
  always_comb
    if (ALUOp) begin
      case(Funct[4:1]) 
        4'b0100: ALUControl = 3'b000; // ADD
        4'b0010: ALUControl = 3'b001; // SUB
        4'b0000: ALUControl = 3'b010; // AND
        4'b1100: ALUControl = 3'b011; // ORR
        4'b1101: ALUControl = 3'b100; // MOV
        4'b1010: ALUControl = 3'b001; // CMP
        4'b1000: ALUControl = 3'b010; // TST
        4'b0001: ALUControl = 3'b101; // EOR
        4'b0011: ALUControl = 3'b110; // LSL
        4'b0101: ALUControl = 3'b111; // ASR
        default: ALUControl = 3'bx;
      endcase
      
      FlagW[1] = Funct[0]; // S-bit para flags N e Z
      FlagW[0] = Funct[0] & (ALUControl == 3'b000 | ALUControl == 3'b001); // S-bit para C e V (só aritméticas)
    end else begin
      ALUControl = 3'b000; // ADD para LDR/STR
      FlagW      = 2'b00;  // Não escreve flags
    end

  assign PCS = ((Rd == 4'b1111) & RegW) | Branch; 
endmodule

module condlogic(input  logic       clk, reset,
                 input  logic [3:0] Cond,
                 input  logic [3:0] ALUFlags,
                 input  logic [1:0] FlagW,
                 input  logic       PCS, RegW, MemW,
                 output logic       PCSrc, RegWrite, MemWrite);
                 
  logic [1:0] FlagWrite;
  logic [3:0] Flags;
  logic       CondEx;

  flopenr #(2) flagreg1(clk, reset, FlagWrite[1], ALUFlags[3:2], Flags[3:2]);
  flopenr #(2) flagreg0(clk, reset, FlagWrite[0], ALUFlags[1:0], Flags[1:0]);

  // A lógica de verificação de condição usa as flags do ciclo anterior.
  condcheck cc(Cond, Flags, CondEx);

  // Os sinais de controle da instrução atual são gerados com base na condição.
  assign RegWrite  = RegW  & CondEx;
  assign MemWrite  = MemW  & CondEx;
  assign PCSrc     = PCS   & CondEx;

  // A escrita de novas flags para o próximo ciclo também depende da condição da instrução atual.
  assign FlagWrite = FlagW & {2{CondEx}};

endmodule

module condcheck(input  logic [3:0] Cond,
                 input  logic [3:0] Flags,
                 output logic       CondEx);
  
  logic neg, zero, carry, overflow, ge;
  
  assign {neg, zero, carry, overflow} = Flags;
  assign ge = (neg == overflow);
             
  always_comb
    case(Cond)
      4'b0000: CondEx = zero;           // EQ
      4'b0001: CondEx = ~zero;          // NE
      4'b0010: CondEx = carry;          // CS
      4'b0011: CondEx = ~carry;         // CC
      4'b0100: CondEx = neg;            // MI
      4'b0101: CondEx = ~neg;           // PL
      4'b0110: CondEx = overflow;       // VS
      4'b0111: CondEx = ~overflow;      // VC
      4'b1000: CondEx = carry & ~zero;  // HI
      4'b1001: CondEx = ~(carry & ~zero);// LS
      4'b1010: CondEx = ge;             // GE
      4'b1011: CondEx = ~ge;            // LT
      4'b1100: CondEx = ~zero & ge;     // GT
      4'b1101: CondEx = ~(~zero & ge);  // LE
      4'b1110: CondEx = 1'b1;           // Always
      default: CondEx = 1'bx;           // undefined
    endcase
endmodule

module datapath(input  logic        clk, reset,
                input  logic [1:0]  RegSrc,
                input  logic        RegWrite,
                input  logic [1:0]  ImmSrc,
                input  logic        ALUSrc,
                input  logic [2:0]  ALUControl,
                input  logic        MemtoReg,
                input  logic        PCSrc,
                output logic [3:0]  ALUFlags,
                output logic [31:0] PC,
                input  logic [31:0] Instr,
                output logic [31:0] ALUResult, WriteData,
                input  logic [31:0] ReadData,
                input  logic        LinkWrite);

  logic [31:0] PCNext, PCPlus4, PCPlus8;
  logic [31:0] ExtImm, SrcA, SrcB, Result;
  logic [3:0]  RA1, RA2;
  logic [31:0] ShifterOut; //adicionado para rolar o deslocamento

  logic [31:0] EscritaFinal;
  logic [3:0]  EscritaRegFinal;

  // MUX 1: Decide ONDE escrever (em qual registrador)
  // Se LinkWrite=0, o destino é Rd (Instr[15:12]).
  // Se LinkWrite=1, o destino é forçado para R14 (4'b1110).
  mux2 #(4) wr_addr_mux(Instr[15:12], 4'b1110, LinkWrite, EscritaRegFinal);

  // MUX 2: Decide O QUE escrever (qual dado)
  // Se LinkWrite=0, o dado é o resultado normal (da ULA ou memória).
  // Se LinkWrite=1, o dado é o endereço de retorno (PC+4).
  mux2 #(32) wr_data_mux(Result, PCPlus4, LinkWrite, EscritaFinal);

  //Lógica para a contagem do PC
  mux2 #(32) pcmux(PCPlus4, ALUResult, PCSrc, PCNext);
  flopr #(32) pcreg(clk, reset, PCNext, PC);
  adder #(32) pcadd1(PC, 32'd4, PCPlus4);
  adder #(32) pcadd2(PC, 32'd8, PCPlus8);

  shifter shift_unit(WriteData, Instr[11:7], Instr[6:5], ShifterOut);


  mux2 #(4)   ra1mux(Instr[19:16], 4'b1111, RegSrc[0], RA1);
  mux2 #(4)   ra2mux(Instr[3:0], Instr[15:12], RegSrc[1], RA2);
  
  regfile rf(clk, RegWrite, RA1, RA2, EscritaRegFinal,
             EscritaFinal,  PCPlus8, 
             SrcA, WriteData); 
             
  mux2 #(32)  resmux(ALUResult, ReadData, MemtoReg, Result);
  extend      ext(Instr[23:0], ImmSrc, ExtImm);

  mux2 #(32)  srcbmux(ShifterOut, ExtImm, ALUSrc, SrcB);
  alu         alu(SrcA, SrcB, ALUControl, 
                  ALUResult, ALUFlags);
endmodule


module regfile(input  logic       clk, 
               input  logic       we3, 
               input  logic [3:0]  ra1, ra2, wa3,      
               input  logic [31:0] wd3, r15,
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[14:0];

  always_ff @(posedge clk)
    if (we3) rf[wa3] <= wd3; 

  assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
  assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];
endmodule

module extend(input  logic [23:0] Instr,
              input  logic [1:0]  ImmSrc,
              output logic [31:0] ExtImm);
  
  always_comb
    case(ImmSrc) 
      2'b00:   ExtImm = {24'b0, Instr[7:0]};
      2'b01:   ExtImm = {20'b0, Instr[11:0]}; 
      2'b10:   ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00}; 
      default: ExtImm = 32'bx;
    endcase
endmodule

module adder #(parameter WIDTH=8)
             (input  logic [WIDTH-1:0] a, b,
              output logic [WIDTH-1:0] y);
  assign y = a + b;
endmodule

module flopenr #(parameter WIDTH = 8)
               (input  logic clk, reset, en,
                input  logic [WIDTH-1:0] d, 
                output logic [WIDTH-1:0] q);
  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else if (en) q <= d;
endmodule

module flopr #(parameter WIDTH = 8)
             (input  logic clk, reset,
              input  logic [WIDTH-1:0] d, 
              output logic [WIDTH-1:0] q);
  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)
            (input  logic [WIDTH-1:0] d0, d1, 
             input  logic             s, 
             output logic [WIDTH-1:0] y);
  //Caso s for 1, d1 sai, caso for 0, d0 sai
  assign y = s ? d1 : d0; 
endmodule

module alu(input  logic [31:0] a, b,
           input  logic [2:0]  ALUControl,
           output logic [31:0] Result,
           output logic [3:0]  ALUFlags);

  logic        neg, zero, carry, overflow;
  logic [31:0] condinvb;
  logic [32:0] sum;
  logic        isArith; //Sinal intermediario para saber que é uma operação aritimedica

  assign isArith = (ALUControl == 3'b000) | (ALUControl == 3'b001);
  assign condinvb = (ALUControl == 3'b001) ? ~b : b;
  assign sum = a + condinvb + (ALUControl == 3'b001);

  always_comb
    case (ALUControl)
      3'b000: Result = sum;
      3'b001: Result = sum;
      3'b010: Result = a & b;  //AND
      3'b011: Result = a | b;  //ORR
      3'b100: Result = b;      //MOV
      3'b101: Result = a ^ b;  //EOR
      3'b110: Result = a << b; //LSL
      3'b111: Result = a >>> b; //ASR
      default: Result = 32'bx;
    endcase

  assign neg      = Result[31];
  assign zero     = (Result == 32'b0);
  assign carry    = isArith & sum[32];
  assign overflow = isArith & ~(a[31] ^ b[31] ^ (ALUControl == 3'b001)) & (a[31] ^ sum[31]); 
  assign ALUFlags = {neg, zero, carry, overflow};
endmodule

module shifter(input  logic [31:0] DataIn,      // Dado deslocado (de Rm)
               input  logic [4:0]  ShiftAmount, // Quantidade de deslocamento (de shamt5)
               input  logic [1:0]  ShiftType,   // Tipo de deslocamento (LSL, LSR, ASR)
               output logic [31:0] DataOut);

  always_comb
    case (ShiftType)
      2'b00:  DataOut = DataIn << ShiftAmount; // LSL (Logical Shift Left)
      2'b01:  DataOut = DataIn >> ShiftAmount; // LSR (Logical Shift Right)
      2'b10:  DataOut = DataIn >>> ShiftAmount;// ASR (Arithmetic Shift Right)
      default: DataOut = DataIn; // Caso padrão ou ROR
    endcase
endmodule
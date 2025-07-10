echo "========================================================"
echo "== INICIANDO SCRIPT DE SIMULAÇÃO PARA APRESENTAÇÃO    =="
echo "========================================================"

# --- 1. Limpeza ---
if {[file exists work]} {
    vdel -all
}

# --- 2. Compilação ---
vlib work
vlog arm_single.sv

# --- 3. Simulação ---
vsim -novopt work.testbench

# --- 4. Configuração da Janela Wave ---
add wave -divider "Sinais Principais"
add wave /testbench/clk
add wave /testbench/reset
add wave -radix hexadecimal /testbench/dut/PC
add wave -radix hexadecimal /testbench/dut/Instr

add wave -divider "Sinais de Controle (Nível ARM)"
add wave /testbench/dut/arm/MemWrite
add wave /testbench/dut/arm/PCSrc
add wave /testbench/dut/arm/RegWrite
add wave /testbench/dut/arm/ALUSrc
add wave /testbench/dut/arm/MemtoReg
add wave -radix binary /testbench/dut/arm/ALUControl

add wave -divider "Banco de Registradores (R0-R14)"
add wave -radix hexadecimal /testbench/dut/arm/dp/rf/rf

add wave -divider "Memória RAM"
add wave -radix hexadecimal /testbench/dut/dmem/RAM
add wave -radix hexadecimal /testbench/dut/imem/RAM

# --- 5. Execução ---
# Roda a simulação por 400 picossegundos
run 400ps

echo "========================================================"
echo "== SIMULAÇÃO CONCLUÍDA                            =="
echo "========================================================"
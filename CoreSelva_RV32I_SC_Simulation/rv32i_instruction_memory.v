`timescale 1ns/1ps

// CoreSelva RV32I_SC
// Author: Vishal Selavn
// Instruction-memory unit for the single-cycle RV32I core.

// Read-only instruction memory containing 1024 32-bit words.
// Instructions are word-aligned, so address bits [1:0] are discarded.
module rv32i_instruction_memory #(
    parameter MEM_FILE = "program.hex"
)(
    input wire [31:0] counter,
    output wire [31:0] instr);
    reg [31:0] memory [0:1023];
    integer i;

    // Fill unused addresses with NOPs before loading the program image. The
    // filename parameter can be overridden when instantiating this module.
    initial begin
        for(i = 0; i < 1024; i = i + 1)
            memory[i] = 32'h00000013; // NOP: ADDI x0, x0, 0
        // With no explicit end address, read as many words as the hex file
        // contains. The 1024-word array is the only capacity limit.
        $readmemh(MEM_FILE, memory);
    end

    // Combinational instruction fetch.
    assign instr = memory[counter[31:2]];
endmodule

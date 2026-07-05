`timescale 1ns/1ps

// CoreSelva RV32I_SC
// Author: Vishal Selavn
// Write-back unit for the single-cycle RV32I core.

// Write-back multiplexer. Loads select memory data; all other register-writing
// instructions select the execute-stage result.
module rv32i_writeback(
    input wire writereg,
    input wire [6:0] opcode,
    input wire [31:0] result,
    input wire [31:0] read_data,
    output reg [31:0] writedata);
    always @(*) begin
		// Default prevents a latch when register write-back is disabled.
		writedata = 32'd0;
        if(writereg) begin
            //LW Instruction
            if(opcode == 7'b0000011) begin
                writedata = read_data;
			end
            //All other instructions
            else begin
                writedata = result;
			end
        end
    end
endmodule

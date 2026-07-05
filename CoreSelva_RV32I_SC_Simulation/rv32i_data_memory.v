`timescale 1ns/1ps

// CoreSelva RV32I_SC
// Author: Vishal Selavn
// Data-memory unit for the single-cycle RV32I core.

// Little-endian data memory containing 1024 32-bit words.
// Reads are combinational and writes occur on the rising clock edge.
// The core assumes naturally aligned halfword and word accesses.
module rv32i_data_memory(
    input wire clk,
    input wire memwrite,
    input wire [2:0] funct3,
    input wire [31:0] result,
    input wire [31:0] rdata2,
    output reg [31:0] read_data);
    reg [31:0] memory [0:1023];

    // Select the addressed word, then choose its byte or halfword using the
    // two low address bits.
    wire [31:0] memory_word = memory[result[31:2]];
    reg [7:0] byte_data;
    reg [15:0] half_data;

    // Little-endian load logic: LB, LH, LW, LBU and LHU.
    always @(*) begin
        case(result[1:0])
            2'd0: byte_data = memory_word[7:0];
            2'd1: byte_data = memory_word[15:8];
            2'd2: byte_data = memory_word[23:16];
            default: byte_data = memory_word[31:24];
        endcase

        if(result[1])
            half_data = memory_word[31:16];
        else
            half_data = memory_word[15:0];

        // funct3 selects width and signed/unsigned extension.
        case(funct3)
            3'b000: read_data = {{24{byte_data[7]}}, byte_data};
            3'b001: read_data = {{16{half_data[15]}}, half_data};
            3'b010: read_data = memory_word;
            3'b100: read_data = {24'd0, byte_data};
            3'b101: read_data = {16'd0, half_data};
            default: read_data = 32'd0;
        endcase
    end

    // Little-endian store logic: preserve unaffected byte lanes for SB/SH.
	always @(posedge clk) begin
		if(memwrite) begin
			case(funct3)
                3'b000: begin
                    case(result[1:0])
                        2'd0: memory[result[31:2]][7:0] <= rdata2[7:0];
                        2'd1: memory[result[31:2]][15:8] <= rdata2[7:0];
                        2'd2: memory[result[31:2]][23:16] <= rdata2[7:0];
                        2'd3: memory[result[31:2]][31:24] <= rdata2[7:0];
                    endcase
                end
                3'b001: begin
                    if(result[1])
                        memory[result[31:2]][31:16] <= rdata2[15:0];
                    else
                        memory[result[31:2]][15:0] <= rdata2[15:0];
                end
                3'b010: memory[result[31:2]] <= rdata2;
                default: ;
            endcase
		end
	end
endmodule

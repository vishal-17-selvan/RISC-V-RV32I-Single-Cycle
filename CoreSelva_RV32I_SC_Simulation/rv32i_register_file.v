`timescale 1ns/1ps

// CoreSelva RV32I_SC
// Author: Vishal Selavn
// Integer register file for the single-cycle RV32I core.

// RV32I register file: two asynchronous read ports and one synchronous write
// port. Register x0 always reads as zero and ignores writes.
module rv32i_register_file(
    input wire clk,
    input wire rst,
    input wire [4:0] rs1,
    input wire [4:0] rs2,
    input wire [4:0] rd,
    input wire [31:0] wd,
    input wire en,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2 );
reg [31:0] x [0:31];
integer i;

// Combinational reads enforce the architectural x0 value independently of
// the backing array.
assign rdata1 = (rs1 == 5'd0) ? 32'd0 : x[rs1];
assign rdata2 = (rs2 == 5'd0) ? 32'd0 : x[rs2];

// Reset clears all registers; normal writes occur on the rising clock edge.
always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i = 0; i < 32; i = i + 1)
            x[i] <= 32'd0;
    end
    else if(en && (rd != 5'd0))
        x[rd] <= wd;
end
endmodule

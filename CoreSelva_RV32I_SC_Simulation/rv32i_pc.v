`timescale 1ns/1ps

// CoreSelva RV32I_SC
// Author: Vishal Selavn
// Program-counter unit for the single-cycle RV32I core.

// Fetch-stage program counter for the single-cycle core.
// Reset is asynchronous and active high. A taken branch or jump has priority
// over the normal sequential PC + 4 update.
module rv32i_pc(
    input wire clk,
    input wire rst,
    input wire branch_taken,
    input wire [31:0] branch_target,
    output reg [31:0] counter
);
    always @(posedge clk or posedge rst) begin
        if(rst)
            counter <= 32'd0;
        else if(branch_taken)
            counter <= branch_target;
        else
            counter <= counter + 32'd4;
    end
endmodule

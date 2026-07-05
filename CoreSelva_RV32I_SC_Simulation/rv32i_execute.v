`timescale 1ns/1ps

// CoreSelva RV32I_SC
// Author: Vishal Selavn
// Execute unit for the single-cycle RV32I core.

// Execute stage for RV32I ALU, address-generation and control-flow operations.
// result carries the ALU value or return address; branches and jumps also
// produce branch_taken and branch_target for the program counter.
module rv32i_execute(
    input wire [31:0] counter,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    input wire [31:0] rdata1,
    input wire [31:0] rdata2,
    input wire [31:0] imm,
    output reg [31:0] result,
    output reg branch_taken,
    output reg [31:0] branch_target);
always @(*) begin
    // Defaults also define harmless behavior for unsupported encodings.
    result = 32'd0;
    branch_taken = 1'b0;
    branch_target = 32'd0;
    // R-type register-register operations.
    if(opcode == 7'b0110011) begin
        if(funct3 == 3'd0) begin
            if(funct7 == 7'd0)
                result = rdata1 + rdata2;
            else if(funct7 == 7'd32)
                result = rdata1 - rdata2;
        end
        else if(funct3 == 3'd4) begin
            if(funct7 == 7'd0)
                result = rdata1 ^ rdata2;
        end
        else if(funct3 == 3'd6) begin
            if(funct7 == 7'd0)
                result = rdata1 | rdata2;
        end
        else if(funct3 == 3'd7) begin
            if(funct7 == 7'd0)
                result = rdata1 & rdata2;
        end
        else if(funct3 == 3'd1) begin
            if(funct7 == 7'd0)
                result = rdata1 << rdata2[4:0];
        end
        else if(funct3 == 3'd5) begin
            if(funct7 == 7'd0)
                result = rdata1 >> rdata2[4:0];
            else if(funct7 == 7'd32)
                result = $signed(rdata1) >>> rdata2[4:0];
        end
        else if(funct3 == 3'd2) begin
            if(funct7 == 7'd0)
                result = ($signed(rdata1) < $signed(rdata2)) ? 32'd1 : 32'd0;
        end
        else if(funct3 == 3'd3) begin
            if(funct7 == 7'd0)
                result = (rdata1 < rdata2) ? 32'd1 : 32'd0;
        end
    end
    // I-type immediate operations.
    else if(opcode == 7'b0010011) begin
        if(funct3 == 3'd0)
            result = rdata1 + imm;
        else if(funct3 == 3'd4)
            result = rdata1 ^ imm;
        else if(funct3 == 3'd6)
            result = rdata1 | imm;
        else if(funct3 == 3'd7)
            result = rdata1 & imm;
        else if(funct3 == 3'd1)
            result = rdata1 << imm[4:0];
        else if(funct3 == 3'd5) begin
            if(funct7 == 7'd0)
                result = rdata1 >> imm[4:0];
            else if(funct7 == 7'd32)
                result = $signed(rdata1) >>> imm[4:0];
        end
        else if(funct3 == 3'd2)
            result = ($signed(rdata1) < $signed(imm)) ? 32'd1 : 32'd0;
        else if(funct3 == 3'd3)
            result = (rdata1 < imm) ? 32'd1 : 32'd0;
    end
    // Load effective address.
    else if(opcode == 7'b0000011) begin
        result = rdata1 + imm;
    end
    // Store effective address.
    else if(opcode == 7'b0100011) begin
        result = rdata1 + imm;
    end
    // Conditional branches use signed or unsigned comparison as required.
    else if(opcode == 7'b1100011) begin
        branch_target = counter + imm;
        if(funct3 == 3'd0)
            branch_taken = (rdata1 == rdata2);
        else if(funct3 == 3'd1)
            branch_taken = (rdata1 != rdata2);
        else if(funct3 == 3'd4)
            branch_taken = ($signed(rdata1) < $signed(rdata2));
        else if(funct3 == 3'd5)
            branch_taken = ($signed(rdata1) >= $signed(rdata2));
        else if(funct3 == 3'd6)
            branch_taken = (rdata1 < rdata2);
        else if(funct3 == 3'd7)
            branch_taken = (rdata1 >= rdata2);
    end
    // JAL writes PC + 4 and redirects execution to PC + immediate.
    else if(opcode == 7'b1101111) begin
        result = counter + 32'd4;
        branch_taken = 1'b1;
        branch_target = counter + imm;
    end
    // JALR clears target bit zero as required by the ISA.
    else if(opcode == 7'b1100111) begin
        result = counter + 32'd4;
        branch_taken = 1'b1;
        branch_target = (rdata1 + imm) & 32'hFFFFFFFE;
    end
    // LUI places the upper immediate directly in the destination register.
    else if(opcode == 7'b0110111) begin
        result = imm;
    end
    // AUIPC adds the upper immediate to the current PC.
    else if(opcode == 7'b0010111) begin
        result = counter + imm;
    end
end
endmodule

`timescale 1ns/1ps

// CoreSelva RV32I_SC
// Author: Vishal Selavn
// Top-level integration of the single-cycle RV32I processor.

// Top-level integration of the educational single-cycle RV32I processor.
// Each instruction completes fetch through write-back in one clock cycle.
module rv32i_core(

    input wire clk,
    input wire rst

);

wire [31:0] counter;
wire [31:0] instr;

wire [6:0] opcode;
wire [4:0] rd;
wire [2:0] funct3;
wire [4:0] rs1;
wire [4:0] rs2;
wire [6:0] funct7;
wire [31:0] imm;

wire [31:0] rdata1;
wire [31:0] rdata2;

wire [31:0] result;
wire branch_taken;
wire [31:0] branch_target;

wire memwrite;
wire writereg;

wire [31:0] read_data;
wire [31:0] writedata;


//--------------------------------------
// Control signals derived directly from the instruction opcode.
//--------------------------------------

assign memwrite = (opcode == 7'b0100011);

assign writereg = (
                    opcode == 7'b0110011 ||   // R-type
                    opcode == 7'b0010011 ||   // I-type ALU
                    opcode == 7'b0000011 ||   // Load
                    opcode == 7'b0110111 ||   // LUI
                    opcode == 7'b0010111 ||   // AUIPC
                    opcode == 7'b1101111 ||   // JAL
                    opcode == 7'b1100111      // JALR
                  );


//--------------------------------------
// Program Counter
//--------------------------------------

rv32i_pc pc(

    .clk(clk),
    .rst(rst),
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .counter(counter)

);


//--------------------------------------
// Instruction Memory
//--------------------------------------

rv32i_instruction_memory imem(

    .counter(counter),
    .instr(instr)

);


//--------------------------------------
// Decoder
//--------------------------------------

rv32i_decoder dec(

    .instr(instr),

    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7),
    .imm(imm)

);


//--------------------------------------
// Register File
//--------------------------------------

rv32i_register_file rf(

    .clk(clk),
    .rst(rst),

    .rs1(rs1),
    .rs2(rs2),

    .rd(rd),
    .wd(writedata),

    .en(writereg),

    .rdata1(rdata1),
    .rdata2(rdata2)

);


//--------------------------------------
// Execute
//--------------------------------------

rv32i_execute ex(

    .counter(counter),

    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),

    .rdata1(rdata1),
    .rdata2(rdata2),
    .imm(imm),

    .result(result),
    .branch_taken(branch_taken),
    .branch_target(branch_target)

);


//--------------------------------------
// Data Memory
//--------------------------------------

rv32i_data_memory dm(

    .clk(clk),

    .memwrite(memwrite),

    .funct3(funct3),

    .result(result),
    .rdata2(rdata2),

    .read_data(read_data)

);


//--------------------------------------
// Write Back
//--------------------------------------

rv32i_writeback wb(

    .writereg(writereg),

    .opcode(opcode),

    .result(result),
    .read_data(read_data),

    .writedata(writedata)

);

endmodule

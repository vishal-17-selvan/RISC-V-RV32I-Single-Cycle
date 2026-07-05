`timescale 1ns/1ps

// CoreSelva RV32I_SC
// Author: Vishal Selavn
// Self-checking verification environment for the processor core.

// Self-checking architectural regression for the single-cycle RV32I core.
// The executable program is stored separately in program.hex;
// this testbench only loads it, runs it, and checks its memory signatures.
module tb_core;
    localparam integer PROGRAM_WORDS = 198;
    localparam integer HALT_PC = (PROGRAM_WORDS - 1) * 4;

    reg clk;
    reg rst;
    integer signatures;
    integer cycles;
    integer errors;
    integer i;

    reg [31:0] expected [0:127];
    reg [8*32-1:0] test_name [0:127];

    rv32i_core dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    // Register one expected signature in the same order that the program
    // stores results into data memory starting at byte address zero.
    task expect_result;
        input [31:0] value;
        input [8*32-1:0] name;
        begin
            expected[signatures] = value;
            test_name[signatures] = name;
            signatures = signatures + 1;
        end
    endtask

    task compare_signatures;
        begin
            errors = 0;
            $display("");
            $display("CoreSelva RV32I_SC - CPU ARCHITECTURAL VALIDATION");
            $display("--------------------------------------------------------------------------");
            $display("Test                     Actual     Expected   Status");
            $display("--------------------------------------------------------------------------");
            for(i = 0; i < signatures; i = i + 1) begin
                if(dut.dm.memory[i] !== expected[i]) begin
                    $display("%-24s %08h   %08h   FAIL",
                             test_name[i], dut.dm.memory[i], expected[i]);
                    errors = errors + 1;
                end
                else begin
                    $display("%-24s %08h   %08h   PASS",
                             test_name[i], dut.dm.memory[i], expected[i]);
                end
            end

            // x0 is checked separately because it is not stored as a program
            // signature and must remain hard-wired to zero at all times.
            if(dut.rf.x[0] !== 32'd0) begin
                $display("%-24s %08h   %08h   FAIL",
                         "x0 hard-wired zero", dut.rf.x[0], 32'd0);
                errors = errors + 1;
            end
            else begin
                $display("%-24s %08h   %08h   PASS",
                         "x0 hard-wired zero", dut.rf.x[0], 32'd0);
            end

            $display("--------------------------------------------------------------------------");
            $display("Executed %0d cycles; %0d checks; %0d passed; %0d failed",
                     cycles, signatures + 1, signatures + 1 - errors, errors);
            if(errors == 0) begin
                $display("CPU VALIDATION: PASS - all architectural results match");
                $display("--------------------------------------------------------------------------");
            end
            else begin
                $display("CPU VALIDATION: FAIL - %0d result(s) did not match", errors);
                $display("--------------------------------------------------------------------------");
                $fatal(1, "CoreSelva RV32I_SC validation failed");
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        signatures = 0;
        cycles = 0;
        errors = 0;

        // Instruction memory loads the hex image itself. The testbench only
        // clears data memory before execution.
        #1;
        for(i = 0; i < 1024; i = i + 1)
            dut.dm.memory[i] = 32'd0;

        // Expected values follow the signature-store order in the hex image.
        expect_result(32'h80000001, "ADD");
        expect_result(32'h7fffffff, "SUB");
        expect_result(32'h00000000, "SLL");
        expect_result(32'h00000001, "SLT");
        expect_result(32'h00000000, "SLTU");
        expect_result(32'h80000001, "XOR");
        expect_result(32'h40000000, "SRL");
        expect_result(32'hc0000000, "SRA");
        expect_result(32'h80000001, "OR");
        expect_result(32'h00000000, "AND");

        expect_result(32'h7fffffff, "ADDI");
        expect_result(32'h00000001, "SLTI");
        expect_result(32'h00000001, "SLTIU");
        expect_result(32'h7fffffff, "XORI");
        expect_result(32'h800007ff, "ORI");
        expect_result(32'h80000000, "ANDI");
        expect_result(32'h00000000, "SLLI");
        expect_result(32'h40000000, "SRLI");
        expect_result(32'hc0000000, "SRAI");

        expect_result(32'h12345000, "LUI");
        expect_result(32'h123450b4, "AUIPC");

        expect_result(32'hffffffd4, "LB");
        expect_result(32'hffffc3d4, "LH");
        expect_result(32'ha1b2c3d4, "LW");
        expect_result(32'h000000c3, "LBU");
        expect_result(32'h0000a1b2, "LHU");
        expect_result(32'h1122aa44, "SB");
        expect_result(32'hbeef3344, "SH");

        expect_result(32'h00000055, "BEQ taken");
        expect_result(32'h00000066, "BEQ not taken");
        expect_result(32'h00000055, "BNE taken");
        expect_result(32'h00000066, "BNE not taken");
        expect_result(32'h00000055, "BLT taken");
        expect_result(32'h00000066, "BLT not taken");
        expect_result(32'h00000055, "BGE taken");
        expect_result(32'h00000066, "BGE not taken");
        expect_result(32'h00000055, "BLTU taken");
        expect_result(32'h00000066, "BLTU not taken");
        expect_result(32'h00000055, "BGEU taken");
        expect_result(32'h00000066, "BGEU not taken");

        expect_result(32'h000002c0, "JAL link");
        expect_result(32'h00000055, "JAL target");
        expect_result(32'h000002d8, "JALR link");
        expect_result(32'h00000055, "JALR target/LSB clear");
        expect_result(32'h00004e84, "200-iteration loop");

        $display("Loaded %0d-word RV32I program from program.hex",
                 PROGRAM_WORDS);
        $display("Registered %0d result signatures", signatures);

        // Release reset away from a rising edge to avoid a testbench race.
        repeat(2) @(negedge clk);
        rst = 1'b0;
    end

    initial begin
        $dumpfile("core.vcd");
        $dumpvars(0, tb_core);
        wait(rst == 1'b0);

        forever begin
            @(negedge clk);
            cycles = cycles + 1;
            if(dut.counter == HALT_PC) begin
                compare_signatures;
                $finish;
            end
            if(cycles > 2000) begin
                $display("TIMEOUT: PC=%08h after %0d cycles", dut.counter, cycles);
                $fatal(1, "CoreSelva RV32I_SC validation timed out");
            end
        end
    end
endmodule

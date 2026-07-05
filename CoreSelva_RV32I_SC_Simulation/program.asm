# CoreSelva RV32I_SC
# Author: Vishal Selavn
# Human-readable teaching companion to program.hex
#
# The simulator executes program.hex. This file explains the same directed
# tests using RISC-V assembly and decimal results. The `li` and `la`
# pseudo-instructions may be expanded differently by different assemblers, so
# assembling this file can change instruction addresses used by JAL/AUIPC.

.section .text
.globl _start

_start:
    li   x30, 0                  # x30 = base address of result signatures

    # ------------------------------------------------------------------
    # Register-register ALU tests
    # x1 = 0x80000000 = -2147483648 signed
    # x2 = 1
    # ------------------------------------------------------------------
    li   x1, 0x80000000
    li   x2, 1

    add  x3, x1, x2             # -2147483648 + 1 = -2147483647
    sw   x3, 0(x30)             # expected 0x80000001 / -2147483647

    sub  x3, x1, x2             # wraps to largest positive signed value
    sw   x3, 4(x30)             # expected 0x7FFFFFFF / 2147483647

    sll  x3, x1, x2             # 0x80000000 << 1, low 32 bits remain
    sw   x3, 8(x30)             # expected 0x00000000 / 0

    slt  x3, x1, x2             # signed: -2147483648 < 1 is true
    sw   x3, 12(x30)            # expected 1

    sltu x3, x1, x2             # unsigned: 2147483648 < 1 is false
    sw   x3, 16(x30)            # expected 0

    xor  x3, x1, x2
    sw   x3, 20(x30)            # expected 0x80000001 / -2147483647

    srl  x3, x1, x2             # logical shift inserts zero
    sw   x3, 24(x30)            # expected 0x40000000 / 1073741824

    sra  x3, x1, x2             # arithmetic shift copies sign bit
    sw   x3, 28(x30)            # expected 0xC0000000 / -1073741824

    or   x3, x1, x2
    sw   x3, 32(x30)            # expected 0x80000001 / -2147483647

    and  x3, x1, x2
    sw   x3, 36(x30)            # expected 0

    # ------------------------------------------------------------------
    # Immediate ALU tests
    # ------------------------------------------------------------------
    addi x3, x1, -1
    sw   x3, 40(x30)            # expected 0x7FFFFFFF / 2147483647

    slti x3, x1, 0              # -2147483648 < 0
    sw   x3, 44(x30)            # expected 1

    sltiu x3, x1, -1            # 2147483648 < 4294967295
    sw    x3, 48(x30)           # expected 1

    xori x3, x1, -1             # invert every bit
    sw   x3, 52(x30)            # expected 0x7FFFFFFF / 2147483647

    ori  x3, x1, 0x7FF
    sw   x3, 56(x30)            # expected 0x800007FF / -2147481601

    andi x3, x1, -1
    sw   x3, 60(x30)            # expected 0x80000000 / -2147483648

    slli x3, x1, 1
    sw   x3, 64(x30)            # expected 0

    srli x3, x1, 1
    sw   x3, 68(x30)            # expected 1073741824

    srai x3, x1, 1
    sw   x3, 72(x30)            # expected -1073741824

    # ------------------------------------------------------------------
    # Upper-immediate tests
    # ------------------------------------------------------------------
    lui   x3, 0x12345
    sw    x3, 76(x30)           # expected 0x12345000 / 305418240

    auipc x3, 0x12345
    sw    x3, 80(x30)           # current hex expects 0x123450B4 / 305418420

    # ------------------------------------------------------------------
    # Load tests. The scratch word starts at byte address 512.
    # Little-endian bytes are D4 C3 B2 A1.
    # ------------------------------------------------------------------
    li   x20, 512
    li   x1, 0xA1B2C3D4
    sw   x1, 0(x20)

    lb   x3, 0(x20)             # byte D4 sign-extends to -44
    sw   x3, 84(x30)            # expected 0xFFFFFFD4 / -44

    lh   x3, 0(x20)             # halfword C3D4 sign-extends
    sw   x3, 88(x30)            # expected 0xFFFFC3D4 / -15404

    lw   x3, 0(x20)
    sw   x3, 92(x30)            # expected 0xA1B2C3D4 / -1582119980 signed

    lbu  x3, 1(x20)             # byte C3 without sign extension
    sw   x3, 96(x30)            # expected 0x000000C3 / 195

    lhu  x3, 2(x20)             # halfword A1B2 without sign extension
    sw   x3, 100(x30)           # expected 0x0000A1B2 / 41394

    # ------------------------------------------------------------------
    # Store-width tests
    # ------------------------------------------------------------------
    li   x1, 0x11223344
    sw   x1, 0(x20)
    li   x2, 0xAA
    sb   x2, 1(x20)             # replace only byte 1
    lw   x3, 0(x20)
    sw   x3, 104(x30)           # expected 0x1122AA44 / 287484484

    li   x1, 0x11223344
    sw   x1, 0(x20)
    li   x2, 0xBEEF
    sh   x2, 2(x20)             # replace only upper halfword
    lw   x3, 0(x20)
    sw   x3, 108(x30)           # expected 0xBEEF3344 / -1091620028 signed

    # ------------------------------------------------------------------
    # Branch tests use 85 (0x55) for the taken path and 102 (0x66) for
    # the sequential path. Each branch is tested taken and not taken.
    # ------------------------------------------------------------------
    li x1, 5
    li x2, 5
    li x3, 85
    beq x1, x2, beq_taken
    li x3, 102
beq_taken:
    sw x3, 112(x30)             # expected 85

    li x1, 5
    li x2, 6
    li x3, 85
    beq x1, x2, beq_not_target
    li x3, 102
beq_not_target:
    sw x3, 116(x30)             # expected 102

    li x1, 5
    li x2, 6
    li x3, 85
    bne x1, x2, bne_taken
    li x3, 102
bne_taken:
    sw x3, 120(x30)             # expected 85

    li x1, 5
    li x2, 5
    li x3, 85
    bne x1, x2, bne_not_target
    li x3, 102
bne_not_target:
    sw x3, 124(x30)             # expected 102

    li x1, -1
    li x2, 1
    li x3, 85
    blt x1, x2, blt_taken
    li x3, 102
blt_taken:
    sw x3, 128(x30)             # expected 85

    li x1, 1
    li x2, -1
    li x3, 85
    blt x1, x2, blt_not_target
    li x3, 102
blt_not_target:
    sw x3, 132(x30)             # expected 102

    li x1, 1
    li x2, -1
    li x3, 85
    bge x1, x2, bge_taken
    li x3, 102
bge_taken:
    sw x3, 136(x30)             # expected 85

    li x1, -1
    li x2, 1
    li x3, 85
    bge x1, x2, bge_not_target
    li x3, 102
bge_not_target:
    sw x3, 140(x30)             # expected 102

    li x1, 1
    li x2, -1
    li x3, 85
    bltu x1, x2, bltu_taken
    li x3, 102
bltu_taken:
    sw x3, 144(x30)             # expected 85

    li x1, -1
    li x2, 1
    li x3, 85
    bltu x1, x2, bltu_not_target
    li x3, 102
bltu_not_target:
    sw x3, 148(x30)             # expected 102

    li x1, -1
    li x2, 1
    li x3, 85
    bgeu x1, x2, bgeu_taken
    li x3, 102
bgeu_taken:
    sw x3, 152(x30)             # expected 85

    li x1, 1
    li x2, -1
    li x3, 85
    bgeu x1, x2, bgeu_not_target
    li x3, 102
bgeu_not_target:
    sw x3, 156(x30)             # expected 102

    # ------------------------------------------------------------------
    # Jump tests
    # ------------------------------------------------------------------
    li   x19, 85
    jal  x18, jal_target
    li   x19, 102               # skipped
jal_target:
    sw   x18, 160(x30)          # link = JAL address + 4
    sw   x19, 164(x30)          # expected 85

    li   x19, 85
    la   x20, jalr_target
    addi x20, x20, 1            # JALR must clear this low bit
    jalr x18, 0(x20)
    li   x19, 102               # skipped
jalr_target:
    sw   x18, 168(x30)          # link = JALR address + 4
    sw   x19, 172(x30)          # expected 85

    fence                       # no visible data side effect in this core
    ecall                       # no trap interface in this teaching core

    # ------------------------------------------------------------------
    # Long loop: sum every integer from 1 through 200.
    # ------------------------------------------------------------------
    li x1, 0                    # sum = 0
    li x2, 1                    # number = 1
    li x3, 201                  # stop when number reaches 201
sum_loop:
    add  x1, x1, x2
    addi x2, x2, 1
    blt  x2, x3, sum_loop
    sw   x1, 176(x30)           # expected 20100 / 0x00004E84

halt:
    jal x0, halt                # deterministic simulation halt loop

# CoreSelva RV32I_SC

**Author:** Vishal Selavn

CoreSelva RV32I_SC is an educational 32-bit RISC-V processor written in
Verilog. It uses a **single-cycle datapath**, so each instruction completes
fetch, decode, execute, memory access, and write-back in one clock cycle.

## How the core works

```text
Program Counter -> Instruction Memory -> Decoder -> Register File
                                                -> Execute / ALU
                                                -> Data Memory
                                                -> Write Back
```

1. The program counter selects an instruction from `program.hex`.
2. The decoder extracts the opcode, registers, function fields, and immediate.
3. The register file provides the two source operands.
4. The execute unit performs the ALU operation, address calculation, or branch.
5. The result or loaded data is written to the destination register.

Register `x0` is always zero. Branches and jumps replace the normal `PC + 4`
address with their target address.

## Supported instructions

- ALU: `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`
- Immediate: `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`
- Memory: `LB`, `LH`, `LW`, `LBU`, `LHU`, `SB`, `SH`, `SW`
- Branch: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- Jump: `JAL`, `JALR`
- Upper immediate: `LUI`, `AUIPC`

## Project files

| File | Purpose |
|---|---|
| `rv32i_core.v` | Connects the complete processor |
| `rv32i_pc.v` | Program counter |
| `rv32i_instruction_memory.v` | Loads and supplies instructions |
| `rv32i_decoder.v` | Decodes instructions and immediates |
| `rv32i_register_file.v` | Implements registers `x0` to `x31` |
| `rv32i_execute.v` | ALU, branches, jumps, and address calculation |
| `rv32i_data_memory.v` | Little-endian load/store memory |
| `rv32i_writeback.v` | Selects data written to the register file |
| `program.hex` | Machine-code test program executed by the core |
| `program.asm` | Readable teaching version with expected results |
| `tb_core.v` | Self-checking testbench |

## Test program

The supplied 198-word program checks every supported instruction. It includes:

- Signed and unsigned arithmetic and comparisons
- Byte, halfword, and word loads/stores
- Taken and not-taken branches
- `JAL` and `JALR`
- A loop that calculates `1 + 2 + ... + 200 = 20100`

The program stores 45 results in data memory. The testbench compares each
actual result with its expected value and checks `x0` separately, giving 46
checks in total.

For readable examples, open `program.asm`:

```asm
li   x1, 0x80000000      # -2147483648
li   x2, 1
add  x3, x1, x2
sw   x3, 0(x30)          # expected: 0x80000001
```

The simulator executes `program.hex`; `program.asm` is provided for learning.

## How to run

Install [Icarus Verilog](https://steveicarus.github.io/iverilog/), open
PowerShell in the project directory, and compile:

```powershell
iverilog -g2012 -Wall -s tb_core -o core_sim rv32i_pc.v rv32i_instruction_memory.v rv32i_decoder.v rv32i_register_file.v rv32i_execute.v rv32i_data_memory.v rv32i_writeback.v rv32i_core.v tb_core.v
```

Run the simulation:

```powershell
vvp core_sim
```

Run it from the project directory so instruction memory can find `program.hex`.

The terminal shows actual and expected hexadecimal results:

```text
Test                     Actual     Expected   Status
ADD                      80000001   80000001   PASS
SUB                      7fffffff   7fffffff   PASS
```

A correct run finishes with:

```text
Executed 786 cycles; 46 checks; 46 passed; 0 failed
CPU VALIDATION: PASS - all architectural results match
```

The simulation creates `core.vcd`. If GTKWave is installed, open it with:

```powershell
gtkwave core.vcd
```

Icarus may warn that `program.hex` contains fewer words than the 1024-word
instruction memory. This is harmless; unused locations remain NOPs.

## Current limitations

This core is intended for learning and simulation. It does not currently
implement privileged modes, CSRs, interrupts, traps, memory protection, or
misaligned-access handling.

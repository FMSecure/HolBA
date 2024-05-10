# HolBA RISC-V examples

## Prerequisites

### Intalling the RISC-V cross-compilation toolchain

Clone the RISC-V GNU Compiler Toolchain:

```shell
git clone https://github.com/riscv/riscv-gnu-toolchain
```

Install the prerequisites, e.g., on Ubuntu:

```shell
sudo apt-get install autoconf automake autotools-dev curl python3 python3-pip libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake libglib2.0-dev
```

Configure and build Linux cross-compiler:

```shell
./configure --prefix=/path/to/riscv
make linux
```

### Building HolBA

See the [general README](https://github.com/kth-step/HolBA/blob/master/README.md) for information on how to build HolBA.

## Binary verification workflow

### 0. RISC-V program

- RISC-V programs must be given in `.da` format for RV64
- C programs should ideally be compiled with `-O1` before disassembly (fewer instructions, close correspondence)

Compile `foo.c` as a library, producing `foo.o`:
```shell
/path/to/riscv/bin/riscv64-unknown-linux-gnu-gcc -std=gnu99 -Wall -fno-builtin -fno-stack-protector -march=rv64g -O1 -c -o foo.o foo.c
```

Disassemble `foo.o`:
```shell
/path/to/riscv/bin/riscv64-unknown-linux-gnu-objdump -d foo.o > foo.da
```

Contents of `foo.da`:
```
foo.o:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <foo>:
   0:	00150513          	addi	a0,a0,1
   4:	00008067          	ret
```

### 1. RISC-V contract

- manually written in HOL4
- expressed using the [L3](https://acjf3.github.io/l3/index.html) model of RISC-V on pre and post states
- specifications must use variables to connect pre and post states

Example:

```sml
Definition riscv_foo_pre_def:
 riscv_foo_pre x y z (m : riscv_state) = ...
End

Definition riscv_foo_post_def:
 riscv_foo_post x y z (m : riscv_state) = ...
End
```

### 2. Lifting RISC-V program to BIR

- requires manual specification of data area addresses, affecting symbolic execution
- automatic once arguments are given inside HOL4
- lifting stores constants for BIR program, original binary program, and lifting theorem

Example:

```sml
val _ = lift_da_and_store "foo" "foo.da" da_riscv
  ((Arbnum.fromInt 0), (Arbnum.fromInt 0x30));
```

### 3. BIR contract

- manually written in HOL4
- defined as BIR expressions
- must be tailored for RISC-V contract transfer

Example:

```
Definition bir_foo_pre_def:
  bir_foo_pre x y z : bir_exp_t = ...
End

Definition bir_foo_post_def:
 bir_incr_post x y z : bir_exp_t = ...
End
```

### 4. Connecting RISC-V and BIR contracts

- RISC-V precondition implies BIR precondition
- BIR postcondition implies RISC-V postcondition
- manually written proofs in HOL4

Example:

```sml
Theorem foo_riscv_pre_imp_bir_pre_thm:
 bir_pre_riscv_to_bir (riscv_foo_pre x y z) (riscv_foo_pre x y z)
Proof
(* ... *)
QED

Theorem foo_riscv_post_imp_bir_post_thm:
 !ls. bir_post_bir_to_riscv (riscv_foo_post x y z) (\l. bir_foo_post x y z) ls
Proof
(* ... *)
QED
```

### 5. BIR symbolic execution analysis

- built on a [general theory of symbolic execution](https://arxiv.org/abs/2304.08848) instantiated for BIR
- requires manual specification of BIR conditions on memory accesses
- requires knowing BIR program address bounds
- requires manual setup in HOL4

Example:

```sml
Theorem foo_symb_analysis_thm:
 symb_hl_step_in_L_sound (bir_symb_rec_sbir bir_foo_prog_tm) (* ... *)
Proof
(* generated *)
QED
```

### 6. Specifying and proving BIR contracts using symbolic analysis results

- requires manual specification of beginning and end program labels for contract
- requires semi-manual application of symbolic soundness theorems

Example:

```sml
Theorem bir_cont_foo:
 bir_cont bir_foo_prog bir_exp_true (BL_Address (Imm64 0w))
  {BL_Address (Imm64 30w)} {} (bir_foo_pre x y z)
   (\l. if l = BL_Address (Imm64 30w) then (bir_incr_post x y z)
        else bir_exp_false)
Proof
(* application of symbolic analysis results *)
QED
```

### 7. Backlifting proven BIR contract to RISC-V binary

- built on a [general Hoare-style logic](https://doi.org/10.1007/978-3-030-58768-0_11) for unstructured programs 
- requires collecting auxiliary results from above steps
- automatic inside HOL4 if all auxiliary results have the right shape

Example:

```sml
Theorem riscv_incr_contract_thm:
 riscv_cont bir_foo_progbin 0w {30w} (riscv_foo_pre x y z) (riscv_foo_post x y z)
Proof
(* application of backlifting automation *)
QED
```
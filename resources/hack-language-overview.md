# Hack Machine Language Overview

## Three Registers

### A-Register (Address Register):

 Think of this as the "pointer" or "control" register. It has two main jobs:
    - **Addressing**: It holds the memory address that the **M** register should look at. If you want to read from or write to a specific location in data memory, you first put that address into **A**
    - **Data Storage**: It can also store general data, similar to the **D** register.

### D-Register (Data Register)

This is your primary "scratchpad" for arithmetic and logic. The ALU (Arithmetic Logic Unit) can perform operations (i.e., addition, subtraction, ANDing) using **D** as one of its inputs. Unlike **A**, **D** cannot point to a memory address.

### M-Register (Memory Register)

This is not a physical register inside the CPU; it represents the value currently stored in the memory location pointed to by the **A-register**. If the **A-register** contains 100, then **M** will hold the *contents* of `RAM[100]`.

 For example, say `RAM[14]` contains `0000100100001101` -- aka `2317` in decimal -- and you used the command `@14` to "focus" on `RAM[14]`. The **M** register would now contain the value `0000100100001101`.

## Two Instruction Types

### A-Instruction (Address Instruction)

#### Purpose

The A-instruction is used to set the value of the **A-register**. This register serves three distinct purposes:

1. Acts as a data storage for immediate values and constants
2. Sets the stage for a subsequent *C-instruction* to manipulate a specific data memory location by setting the *A-register* to the memory address of that location
3. Sets the stage for a subsequent *C-instruction* that specifies a jump by first loading the address of the instruction memory jump destination into the *A-register*

#### Syntax

It is written as `@value`,  where `value` is a number or a symbol representing a number value.

#### Binary Format

It is identified by a leading **0** bit, followed by a 15-bit value that represents the number or symbol it holds.
    - `0 v v v  v v v v  v v v v  v v v v` where `v` is either a `0` or a `1` depending on the value.

### C-Instruction (Compute Instruction)

#### Purpose

The C-instruction instructs the **ALU (Arithmetic Logic Unit)** to carry out calculations. It specifies three key operations:

1. **Computation**: What math or logic to perform (using the control bits)
2. **Destination**: Where to store the result (i.e., the **A-register**, **D-register**, or **Memory/M**).
3. **Jump**: Whether to jump to a different instruction address based on the result of the computation

#### Syntax

- `dest=comp;jump`
  - Both the *dest* and the *jump* fields are optional
  - If *dest* is empty, the `=` is omitted
  - If *jump* is empty, the `;` is omitted

#### Binary Format

It is identified by a leading **1** bit[^1], followed by a specific pattern of 15 bits[^2] that encode the computation, destination, and jump conditions.

```bash

      |---- comp ----------|-- dest --|- jump -|
1 1 1 a  c1 c2 c3 c4  c5 c6 d1 d2  d3 j1 j2 j3
```

- The leftmost bit is the *C*-instruction code, which is 1. The next two bits are not used and set to `1` by convention.
- The remaining bits form three fields that correspond to the three parts of the instruction's symbolic representation: *dest=comp;jump*
  - *comp* field instructs the ALU on what to compute and is comprised of the bolded bits below:
    - 1 1 1 **1  0 1 0 1  0 1** 0 0  0 0 0 0 -> computes the value of `D|M`
    - 1 1 1 **0  1 1 1 0  1 0** 0 0  0 0 0 0 -> computes the constant `-1`
    - This 7-bit pattern can potentially code 128 different functions, but only 28 of those are specified in the language spec. *See the [[study-notes/hack machine language#Compute Table|Compute Table]] below.*
    - *dest* field instructs where to store the computed value (ALU output). *See the [[study-notes/hack machine language#Destination Table|Destination Table]], below*
    - *jump* field specifies a jump condition, namely, which command to fetch and execute next. There are two possibilities:
      - Fetch and execute the next instruction in the program (default)
      - Fetch and execute an instruction located elsewhere in the program. In this case, we assume that the A register has been previously set to the address in which we have to jump. For example:

        - ```c
          @3
          D=M    // D=RAM[3]
          @100
          D;JEQ  // If D=0, goto 100
          @200
          0;JMP  // Goto 200 no matter what
          ```

      - *See the [[study-notes/hack machine language#Jump Table|Jump Table]] below.*

##### Compute Table

| when (a = 0) | c1  | c2  | c3  | c4  | c5  | c6  | (when a = 1) |
| -----------: | --- | --- | --- | --- | --- | --- | :----------- |
| `0`          | `1` | `0` | `1` | `0` | `1` | `0` | -            |
| `1`          | `1` | `1` | `1` | ``` | `1` | `1` | -            |
| `-1`         | `1` | `1` | `1` | `0` | `1` | `1` | -            |
| `D`          | `0` | `0` | `1` | `1` | `0` | `0` | -            |
| `A`          | `1` | `1` | `0` | `0` | `0` | `0` | `M`          |
| `!D`         | `0` | `0` | `1` | `1` | `0` | `1` | -            |
| `!A`         | `1` | `1` | `0` | `0` | `0` | `1` | `!M`         |
| `-D`         | `0` | `0` | `1` | `1` | `1` | `1` | -            |
| `-A`         | `1` | `1` | `0` | `0` | `1` | `1` | `-M`         |
| `D+1`        | `0` | `1` | `1` | `1` | `1` | `1` | -            |
| `A+1`        | `1` | `1` | `0` | `1` | `1` | `1` | `M+1`        |
| ..           | ..  | ..  | ..  | ..  | ..  | ..  | ..           |
| `D OR A`     | `0` | `1` | `0` | `1` | `0` | `1` | `D OR M`     |

##### Destination Table

| d1  | d2  | d3  | Mnemonic | Destination (where to store computed value) |
| --- | --- | --- | :------- | :------------------------------------------ |
| `0` | `0` | `0` | null     |  The value is not stored anywhere           |
| `0` | `0` | `1` | `M`      | RAM[A] (memory register addressed by A)     |
| `0` | `1` | `0` | `D`      | D register                                  |
| `0` | `1` | `1` | `MD`     | RAM[A] and D register                       |
| `1` | `0` | `0` | `A`      | A register                                  |
| `1` | `0` | `1` | `AM`     | A register and RAM[A]                       |
| `1` | `1` | `0` | `AD`     | A register and D register                   |
| `1` | `1` | `1` | `AMD`    | A register, RAM[A], and D register          |

##### Jump Table

| j1  | j2  | j3  | Mnemonic | Effect                    |
| --- | --- | --- | -------- | :------------------------ |
| `0` | `0` | `0` | null     | No jump                   |
| `0` | `0` | `1` | `JGT`    | If *out* > 0 jump         |
| `0` | `1` | `0` | `JEQ`    | If *out* = 0 jump         |
| `0` | `1` | `1` | `JGE`    | If *out* >= 0 jump        |
| `1` | `0` | `0` | `JLT`    | If *out* < 0 jump         |
| `1` | `0` | `1` | `JNE`    | If *out* != 0 jump        |
| `1` | `1` | `0` | `JLE`    | If *out* <= 0 jump        |
| `1` | `1` | `1` | `JMP`    | Jump no matter what       |

[^1]: actually, three leading `1` bits, since the second and third bits (from R->L) have no purpose in C-instructions, so, by convention, they are just set to `1`

[^2]: well, 13 bits, since the first two of the 15 bits (from R --> L) are set to `1 1` by convention

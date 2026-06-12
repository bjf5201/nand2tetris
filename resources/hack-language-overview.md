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

## Conventions

### Symbols

You can refer to memory locations (addresses) using either *constants* (i.e. `@20` for `RAM[20]`) or *symbols*.  Symbols are introduced into assembly programs in one of three ways:

1. *Predefined symbols*: A special subset of RAM addresses can be referred to by any assembly program using the following predefined symbols:
   - *Virtual registers*: To simplify things, the symbols `R0` to `R15` are predefined to refer to RAM addresses 0 to 15, respectively.
   - *Predefined pointers*: The symbols `SP`, `LCL`, `ARG`, `THIS` and `THAT` are predefined to refer to RAM addresses 0 to 4, respectively. Note that each of these memory locations has *two* labels. I.e., RAM[2] can be referred to using either `R2` or `ARG`. This will come in handy when implementing virtual machines later.
   - *I/O pointers*: The symbols `SCREEN` and `KBD` are predefined to refer to RAM addresses 16384 (0x4000) and 24576 (0x6000), respectively, which are the base addresses of the screen and keyboard memory maps. *See [[study-notes/hack machine language#Input/Output|Input/Output]] below.*
2. *Label symbols*: These are user-defined symbols, which serve to label destinations of *goto* commands. They are declared by the pseudo-command `(Name)` or `(Xxx)` where "Name"/"Xxx" are replaced by the capitalized label name. A label can be defined only once and can be used anywhere in the assembly program, even before the line in which it is defined
3. *Variable symbols*: Any user-defined symbol `Xxx` appearing in an assembly program that is not predefined and is not defined elsewhere using the `(Xxx)` command is treated as a *variable*, and is assigned a unique memory address by the assembler, starting at RAM address 16 (0x0010).

### Input/Output

The Hack computer connects to two peripherals: a screen (output) and a keyboard (input). These devices interact with the computer via *memory maps* which are synced via a continuous loop.

#### Screen

The Hack computer includes a black and white screen that is 256x512 pixels wide. That is, it holds 256 rows that have 512 pixels per row. The screen's pixels are represented by an 8K memory map that starts at `RAM[16384]`. Each row in the physical screen is represented in the RAM by 32 consecutive 16-bit words which start at the screen's top left corner.

So, the following formula can map out which word (group of 16 bits) the pixel at row *r*, column *c* is at:

`16384 + r * 32 + c//16` (here, the `//` symbol refers to dividing and tossing out the remainder. There's an actual operator for this but I can't remember the official name/symbol.)

So, for example a pixel just off-center of the screen would be mapped out like so:
row = 128
column = 260

16384 + (128 * 32) + (260 // 16)
16384 + 4096 + (260 // 16)
16384 + 4096 + 16 = `RAM[20496]`

Then, you would calculate what `c%16 = x` is and, starting from LSB -> MSB (right to left) you would turn the `x`th bit from `0` to `1`.

So, for the example above for the pixel at row 128 and column 260, you would perform the following calculation:

260 % 16 = 4

So, the word at `RAM[20496]` would be set to `0000000000001000`, or `8` in decimal.

### Keyboard

The physical keyboard interfaces with the Hack computer via a single-word memory map located at `RAM[24576]`. It only needs a single word because the Hack computer uses the 16-bit ASCII (pronounced "ask-E") code to represent the character being pressed. When no key is pressed, the code 0 appears in this location. In addition to the typical ASCII codes, the Hack computer recognizes the following key codes:

| Key pressed | Code |
| :---------- | ---: |
| newline     |  128 |
| backspace   |  129 |
| left arrow  |  130 |
| up arrow    |  131 |
| right arrow |  132 |
| down arrow  |  133 |
| home        |  134 |
| end         |  135 |
| page up     |  136 |
| page down   |  137 |
| insert      |  138 |
| delete      |  139 |
| escape      |  140 |
| f1          |  141 |
| f2          |  142 |
| f3          |  143 |
| f4          |  144 |
| f5          |  145 |
| f6          |  146 |
| f7          |  147 |
| f8          |  148 |
| f9          |  149 |
| f10         |  150 |
| f11         |  151 |
| f12         |  152 |

### File Conventions

#### File Formatting

Assembly language files are stored in text files with an `asm` extension and always begin with a capital letter (by convention). For example, `Prog.asm`, `Fill.asm`, or `Add.asm`.

#### File Contents

Each file is composed of lines of text which contain either an *instruction* or a *symbol declaration*.

**Instructions**: lines with either [[study-notes/hack machine language#A-Instruction (Address Instruction)|A-instructions]] or [[study-notes/hack machine language#C-Instruction (Compute Instruction)|C-instructions]].

**(Symbol) declaration**: symbol declaration pseudo-commands are written as `(Name)` with the symbol's name in parenthesis followed by the program command that will be stored within that symbol. This is called a `pseudo-command` since it does not generate any machine code.

#### Constants and Symbols

*Constants* must be non-negative and are always written in decimal notation. A user-defined *symbol* can be any sequence of letters, digits, underscore (`_`), dot (`.`),  dollar sign (`$`), and colon (`:`) that doesn't begin with a digit.

By convention, use UPPERCASE for symbols and lowercase for variable names.

#### Comments

Text beginning with two slashes (`//`) and ending at the end of the line is considered a comment by the assembler and is ignored.

#### White Space

Space characters and empty lines are also ignored by the assembler.

#### Case Conventions

All the assembly mnemonics must be written in uppercase. User-defined labels and variables, however, are case-sensitive. As noted above, LABELS should be uppercase and variables should be lowercase.

## Usage Notes

### Conflicting Use of the A Register

The A-register can be used to select either *data memory (RAM)* location for a subsequent C-instruction involving **M**, or an *instruction memory* location for a subsequent C-instruction involving a jump.

To prevent conflicting use of the A register, in well-written programs a C-instruction that may cause a jump should **not contain a reference to M, and vice versa**.

### Command memory addresses

Machine languages all have their own conventions when it comes to the number of memory addresses that can appear in a single command. The Hack machine language could be described as a "1/2 address machine" in this respect. This is because this simple computer is a 16-bit computer; that is, it uses a 16-bit instruction format.

Since there is no room to pack both an instruction code and a 15-bit address in the 16-bit instruction format (remember, the rightmost bit of the instruction codes is used to denote if the instruction is an *A-instruction* or a *C-instruction*), operations involving memory access will normally be specified in Hack using two instructions: an *A*-instruction to specify the address location and a *C*-instruction to specify the operation performed.[^3]

### Macro Commands

Because of the "1/2 address machine" feature described above, Hack assembly code typically ends up being an alternating sequence of *A-* and *C*-instructions. For example:

`@xxx` followed by `D=D+M`
`@yyy` followed by `0;JMP`

Note that friendlier *macro commands* like `D=D+M[xxx]` or `GOTO YYY` (where `GOTO` is a symbol? #question) can make the language a bit less tedious.

[^1]: actually, three leading `1` bits, since the second and third bits (from R->L) have no purpose in C-instructions, so, by convention, they are just set to `1`

[^2]: well, 13 bits, since the first two of the 15 bits (from R --> L) are set to `1 1` by convention

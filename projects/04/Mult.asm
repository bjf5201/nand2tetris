// Mult.asm
// Multiplication Program
// The inputs of this program are the current values stored
// in R0 and R1 (the two top RAM locations)
// The program computes the product of R0*R1 and stores the
// result in R2.
// Assumptions (you don't need to test these conditions):
//  - R0>=0
//  - R1>=0
//  - R0*R1<32768

// Pseudo-code:
// R2 = 0
// i = R1
// for (i=0, i>=0, i--) {
//    R2 = R2 + R0
//}

// Set value of R2 = 0
@R2 // #0
M=0 // #1

// Initialize @sum and set to value of R2
@R2 // #2
D=M // #3
@sum // #4
M=D // #5

// Initialize @i and set to the value of R1
@R1 // #6
D=M // #7
@i // #8
M=D // #9

// Create LOOP label
(LOOP)
    // If i === 0, jump to @END label
    @i // #10
    D=M // #11
    @END // #12
    D;JEQ // #13

    // Add R0 to @sum
    @R0 // #14
    D=M // #15
    @sum // #16
    D=D+M // #17

    // Set @sum to new total
    @sum // #18
    M=D // #19

    // Place @sum at R2
    @sum
    D=M
    @R2 // #21
    M=D // #22

    // Decrement i
    @i // #23
    M=M-1 // #24

    // Repeat forever
    @LOOP // #25
    0;JMP // #26

(END)
    @END // #27
    0;JMP // Repeat forever #28
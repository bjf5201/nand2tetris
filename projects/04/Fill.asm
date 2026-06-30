// Listen to the keyboard

// Pseudo-code
// isPressed = KBD
// screenLength = 512 * 256
// screenEnd = SCREEN + screenLength
// if (isPressed !== 0) {
//     for (i=0, i<=screenEnd, i++) {
//         i = 1 // i = bit in SCREEN memory map, and 1 turns it black
//     }
// } else {
//     end();
// }
//
// function end() { // endless loop
//     n = true
//     if (n) {
//       end()
//     }
// }

// Create necessary variables
@SCREEN
D=A  // D = 16384 (@SCREEN base address)
@pointer
M=D // @pointer = 16384 (@SCREEN base address)

@131072 // Hack Screen is made up of 256 rows of 512 bits. 256 * 512 = 131072
D=A
@SCREEN
D=D+A // Adding 131072 to screen base address of 16384
@screenEnd
M=D // sets @screenEnd variable to the end of the screen memory map

(LOOP)
  @KBD
  D=M
  @WHITE
  D;JEQ // if KBD === 0 (is not pressed) jump to (WHITE) label
  @BLACK
  0;JMP // otherwise, jump to (BLACK) label

(WHITE)
  @color
  M=0 // set @color variable to 0, the Hack computer is white at the locations of its memory map with bits equal to 0
  @FILL
  0;JMP // once @color is set, go to (FILL) label

(BLACK)
  @color
  M=1 // set @color variable to 1 to set Screen bits to black
  @FILL
  0;JMP // once @color variable is set, go to (FILL) label

(FILL)
  @color
  D=M // D = 1 if KBD is pressed, D = 0 if it is not pressed
  @pointer
  A=M
  M=D // set @pointer location to the selected @color (white or black)
  @pointer
  M=M+1 // add 1 to pointer
  D=M // set @pointer to new value (@pointer + 1)
  @screenEnd // M = @screenEnd value; D = @pointer value
  D=D-M // subtract @screenEnd from @pointer value
  @RESET
  D;JGT // if @pointer - @screenEnd > 0, go to (RESET) label
  @LOOP // otherwise, go to (LOOP) label
  0;JMP

(RESET)
  @SCREEN
  D=A
  @pointer // move @pointer back to the start of the SCREEN
  M=D
  @LOOP // go to (LOOP) label
  0;JMP






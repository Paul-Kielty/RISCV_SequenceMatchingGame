# x1 (ra) = Return address
# x2 (sp) = Stack pointer
# x3 = Memory address for display
# x4 = Data to write to display (at x3)
# x5 = Loop counter
# x6 = counter + inport peripheral address (without offset)
# x7 = temp value when drawing initial display / counter value / temporary value for adding to display
# x8 = 1 or 0 if bit in sequence should be on or off / timer display value
# x9 = counter least significant digit threshold
# x10 = oneTick countdown value
# x11 = mask for checking what bit to add to sequence
# x12 = required value to input
# x13 = value read from inport
# x14 = Lives
# x16 = score display value
# x17 = lives display value
# x18 = oneTick delay (decrease to speed up game)
# x19 = oneTick delay decrement amount (rate at which game speeds up)
# x20 = used for generating sequence

setup:
    lui x6 0x00010          # Counter peripheral address
    addi x3 x0 3            # Control0 register bits up, ce = 1,1
    sw x3 0(x6)             # Write to control0, address offset 0
    addi x3 x0 0            # Initialise memory array address in register x3
    addi x14 x0 3           # Initialise number of lives in x14
    lui x16 0x80000         # Initialise score display to 1 bit (right to left on display)
    lui x17 0xEEE00         # Value to show number of lives on display (3 blocks for 3 lives)
    sw x17 0x8(x3)          # Load starting lives to display 
    lui x18 0x0013b         # Initialise tick delay
    lui x19 0xffffb         # initialise tick decrement (-0d131072)
    addi sp zero 0x100      # Initialise stack pointer (sp)
    addi sp sp -32          # Reserve 8 x 32-bit words
    # DRAW FRAME ON LED ARRAY:
    lui x4 0xfffff          # Solid line on bits 31-7 = 0xFFFFF80
    addi x4 x4 0x7c0
    addi x4 x4 0x7c0        
    sw x4, 0x24(x3)         # Save lower line to memory x3 offset 0x24
    sw x4, 0x3c(x3)         # Save upper line to memory x3 offset 0x3c
    lui x4 0x82082
    addi x4 x4 0x080        # Line with gaps for sequence bits
    addi x5 x0 5            # Number of times to draw the line = 5
    addi x7 x0 0x28         # Temporary incrementing address for drawing initial display
    jal ra spacedLineLoop
    beq x0 x0 mainLoop      # After setup go to mainLoop
    spacedLineLoop:
        sw x4, 0(x7)
        addi x7 x7 4
        addi x5 x5 -1
        bne x5 x0 spacedLineLoop
        ret

mainLoop:
    jal ra generateSequence
    jal ra countdown
    jal ra checkCorrectInput
    bne x14 x0 mainLoop         # While number of lives remaining is not 0
    lui x15 0xDEAD0
    end: beq x0 x0 end

    generateSequence:
        sw ra 0(sp)             # Store return address on stack
        addi sp sp 4            # Increment sp by 4
        addi x12 x0 0           # Initialize required inpot value as 0
        lui x4 0x82082
        addi x4 x4 0x080
        srli x18 x18 12             # Shift delay (changes every point scored) for first input to sequence generation
        xor x20 x18 x20             # XOR delay bits that changed with previous sequence
        slli x18 x18 12             # Return x18 to correct delay value
        lw x13 0xc(x6)              # read inport and store in register 13
        lw x7, 0x8(x6)              # read xounter and store in register 7
        xor x7 x13 x7               # XOR of counter and inport is XOR'd with x20 to further randomise sequence
        xor x20 x7 x20
        andi x20 x20 0b1111         # Mask to lower 4 bits for sequence to match
        jal ra checkIfAddNote1
        jal ra checkIfAddNote2
        jal ra checkIfAddNote3
        jal ra checkIfAddNote4
        sw x4 0x34(x3)
        sw x4 0x30(x3)
        sw x4 0x2c(x3)
        addi sp sp -4
        lw ra 0(sp)
        ret
        checkIfAddNote1:
            addi x11 x0 0b1000 
            and x8 x20 x11
            beq x8 x11 addNote1
            ret
            addNote1:
                lui x7 0x38000
                or x4 x4 x7
                addi x12 x12 0x8
                ret
        checkIfAddNote2:
            addi x11 x0 0b0100 
            and x8 x20 x11
            beq x8 x11 addNote2
            ret
            addNote2:
                lui x7 0x00E00
                or x4 x4 x7
                addi x12 x12 0x4
                ret
        checkIfAddNote3:
            addi x11 x0 0b0010 
            and x8 x20 x11
            beq x8 x11 addNote3
            ret
            addNote3:
                lui x7 0x00038
                or x4 x4 x7
                addi x12 x12 0x2
                ret
        checkIfAddNote4:
            addi x11 x0 0b0001 
            and x8 x20 x11
            beq x8 x11 addNote4
            ret
            addNote4:
                addi x7 x0 0x700
                addi x7 x7 0x700
                or x4 x4 x7
                addi x12 x12 0x1
                ret


    countdown:
        sw ra 0 (sp)
        addi sp sp 4
        addi x4 x0 -1
        jal ra countDownTick
        addi sp sp -4
        lw ra 0(sp)
        ret
        countDownTick:
            sw ra 0(sp)
            addi sp sp 4
            countDownTickLoop:
                sw x4 0x1c(x3)
                add x10 x0 x18 # Set tick delay
                jal oneTickDelayLoop
                slli x4 x4 2
                bne x4 x0 countDownTickLoop
                sw x4 0x1c(x3)
                addi sp sp -4
                lw ra 0(sp)
                ret
                oneTickDelayLoop:
                    addi x10 x10 -1         # decr delay counter
                    bne  x10 x0, oneTickDelayLoop # branch: loop if x10 != 0
                    ret


    checkCorrectInput:
        lw x13 0xc(x6)              # read inport and store value in register 13
        srli x13 x13 12             # Shift right to make digit position match x12
        bne x13 x12 removeOneLife
        beq x13 x12 increaseScoreAndDifficulty
        removeOneLife:
            addi x14 x14 -1             # Decrement number of lives remaining by 1
            slli x17 x17 4              # Remove one block from life count display
            sw x17 0x8(x3)              # Update display memory
            ret
        increaseScoreAndDifficulty:
            sw x16 0(x3)              # Save score to display memory at offset 0xc
            srai x16 x16 1              # Increase score display by 1 bit (right to left) to be displayed next cycle
            add x18 x18 x19             # Decrease tick delay to increase difficulty
            ret
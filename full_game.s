# x1 (ra) = Return address
# x2 (sp) = Stack pointer
# x3 = Stores memory address for LED array
# x4 = Setup clear LED addresses / Data to write to LED Array memory (at x3)
# x5 = Stopping condition for first clearLED array loop / Control0 up & ce data / Loop count for the number of lines in drawFrame
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
# x17 = used for generating sequence
# x18 = oneTick delay (decrease to speed up game)
# x19 = oneTick delay decrement amount (rate at which game speeds up)
# x20-x23 = Values to write to memory to show lives as hearts on LED array 


setup:
    addi x3 x0 0            # Initialise x3 for addresses clearing LED array on reset
    addi x4 x0 0            # Initialise data to write to LED array memory (0 to clear display on reset)
    addi x5 x0 0x40         # Set x5 for exit condition in clearLEDArray
    clearLEDArray:
    sw x4 0(x3)
    addi x3 x3 4
    bne x3 x5 clearLEDArray
    addi x3 x0 0            # Reset x3 to 0 to store LED array memory address
    addi x5 x0 3            # Control0 register bits up, ce = 1,1
    lui x6 0x00010          # Counter peripheral address
    sw x5 0(x6)             # Write to control0, address offset 0
    addi x14 x0 3           # Initialise number of lives in x14
    lui x16 0x80000         # Initialise score display to 1 bit (right to left on display)
    lui x18 0x0013b         # Initialise tick delay
    lui x19 0xffffb         # initialise tick decrement (-0d131072)
    # Initialise lives display
    lui x20 0x28a28         
    lui x21 0x7df7c
    lui x22 0x38e38    
    lui x23 0x10410
    sw x20 0x14(x3)
    sw x21 0x10(x3)
    sw x22 0x0c(x3)
    sw x23 0x8(x3)
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
    sw ra 0 (sp)
    addi sp sp 4
    jal ra countdown        # Initial countdown for the user to get ready
    addi sp sp -4
    lw ra 0(sp)
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
        xor x17 x18 x17             # XOR delay bits that changed with previous sequence
        slli x18 x18 12             # Return x18 to correct delay value
        lw x13 0xc(x6)              # read inport and store in register 13
        lw x7, 0x8(x6)              # read xounter and store in register 7
        xor x7 x13 x7               # XOR of counter and inport is XOR'd with x17 to further randomise sequence
        xor x17 x7 x17
        andi x17 x17 0b1111         # Mask to lower 4 bits for sequence to match
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
            and x8 x17 x11
            beq x8 x11 addNote1
            ret
            addNote1:
                lui x7 0x38000
                or x4 x4 x7
                addi x12 x12 0x8
                ret
        checkIfAddNote2:
            addi x11 x0 0b0100 
            and x8 x17 x11
            beq x8 x11 addNote2
            ret
            addNote2:
                lui x7 0x00E00
                or x4 x4 x7
                addi x12 x12 0x4
                ret
        checkIfAddNote3:
            addi x11 x0 0b0010 
            and x8 x17 x11
            beq x8 x11 addNote3
            ret
            addNote3:
                lui x7 0x00038
                or x4 x4 x7
                addi x12 x12 0x2
                ret
        checkIfAddNote4:
            addi x11 x0 0b0001 
            and x8 x17 x11
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
            sw ra 0 (sp)
            addi sp sp 4
            addi x14 x14 -1                 # Decrement number of lives remaining by 1
            # Remove one heart from life count display
            slli x20 x20 6
            slli x21 x21 6
            slli x22 x22 6
            slli x23 x23 6
            sw x20 0x14(x3)                 # Update LED array memory
            sw x21 0x10(x3)
            sw x22 0x0c(x3)
            sw x23 0x8(x3)
            beq x14 x0 skipPityCountdown    # If the player has no lives remaining, skip the "pity countdown"
            jal countdown                   # If life lost, but lives are not 0, give an extra "pity countdown" before the next sequence to allow the user to catch up
            skipPityCountdown:
            addi sp sp -4
            lw ra 0(sp)
            ret
        increaseScoreAndDifficulty:
            sw x16 0(x3)                # Save score to display memory at offset 0xc
            srai x16 x16 1              # Increase score display by 1 bit (right to left) to be displayed next cycle
            add x18 x18 x19             # Decrease tick delay to increase difficulty
            ret
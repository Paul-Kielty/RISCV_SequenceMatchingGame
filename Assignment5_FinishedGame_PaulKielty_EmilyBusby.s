# EE451 - Assignment 5
# Paul Kielty & Emily Busby

# Assemply program:

# Register allocation:
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
# x14 = Life count = mainLoop exit condition -> losing state
# x15 = Max score = mainLoop exit condition -> winning state
# x16 = Player score data for LED array
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
    addi x14 x0 3           # Initialise number of lives (3) in x14 
    addi x15 x0 -1          # Initialise final score to reach
    addi x16 x0 0           # Initialise score display data (left to right on display)
    lui x18 0x0013b         # Initialise countdown tick delay
    lui x19 0xffffb         # initialise countdown tick decrement amount
    # Initialise lives display (next 8 lines)
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
    # To draw the frame on the LED array where the randomly generated sequences are shown (next 13 lines)
    lui x4 0xfffff          # Solid line on bits 31-7 = 0xFFFFF80
    addi x4 x4 0x7c0
    addi x4 x4 0x7c0        
    sw x4, 0x24(x3)         # Save lower line to memory x3 offset 0x24
    sw x4, 0x3c(x3)         # Save upper line to memory x3 offset 0x3c
    lui x4 0x82082
    addi x4 x4 0x080        # Line with spaces for sequence bits
    addi x5 x0 5            # Number of times to draw the line = 5
    addi x7 x0 0x28         # Temporary incrementing address for drawing these lines with spaces on LED array
    spacedLineLoop:         # Loop which draws the spaced lines on the display
        sw x4, 0(x7)
        addi x7 x7 4
        addi x5 x5 -1
        bne x5 x0 spacedLineLoop
    sw ra 0(sp)             # Save current return address (ra) to stack in memory at address = stack pointer (sp) and offset = 0
    addi sp sp 4            # Increase stack pointer by 4
    jal ra countdown        # Run an initial countdown for the user to get ready
    addi sp sp -4           # Decrease sp by 4
    lw ra 0(sp)             # Load ra from stack in memory at address = sp and offset = 0 
    beq x0 x0 mainLoop      # After setup, branch to mainLoop
    

mainLoop:                   # Primary gameplay loop. Exits only when the player either wins or loses
    beq x16 x15 win             # If player score (x16) == max score (x15), enter win state. Otherwise continue mainLoop
    jal ra generateSequence     # Generate a pseudo-random sequence for the player to match and save it to the LED array
    jal ra countdown            # Run a countdown to give the player time to match the sequence on inport
    jal ra checkCorrectInput    # Check if the inport value matches the sequence, and takes action based off result
    bne x14 x0 mainLoop         # If the player has lives remaining, repeat mainLoop. Otherwise continue into lose state
    lui x1 0xDEAD0              # Write to register x1 to show the player they have lost
    end:                        # End loops indefinitely once player either wins or loses
        beq x0 x0 end
    win:                        # In win state, write "WINNER!" message to LED array
        addi x4 x0 0
        sw x4, 0x3c(x3)
        lui x4 0x45451
        addi x4 x4 0x7ba
        sw x4, 0x38(x3)
        lui x4 0x45659
        addi x4 x4 0x42a
        sw x4, 0x34(x3)
        lui x4 0x55555
        addi x4 x4 0x73a
        sw x4, 0x30(x3)
        lui x4 0x554d3
        addi x4 x4 0x430
        sw x4, 0x2c(x3)
        lui x4 0x29451
        addi x4 x4 0x7aa
        sw x4, 0x28(x3)
        addi x4 x0 0
        sw x4, 0x24(x3)
        beq x0 x0 end

    generateSequence:          
        sw ra 0(sp)            
        addi sp sp 4            
        addi x12 x0 0           
        lui x4 0x82082
        addi x4 x4 0x080
        # Pseudo-random generation (next 8 lines)
        srli x18 x18 12             # Shift delay (changes every point scored) for first input to sequence generation
        xor x17 x18 x17             # XOR relevant bits from this delay with previous sequence
        slli x18 x18 12             # Set x18 back to the correct delay value
        lw x13 0xc(x6)              # read inport and store in register 13
        lw x7, 0x8(x6)              # read counter and store in register 7
        xor x7 x13 x7               # XOR of counter and inport is XOR'd with x17 to further randomise sequence
        xor x17 x7 x17
        andi x17 x17 0b1111         # Mask to lower 4 bits for sequence to match
        # (Next 4 lines) Check generated sequence for each element (note). Display value x4 and required inport x12 are updated accordingly
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
        addi x4 x0 -1                  # Set full countdown line
        jal ra countDownTick           
        addi sp sp -4
        lw ra 0(sp)
        ret
        countDownTick:
            sw ra 0(sp)
            addi sp sp 4
            countDownTickLoop:         # Shifts the countdown left by 2 bits every "tick"
                sw x4 0x1c(x3)
                add x10 x0 x18         # Set the delay of each tick with value in x18
                jal oneTickDelayLoop
                slli x4 x4 2
                bne x4 x0 countDownTickLoop
                sw x4 0x1c(x3)
                addi sp sp -4
                lw ra 0(sp)
                ret
                oneTickDelayLoop:
                    addi x10 x10 -1               # decr delay counter
                    bne  x10 x0, oneTickDelayLoop # branch: loop if x10 != 0
                    ret


    checkCorrectInput:
        lw x13 0xc(x6)              # Read inport and store value in register 13
        srli x13 x13 12             # Shift right to make digit position match x12
        bne x13 x12 removeOneLife   # If inport incorrect, remove one life from the player and return to mainLoop 
        beq x13 x12 increaseScoreAndDifficulty  # If inport correct, increase the players score and difficulty by speeding up coundown
        removeOneLife:
            sw ra 0 (sp)
            addi sp sp 4
            addi x14 x14 -1          # Decrement number of lives remaining by 1
            # Remove one heart from life count display (next 8 lines)
            slli x20 x20 6
            slli x21 x21 6
            slli x22 x22 6
            slli x23 x23 6
            sw x20 0x14(x3)                 
            sw x21 0x10(x3)
            sw x22 0x0c(x3)
            sw x23 0x8(x3)
            beq x14 x0 skipPityCountdown    # If the player has no lives remaining, skip the "pity countdown"
            jal countdown                   # If life lost, give an extra grace period or "pity countdown" before the next sequence to allow the user to catch up
            skipPityCountdown:
            addi sp sp -4
            lw ra 0(sp)
            ret
        increaseScoreAndDifficulty:
            bne x16 x0 skipAddFirstPoint    # If player scored their first point, x16 is set to 0x8000000, for subsequent points x16 is arithmetic shifted right
            lui x16 0x80000                 # First point, so set score data to assert 1 LED when saved to memory
            sw x16 0(x3)                    # Save score to LED array memory with offset 0
            ret                             # Return to mainLoop after adding first point
            skipAddFirstPoint:                                 
            srai x16 x16 1                  # Increment score LEDs by 1 bit (right to left)
            sw x16 0(x3) 
            add x18 x18 x19                 # Decrease tick delay to increase difficulty
            ret                             # Return to mainLoop after incrementing score bits asserted 


# ============================
# Venus 'dump' program binary. No of instructions n = 176
# 00000193
# 00000213
# 04000293
# 0041a023
# 00418193
# fe519ce3
# 00000193
# 00300293
# 00010337
# 00532023
# 00300713
# fff00793
# 00000813
# 0013b937
# ffffb9b7
# 28a28a37
# 7df7cab7
# 38e38b37
# 10410bb7
# 0141aa23
# 0151a823
# 0161a623
# 0171a423
# 10000113
# fe010113
# fffff237
# 7c020213
# 7c020213
# 0241a223
# 0241ae23
# 82082237
# 08020213
# 00500293
# 02800393
# 0043a023
# 00438393
# fff28293
# fe029ae3
# 00112023
# 00410113
# 15c000ef
# ffc10113
# 00012083
# 00000263
# 00f80e63
# 068000ef
# 144000ef
# 194000ef
# fe0718e3
# dead00b7
# 00000063
# 00000213
# 0241ae23
# 45451237
# 7ba20213
# 0241ac23
# 45659237
# 42a20213
# 0241aa23
# 55555237
# 73a20213
# 0241a823
# 554d3237
# 43020213
# 0241a623
# 29451237
# 7aa20213
# 0241a423
# 00000213
# 0241a223
# fa0008e3
# 00112023
# 00410113
# 00000613
# 82082237
# 08020213
# 00c95913
# 011948b3
# 00c91913
# 00c32683
# 00832383
# 0076c3b3
# 0113c8b3
# 00f8f893
# 028000ef
# 044000ef
# 060000ef
# 07c000ef
# 0241aa23
# 0241a823
# 0241a623
# ffc10113
# 00012083
# 00008067
# 00800593
# 00b8f433
# 00b40463
# 00008067
# 380003b7
# 00726233
# 00860613
# 00008067
# 00400593
# 00b8f433
# 00b40463
# 00008067
# 00e003b7
# 00726233
# 00460613
# 00008067
# 00200593
# 00b8f433
# 00b40463
# 00008067
# 000383b7
# 00726233
# 00260613
# 00008067
# 00100593
# 00b8f433
# 00b40463
# 00008067
# 70000393
# 70038393
# 00726233
# 00160613
# 00008067
# 00112023
# 00410113
# fff00213
# 010000ef
# ffc10113
# 00012083
# 00008067
# 00112023
# 00410113
# 0041ae23
# 01200533
# 01c000ef
# 00221213
# fe0218e3
# 0041ae23
# ffc10113
# 00012083
# 00008067
# fff50513
# fe051ee3
# 00008067
# 00c32683
# 00c6d693
# 00c69463
# 04c68263
# 00112023
# 00410113
# fff70713
# 006a1a13
# 006a9a93
# 006b1b13
# 006b9b93
# 0141aa23
# 0151a823
# 0161a623
# 0171a423
# 00070463
# f6dff0ef
# ffc10113
# 00012083
# 00008067
# 00081863
# 80000837
# 0101a023
# 00008067
# 40185813
# 0101a023
# 01390933
# 00008067

# ============================
# Program binary formatted, for use in vicilogic online RISC-V processor
# i.e, 8x32-bit instructions, 
# format: m = mod(n/8)+1 = mod(11/8)+1
# 0000019300000213040002930041a02300418193fe519ce30000019300300293
# 000103370053202300300713fff00793000008130013b937ffffb9b728a28a37
# 7df7cab738e38b3710410bb70141aa230151a8230161a6230171a42310000113
# fe010113fffff2377c0202137c0202130241a2230241ae238208223708020213
# 00500293028003930043a02300438393fff28293fe029ae30011202300410113
# 15c000efffc10113000120830000026300f80e63068000ef144000ef194000ef
# fe0718e3dead00b700000063000002130241ae23454512377ba202130241ac23
# 4565923742a202130241aa235555523773a202130241a823554d323743020213
# 0241a623294512377aa202130241a423000002130241a223fa0008e300112023
# 0041011300000613820822370802021300c95913011948b300c9191300c32683
# 008323830076c3b30113c8b300f8f893028000ef044000ef060000ef07c000ef
# 0241aa230241a8230241a623ffc1011300012083000080670080059300b8f433
# 00b4046300008067380003b70072623300860613000080670040059300b8f433
# 00b404630000806700e003b70072623300460613000080670020059300b8f433
# 00b4046300008067000383b70072623300260613000080670010059300b8f433
# 00b4046300008067700003937003839300726233001606130000806700112023
# 00410113fff00213010000efffc1011300012083000080670011202300410113
# 0041ae230120053301c000ef00221213fe0218e30041ae23ffc1011300012083
# 00008067fff50513fe051ee30000806700c3268300c6d69300c6946304c68263
# 0011202300410113fff70713006a1a13006a9a93006b1b13006b9b930141aa23
# 0151a8230161a6230171a42300070463f6dff0efffc101130001208300008067
# 00081863800008370101a02300008067401858130101a0230139093300008067
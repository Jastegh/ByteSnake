#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2020 University of Alberta
# Copyright 2022 Yufei Chen
# TODO: claim your copyright
# This software is distributed to students in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the disclaimer below in the documentation
#    and/or other materials provided with the distribution.
#
# 2. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#-------------------------------
# Lab_Snake_Game Lab
#
# Author: Jastegh Singh
# Date:   24th March, 2024
# TA:     Christiaan/ Sachin/ Aaron
#
#-------------------------------

.include "common.s"

.data

keyInput:         .word     0
INITIAL_STRING:      .asciz  "Please enter 1, 2 or 3 to choose the level and start the game"
GAME_TIME:               .word    0
BONUS_TIME:         .word    0
SNAKE_HEAD:          .asciz  "@"
SNAKE_BODY:          .asciz  "*"
SNAKE_BODY_1:        .asciz  "1"
SNAKE_BODY_2:        .asciz  "2"
SNAKE_BODY_3:        .asciz  "3"


POINTS:              .word    0
SNAKE_HEAD_ROW:          .word  5
SNAKE_HEAD_COL:           .word  10

COMPONENT_ONE_ROW:    .word 5
COMPONENT_ONE_COL:    .word 9

COMPONENT_TWO_ROW:    .word 5
COMPONENT_TWO_COL:    .word 8

COMPONENT_THREE_ROW:    .word 5
COMPONENT_THREE_COL:    .word 7

COMPONENT_FOUR_ROW:     .word 5
COMPONENT_FOUR_COL:     .word 6
SNAKE_TAIL_SPACE:       .asciz " "

SECONDS_STRING:         .asciz   "seconds"
POINTS_STRING:          .asciz    "points"


APPLE_ROW:              .word 0
APPLE_COL:	      .word 0

APPLE:               .asciz  "a"
FLAG:               .word     0                    # to check for timer
currentDirection:   .word  0                       #  store the current direction 

.align 2

DISPLAY_CONTROL:    .word 0xFFFF0008
DISPLAY_DATA:       .word 0xFFFF000C
INTERRUPT_ERROR:	.asciz "Error: Unhandled interrupt with exception code: "
INSTRUCTION_ERROR:	.asciz "\n   Originating from the instruction at address: "

Brick:      .asciz "#"


.text



snakeGame:
	addi sp, sp ,-4
	sw sp, 0(sp)
	
	# Enabling user-level interrupts
	csrrwi zero, 0, 0x01                                                  # making the 0th bit 1    
	
	
	# Enabling user-level timer interrupts and user-level external interrupts
	csrwi 4, 0x110	                                                      # changing the 4th and 8th bit to 1  
	
	# Storing the address of the handler in utvec (CSR 5)
	la t0, handler
	csrw t0, 5	
	
	# Setting the bit 1 of this register Keyboard control to 1
	li t1, 0xFFFF0000
	li t2,2
	sw t2,0(t1)                                                           # bit 1 of this register set to 1
	
	
	# Printing  the initial string - Preparation screen
	la a0, INITIAL_STRING
	li a1, 0
	li a2, 0
	jal printStr

	lw ra , 0(sp)
	addi sp , sp , 4
	
	
	# Checking what level was selected
	li t0,0x31                                                            # 1
	li t1,0x32                                                            # 2
	li t2,0x33                                                            # 3
	j loopLevel
	
	
loopLevel:
        # Keeps taking input until valid Level 1,2 0r 3 is selected
	la t3, keyInput                                                       # loading the address of the global variable keyInput
	lw t4, 0(t3)                                                          # loading the user input value in t4
	
	beq t0,t4, levelOne
	beq t1,t4, levelTwo
	beq t2,t4, levelThree
	
	j loopLevel
	
levelOne:
	# If Level 1 is selected set the time and and bonus time for level one
	
	la t0, GAME_TIME                                                        # load the address of GAME_TIME

	li t1, 120
	sw t1, 0(t0)

	la t2, BONUS_TIME	                                                # load the address of BONUS_TIME
	li t3, 8
	sw t3, 0(t2)
	
	j buildGame

levelTwo:
	# If Level 2 is selected set the time and and bonus time for level two
	
	la t0, GAME_TIME               						# load the address of GAME_TIME
	li t1, 30
	sw t1, 0(t0)
	
	la t2, BONUS_TIME	                                                # load the address of BONUS_TIME
	li t3, 5
	sw t3, 0(t2)
	
	j buildGame
	
levelThree:
	# If Level 3 is selected set the time and and bonus time for level three
	
	la t0, GAME_TIME              						#  load the address of GAME_TIME
	li t1, 15
	sw t1, 0(t0)
	
	la t2, BONUS_TIME	                                                # load the address of BONUS_TIME
	li t3, 3
	sw t3, 0(t2)
	
	j buildGame
	

#-------------------------------------------------------------------------------
# buildGame
#   This function clears the Preparation screen and loads the Game screen, and
#   builds the structure of the game. 
# 
#-------------------------------------------------------------------------------
#
# Register Usage:
#       Temporary registers are reused within the function
#
#	t0: loads the address of SNAKE_HEAD_ROW
#	s1: holds the address of SNAKE_HEAD_COL
#	t2: holds the value of SNAKE_HEAD_ROW
#	t3: holds the value of SNAKE_HEAD_COL
#	t4: loads the address of APPLE_ROW
#	t5: loads the address of APPLE_COL
#	t6: loads the value of APPLE_ROW
#	a1: loads the value of APPLE_COL
#
#-------------------------------------------------------------------------------
buildGame:
	addi sp, sp ,-4
	sw sp, 0(sp)
	
	# Clearing the Preparation screen 
	li a0, 100
	li a1, 0
	li a2, 0
	li a3, 0x20
	jal ra, printMultipleSameChars
	
	# Building the walls/boundaries
	jal ra, printAllWalls
	
	# Print suffix strings "seconds" and "points"
	la a0, POINTS_STRING
	li a1, 0
	li a2, 28
	jal ra, printStr
	
	la a0, SECONDS_STRING
	li a1, 1
	li a2, 28
	jal ra, printStr
	
	
	# TIME INTERRUPT
	li s1,0xFFFF0018                             					# TIME
   	li s2,0xFFFF0020                                                                # TIMECMP
   	
   	# Updating time 
   	lw s3, 0(s1)                                #  current time 
   	addi s5, s3, 1000                           #  increment 1 sec(1000ms)
   	sw s5, 0(s2)                                #  store value to timecmp
	
	# Printing the first apple
	jal ra, printApple                             
	
	# Draw the snake at the m iddle of the screen	
	jal ra, drawSnake
	
	lw ra, 0(sp)
	addi sp, sp, 4
	
	j waitfortimer
	
waitfortimer:
	la t0, FLAG
	lw t1, 0(t0)
	li t2, 1
	beq t1, t2, gameLoop                	
	j waitfortimer
	
#-------------------------------------------------------------------------------
# printApple
#   This function prints the apple using 2 random coordinates generated by 
#   random function
# 
#-------------------------------------------------------------------------------
#
# Register Usage:
#
#	s0: loads the first random number genrerated using random function
#	s0: loads the second random number genrerated using random function
#	t0: loads the address of Apple character(a)
#	a0: loads the value of Apple character(a)
#	a1: stores the row crdinate(s0)
#	a2: stores the column crdinate(s1)
#
#-------------------------------------------------------------------------------
printApple:
	addi sp, sp ,-12
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	

	# APPLE
	jal ra, random
	mv s0, a0                                     # row
	addi s0,s0,1                                  # add 1
	
	# updating the row in global variable
	la t0, APPLE_ROW
	sw s0, 0(t0)
	
	jal ra, random
	mv s1, a0                                     #column	
	addi s1,s1, 1                                 #add 1
	
	# updating the column in global variable
	la t1, APPLE_COL
	sw s1, 0(t1)
	
	# Print apple
	la t0, APPLE
	lb a0, 0(t0)
	mv a1,s0
	mv a2,s1
	jal ra, printChar
	
	
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw ra, 0(sp)
	addi sp,sp 12
	
	ret

#-------------------------------------------------------------------------------
# timeCheck
#   This function whether the GAME_TIME is 0 and terminates the game accordingly
# 
#-------------------------------------------------------------------------------
#
# Register Usage:
#
#	t0: loads the value of global variable GAME_TIME	
#
#-------------------------------------------------------------------------------
timeCheck:
	lw t0, GAME_TIME
	beqz t0, endGame
	ret

#-------------------------------------------------------------------------------
# wallCheck
#   This function checks whether the sanke collides/hits the walls
#   and then ends the game accordingly. 
# 
#-------------------------------------------------------------------------------
#
# Register Usage:
#       Temporary registers are reused within the function
#
#	t0: loads the value of SNAKE_HEAD_ROW
#	t1: loads the value of SNAKE_HEAD_COL
# 	t2: stores the integer 10 to check row condition
#	t3: stores the integer 20 to check column condition
#	t4: stores the integer 0 to check row and column conditions
#
#-------------------------------------------------------------------------------
wallCheck:
	lw t0, SNAKE_HEAD_ROW
	lw t1, SNAKE_HEAD_COL
	
	li t2, 10
	li t3, 20
	li t4, 0
	# row condition
	bge  t0, t2, endGame
	ble t0,t4 endGame
	
	# column condition
	bge t1, t3, endGame
	ble t1,t4 endGame
	ret
endGame:
	li a7, 10 
	ecall
	




#-------------------------------------------------------------------------------
# convertToStringPoints
#   This function converts the points as number to characters and then prints them 
# 
#-------------------------------------------------------------------------------
#
# Register Usage:
#       Temporary registers are reused within the function
#
#	t0: loads the value of POINTS
#	s0: stores the integer 10 used in calculations
# 	s2: used for copying register 
#	s3: stores the length of the digit
#	s4: used for copying register 
#	s5: used for copying register 
#	a0: stores the value to be printed
#       a1: row number 
# 	a2: column number
#
#-------------------------------------------------------------------------------
convertToStringPoints:
	addi sp , sp , -24
	sw ra,0(sp)
	sw s0 , 4(sp)
	sw s2 , 8(sp)
	sw s3 , 12(sp)
	sw s4 , 16(sp)
	sw s5 , 20(sp)
	
	li s0, 10 
	
	# legth counter
	li s3, 0					
	
	lw t0, POINTS
	mv t1, t0
	
	li t2, 1
	li t3, 2
	li t4, 3
	
	length2:
		# Find the length of the number 
		div t1, t1, s0			 
		addi s3, s3, 1
		bnez t1, length2		

	
	
	beq s3, t2, one_digit1
	beq s3, t3, two_digit2
	beq s3, t4 three_digit3
	
	one_digit1:
		# If 1 digit points 
		addi t0, t0, 48							# Converting digit to Ascii
		
		mv a0, t0
		li a1, 0
		li a2, 25
		jal ra, printChar	
		
		li t0, 0
		addi t0, t0, 48                                                 # Converting digit to Ascii	
		
		mv a0, t0
		li a1, 0
		li a2, 24
		jal ra, printChar
		
		
		li t0, 0
		addi t0, t0, 48							# Converting digit to Ascii
		
		mv a0, t0
		li a1, 0
		li a2, 23
		jal ra, printChar
		
		
		j regis
		
	two_digit2:
		# If 2 digit points 
		rem t1, t0, s0 
		div t3, t0, s0 
		mv s2, t1 
		mv s3, t3 
		li s4, 0
		
		addi s2, s2, 48                                                     # Converting digit to Ascii
		addi s3, s3, 48							    # Converting digit to Ascii
		addi s4, s4, 48							    # Converting digit to Ascii
		
		# last digit stop condition
		#li t5, 48
		#beq s2, t5, stop
		#stop:
			#ret
			
		mv a0, s2
		li a1, 0
		li a2, 25
		jal ra, printChar
		
		mv a0, s3
		li a1, 0
		li a2, 24
		jal ra, printChar
		
		
		mv a0, s4
		li a1, 0
		li a2, 23		
		jal ra, printChar
		
		
		j regis
		
		
	
	three_digit3:
		# If 3 digit points 
		rem t1, t0, s0 
		div t3, t0, s0 

		mv s3, t1

		rem t1, t3, s0 
		div t2, t3, s0 
		
		mv s4, t1	
		mv s5, t2 	
		
		addi s3, s3, 48								# Converting digit to Ascii
		addi s4, s4, 48								# Converting digit to Ascii
		addi s5, s5, 48								# Converting digit to Ascii
		

		mv a0, s3
		li a1, 0
		li a2, 25
		jal ra, printChar

		
		mv a0, s4
		li a1, 0
		li a2, 24
		jal ra, printChar
		
		
		mv a0, s5
		li a1, 0
		li a2, 23
		jal ra, printChar
		
		j regis
		
	regis:
		lw ra,0(sp)	
		lw s0 , 4(sp)
		lw s2 , 8(sp)
		lw s3 , 12(sp)
		lw s4 , 16(sp)
		lw s5 , 20(sp)	
		addi sp , sp , 24
		ret


#-------------------------------------------------------------------------------
# convertToStringPoints
#   This function converts the GAME_TIME as number to characters and then prints them 
# 
#-------------------------------------------------------------------------------
#
# Register Usage:
#       Temporary registers are reused within the function
#
#	t0: loads the value of GAME_TIME
#	s0: stores the integer 10 used in calculations
# 	s2: used for copying register 
#	s3: stores the length of the digit
#	s4: used for copying register 
#	s5: used for copying register 
#	a0: stores the value to be printed
#       a1: row number 
# 	a2: column number
#
#-------------------------------------------------------------------------------
convertToStringTime:
	addi sp , sp , -24
	sw ra,0(sp)
	sw s0 , 4(sp)
	sw s2 , 8(sp)
	sw s3 , 12(sp)
	sw s4 , 16(sp)
	sw s5 , 20(sp)
	
	li s0, 10 
	
	# Length count
	li s3, 0					
	
	lw t0, GAME_TIME
	mv t1, t0
	
	li t2, 1
	li t3, 2
	li t4, 3
	
	length:
		# Find the length of the number 
		div t1, t1, s0			
		addi s3, s3, 1
		bnez t1, length		

	
	compare:
		beq s3, t2, one_digit
		beq s3, t3, two_digit
		beq s3, t4 three_digit
	
	one_digit:
		# If 1 digit time 
		addi t0, t0, 48                                           	# Converting digit to Ascii
		
		mv a0, t0
		li a1, 1
		li a2, 25
		jal ra, printChar
		
		
		li t0, 0
		addi t0, t0, 48                                                  # Converting digit to Ascii
		
		mv a0, t0
		li a1, 1
		li a2, 24
		jal ra, printChar
		
		
		
		li t0, 0
		addi t0, t0, 48							 # Converting digit to Ascii
		
		mv a0, t0
		li a1, 1
		li a2, 23
		jal ra, printChar
		
		j reg
		
	two_digit:
		# If 2 digit time 
		rem t1, t0, s0 
		div t3, t0, s0 
		mv s2, t1 
		mv s3, t3 
		li s4, 0
		
		
		addi s2, s2, 48							 # Converting digit to Ascii
		addi s3, s3, 48							 # Converting digit to Ascii
		addi s4, s4, 48							 # Converting digit to Ascii
		
		# last digit stop condition
		#li t5, 48
		#beq s2, t5, stop
		#stop:
			#ret
			
		mv a0, s2
		li a1, 1
		li a2, 25
		jal ra, printChar
		
		mv a0, s3
		li a1, 1
		li a2, 24	
		jal ra, printChar
		
		mv a0, s4
		li a1, 1
		li a2, 23	
		jal ra, printChar
		
		j reg
		
		
	
	three_digit:
		# If 3 digit time 
		rem t1, t0, s0 
		div t3, t0, s0 
		mv s3, t1

		rem t1, t3, s0
		div t2, t3, s0 
		
		mv s4, t1	
		mv s5, t2 	
		
		addi s3, s3, 48								# Converting digit to Ascii
		addi s4, s4, 48								# Converting digit to Ascii
		addi s5, s5, 48								# Converting digit to Ascii
		

		mv a0, s3
		li a1, 1
		li a2, 25	
		jal ra, printChar
		

		mv a0, s4
		li a1, 1
		li a2, 24	
		jal ra, printChar
		

		mv a0, s5
		li a1, 1
		li a2, 23	
		jal ra, printChar
		j reg
		
	reg:
		lw ra,0(sp)	
		lw s0 , 4(sp)
		lw s2 , 8(sp)
		lw s3 , 12(sp)
		lw s4 , 16(sp)
		lw s5 , 20(sp)
		
		addi sp , sp , 24
		
		ret
	
#-------------------------------------------------------------------------------
# eatApple
#   This function checks whether the snae head and apple collide, and if they do update
#   the time and points
#
# 
#-------------------------------------------------------------------------------
#
# Register Usage:
#       Temporary registers are reused within the function
#
#	t0: loads the address of SNAKE_HEAD_ROW
#	s1: holds the address of SNAKE_HEAD_COL
#	t2: holds the value of SNAKE_HEAD_ROW
#	t3: holds the value of SNAKE_HEAD_COL
#	t4: loads the address of APPLE_ROW
#	t5: loads the address of APPLE_COL
#	t6: loads the value of APPLE_ROW
#	a1: loads the value of APPLE_COL
#
#-------------------------------------------------------------------------------	
eatApple:
	addi sp, sp, -40	
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s3, 16(sp)
	sw s4, 20(sp)
	sw s5, 24(sp)
	sw s6, 28(sp)
	sw s7, 32(sp)
	lw s8, 36(sp)
	
	la s0, SNAKE_HEAD_ROW
	la s1, SNAKE_HEAD_COL
	lw s2, 0(s0)
	lw s3, 0(s1)
	
	la s4, APPLE_ROW
	la s5, APPLE_COL
	lw s6, 0(s4)
	lw a1, 0(s5)
	
	beq s2,s6, secondcheck
	j saveregistor 
secondcheck:
	beq s3,a1, printAgain
	j saveregistor
	
printAgain:
	
	#add bonus time
	lw s4, BONUS_TIME
	
	la s5, GAME_TIME
	lw s6, 0(s5)
	
	add s6, s6, s4
	sw s6, 0(s5)
	
	# add points
	la s7, POINTS
	lw s8, 0(s7)
	addi s8,s8, 1
	sw s8,0(s7)
	
	# print new apple	
	jal printApple	
	
	j saveregistor 
	
saveregistor:
	lw ra, 0(sp)
    	lw s0, 4(sp)
    	lw s1, 8(sp)
    	lw s2, 12(sp)
    	lw s3, 16(sp)
    	lw s4, 20(sp)
    	lw s5, 24(sp)
    	lw s6, 28(sp)
    	lw s7, 32(sp)
    	lw s8, 36(sp)
    	
	addi sp, sp, 40
	
    	ret
	
	

gameLoop:	

	j direction

#-------------------------------------------------------------------------------
# direction:
#   This function checks for the direction input and all the stop condition for
#   the game
#
#-------------------------------------------------------------------------------	
direction:
	# Print the Game time on Display  
	addi sp, sp , -4
	sw ra, 0(sp)
	jal ra, convertToStringTime
	lw ra, 0(sp)
	addi sp, sp, 4
	
	# Checking if the time has finished 
	addi sp, sp , -4
	sw ra, 0(sp)
	jal ra, timeCheck
	lw ra, 0(sp)
	addi sp, sp, 4
	
	# Print the points on the Display 
	addi sp, sp , -4
	sw ra, 0(sp)
	jal ra, convertToStringPoints
	lw ra, 0(sp)
	addi sp, sp, 4
	
	
	# Checking if the snake hits the wall
	addi sp, sp , -4
	sw ra, 0(sp)
	jal ra, wallCheck                              
	lw ra, 0(sp)
	addi sp, sp, 4
	
	# Checking if the snake eats(collides) with the apple 
	addi sp, sp , -4
	sw ra, 0(sp)                                                     
	jal ra, eatApple
	lw ra, 0(sp)
	addi sp, sp, 4
	
	# Check the user input for direction of the snake ( w, a, s, d)
	la t5, keyInput
	lw t6,0(t5)
		
	li t1,0x77                              #w #up
	beq t1,t6, moveUp
	
	li t2,0x61                             #a #left
	beq t2,t6, moveLeft
	
	li t3,0x73                              #s #down
	beq t3,t6, moveDown
	
	li t4,0x64                              #d #right
	beq t4,t6, moveRight	
	

	j moveRight
	j waitfortimer
	
	


				
moveRight:
	# Moves the snake in right direction by adding 1 column 
	  
	la s0, SNAKE_HEAD_COL
	lw s2, 0(s0) 
	la s1, SNAKE_HEAD_ROW      
	lw s3, 0(s1)
	
	
	
	la s4, COMPONENT_ONE_COL
	lw s6, 0(s4)                                                             # value for the next component
	sw s2, 0(s4)
	la s5, COMPONENT_ONE_ROW
	lw s7, 0(s5)                                                             # value for the next component
	sw s3, 0(s5)
	
	addi s2, s2,1           						 # update head by adding 1 column
	sw s2, 0(s0)
	
	la s8, COMPONENT_TWO_COL
	lw s10, 0(s8)                                                            # value for the next component
	sw s6, 0(s8)
	la s9, COMPONENT_TWO_ROW
	lw s11, 0(s9)                                                            # value for the next component
	sw s7, 0(s9)
	
	
	la t0, COMPONENT_THREE_COL
	lw t2, 0(t0)                                                             # value for the next component
	sw s10, 0(t0)
	la t1, COMPONENT_THREE_ROW
	lw t3, 0(t1)                                                            # value for the next component
	sw s11, 0(t1)
	
	# Clear the last component 
         mv a1, t3
	 mv a2, t2
	 li a0, 0x20
	 jal printChar
	jal drawSnake
	
	la t0, FLAG
	sw zero,0(t0)
	
	j waitfortimer
    	
moveLeft:
	# Moves the snake in left direction by subtracting 1 column 
	la s0, SNAKE_HEAD_COL
	lw s2, 0(s0) 
	la s1, SNAKE_HEAD_ROW      
	lw s3, 0(s1)
		
	
	la s4, COMPONENT_ONE_COL
	lw s6, 0(s4)                                                       # value for the next component
	sw s2, 0(s4)
	la s5, COMPONENT_ONE_ROW
	lw s7, 0(s5)                                                       # value for the next component
	sw s3, 0(s5)
	
	addi s2, s2,-1                                                     # update head by subtracting 1 column
	sw s2, 0(s0)
	
	la s8, COMPONENT_TWO_COL
	lw s10, 0(s8)                                                      # value for the next component
	sw s6, 0(s8)
	la s9, COMPONENT_TWO_ROW
	lw s11, 0(s9)                                                      # value for the next component
	sw s7, 0(s9)
	
	
	la t0, COMPONENT_THREE_COL
	lw t2, 0(t0)                                                       # value for the next component
	sw s10, 0(t0)
	la t1, COMPONENT_THREE_ROW
	lw t3, 0(t1)                                                       # value for the next component
	sw s11, 0(t1)
	
	# Clear the last component 
         mv a1, t3
	 mv a2, t2
	 li a0, 0x20
	 jal printChar


	jal drawSnake
	
	la t0, FLAG
	sw zero,0(t0)
		j waitfortimer
    	

moveUp:
	# Moves the snake in upwards direction by subtracting 1 row 
	la s0, SNAKE_HEAD_COL
	lw s2, 0(s0) 
	la s1, SNAKE_HEAD_ROW      
	lw s3, 0(s1)
	
	
	la s4, COMPONENT_ONE_COL
	lw s6, 0(s4)                                                      # value for the next component
	sw s2, 0(s4)
	la s5, COMPONENT_ONE_ROW
	lw s7, 0(s5)                                                      # value for the next component
	sw s3, 0(s5)
	
	addi s3, s3,-1                                                    # update head by subtracting 1 row
	sw s3, 0(s1)
	
	la s8, COMPONENT_TWO_COL
	lw s10, 0(s8)                                                     # value for the next component
	sw s6, 0(s8)
	la s9, COMPONENT_TWO_ROW
	lw s11, 0(s9)                                                     # value for the next component
	sw s7, 0(s9)
	
	
	la t0, COMPONENT_THREE_COL
	lw t2, 0(t0)                      				  # value for the next component
	sw s10, 0(t0)
	la t1, COMPONENT_THREE_ROW
	lw t3, 0(t1)                       			          # value for the next component
	sw s11, 0(t1)
	
	# Clear the last component 
         mv a1, t3
	 mv a2, t2
	 li a0, 0x20
	 jal printChar


	jal drawSnake
	
	la t0, FLAG
	sw zero,0(t0)
	
	j waitfortimer

moveDown:
	# Moves the snake in downwards direction by adding 1 down 
	la s0, SNAKE_HEAD_COL
	lw s2, 0(s0) 
	la s1, SNAKE_HEAD_ROW      
	lw s3, 0(s1)
	
	
	la s4, COMPONENT_ONE_COL
	lw s6, 0(s4)                                                             # value for the next component
	sw s2, 0(s4)
	la s5, COMPONENT_ONE_ROW
	lw s7, 0(s5)                                                             # value for the next component
	sw s3, 0(s5)
	
	addi s3, s3,1           						 # update head by adding 1 row
	sw s3, 0(s1)
	
	la s8, COMPONENT_TWO_COL
	lw s10, 0(s8)                                                            # value for the next component
	sw s6, 0(s8)
	la s9, COMPONENT_TWO_ROW
	lw s11, 0(s9)                                                            # value for the next component
	sw s7, 0(s9)
	
	
	la t0, COMPONENT_THREE_COL
	lw t2, 0(t0)                                                             # value for the next component
	sw s10, 0(t0) 
	la t1, COMPONENT_THREE_ROW
	lw t3, 0(t1)                                                              # value for the next component
	sw s11, 0(t1)
	
	# Clear the last component 
         mv a1, t3
	 mv a2, t2
	 li a0, 0x20
	 jal printChar
	 
	jal drawSnake	
	
	la t0, FLAG
	sw zero,0(t0)
	
	j waitfortimer

	
	
#-------------------------------------------------------------------------------
# drawSnake
#   This function draws the snake according to its direction changed
#   the time and points
#
# 
#-------------------------------------------------------------------------------
#
# Register Usage:
#       Temporary registers are reused within the function
#
#	a0: used to store the value snake components to be printed 
#	a1: used to store the row number snake components to be printed 
#	a2: used to store the column number snake components to be printed 
#
#
#-------------------------------------------------------------------------------
drawSnake:
	addi sp,sp -4
	sw ra, 0(sp)
		
	# snake head position (center) 
	la t0, SNAKE_HEAD_ROW
	lw t1, 0(t0)                            
	
	la t0, SNAKE_HEAD_COL
	lw t2, 0(t0)
	
	# Print the snake head
	la t0, SNAKE_HEAD
	lb a0, 0(t0)
	mv a1, t1        
	mv a2, t2
	jal printChar
	
	

	# SNAKE  BODY POSITION
	
	      # 1st component 
	la t0, COMPONENT_ONE_ROW
	lw t1, 0(t0)	
	la t2, COMPONENT_ONE_COL
	lw t3, 0(t2)
	
	# Print the snake body
	la t0, SNAKE_BODY                      # SNAKE_BODY stores *
	lb a0, 0(t0)
	mv a1, t1
	mv a2, t3
	jal printChar
	
	
	     # 2nd component 
	la t0, COMPONENT_TWO_ROW
	lw t1, 0(t0)	
	la t2, COMPONENT_TWO_COL
	lw t3, 0(t2)
		
	# Print the snake body
	la t0, SNAKE_BODY
	lb a0, 0(t0)
	mv a1, t1
	mv a2, t3
	jal printChar
	
	
	   # 3rd component 
	la t0, COMPONENT_THREE_ROW
	lw t1, 0(t0)	
	la t2, COMPONENT_THREE_COL
	lw t3, 0(t2)
		
	# Print the snake body
	la t0, SNAKE_BODY
	lb a0, 0(t0)
	mv a1, t1
	mv a2, t3
	jal printChar
	
	

	lw s0, 4(sp)
    	lw s1, 8(sp)
    	lw s2, 12(sp)
    	lw s3, 16(sp)
    	lw s4, 20(sp)
    	lw s5, 24(sp)
    	lw s6, 28(sp)
    	lw s7, 32(sp)
    	lw s8, 36(sp)
	lw ra, 0(sp)
	addi sp,sp 4
	ret
	
#-------------------------------------------------------------------------------
# random
#   This function generates a random number between 0 to 8 
#   which is used in printing apple
# 
#-------------------------------------------------------------------------------
#
#       Args: None
# # Register Usage: 
#	a0: loads  the address of XiVar
#      to: stores the value of XiVar
#      t1: stores the value of aVar
#      t2: stores the value of cVar
#      t3: stores the value of mVar
#-------------------------------------------------------------------------------


random:
	la a0, XiVar

	# Load previous random value from memory
    	lw t0, XiVar  # Load Xi
    	lw t1, aVar   # Load a
    	lw t2, cVar   # Load c
    	lw t3, mVar   # Load m
    	
    	# Calculate new random value: Xi = (a * Xi + c) % m
   	mul t4, t0, t1   # Multiply aXi
    	add t5, t4, t2   # Add c
    	rem t6, t5, t3   # Modulus m     t6=Xi

    	# Store new random value back to XiVar
    	sw t6, 0(a0)    # Store new Xi

    	# Return the random value (Xi)
    	mv a0, t6            # Move random value to return register
    	ret
    	
    	
    	
handler:
	csrrw a0, uscratch,a0
	sw t0,0(a0)
	sw t1,4(a0)
	sw t2,8(a0)
	sw t3, 12(a0)
	sw t4, 16(a0)
	sw t5, 20(a0)
	sw t6, 24(a0)
	sw s1, 28(a0)
	sw s2, 32(a0)
	sw s3, 36(a0)
	sw s4, 36(a0)
	sw s5, 40(a0)
	
	csrr t0, 0x040
	sw t0, 44(a0)
	
		
	
	csrr t3, 0x42                                 #ucause register in t3
	 
	# check if exception or interupption
	srli t4, t3, 31                            # get the rightmost bit(most significant) 
   	beq t4, zero, handlerTerminate               #if equal to 0 it is an in exception --> terminate
   	
	
   	
   	#get the exception code 
   	li t5, 0x7FFFFFFF                            
   	and t6, t3, t5                             #t6 --> exc code
   	
   	li s1, 8 
   	li s2, 4
   	beq s1,t6, keyboard
   	beq s2,t6, timer
   	beq zero,zero, handlerTerminate
   	
keyboard:
	#if  keyboard interrupt
	 
	li t0,0xFFFF0004          #keyboard data
	lw t1,0(t0)               # get the the user input(keyboard data)
	la t2, keyInput           # address of keyInput
	sw t1, 0(t2)              # save the input in global variable keyInput 	
 
	#keyboard control
	li t1, 0xFFFF0000
	
	li t2,2
	sw t2,0(t1)                   # bit 1 of this register set to 1
	
	j handlerEnd
	
timer:
	li s1,0xFFFF0018                             # TIME
   	li s2,0xFFFF0020                             # TIMECMP
   	la s3, GAME_TIME                             # GAME_TIME
   	lw s4, 0(s3)
   	
   	#decrement time 
   	addi s4,s4, -1
   	sw s4, 0(s3)                                 #save the value back
   	
   	lw s5, 0(s1)                                #  current time 
   	addi s5, s5, 1000                           #  increment 1 sec(1000ms)
   	sw s5, 0(s2)                                #  store value to timecmp
   	
   	li t0,1
   	la t1, FLAG
   	sw t0, 0(t1)
	

handlerEnd:
	
	
	la      a0, iTrapData # a0 <- Addr[iTrapData]
	lw      t0, 44(a0)    # t0 <- USERa0
	csrw    t0, 0x040  
	
   	lw t0, 0(a0)
   	lw t1, 4(a0)
   	lw t2, 8(a0)
   	lw t3, 12(a0)
   	lw t4, 16(a0)
   	lw t5, 20(a0)
	lw t6, 24(a0)
	lw s1, 28(a0)
	lw s2, 32(a0)
	lw s3, 36(a0)
	lw s4, 36(a0)
	lw s5, 40(a0)
   	
   	csrrw a0, uscratch,a0
   	uret                     #return
	
handlerTerminate:
	# Print error msg before terminating
	li     a7, 4
	la     a0, INTERRUPT_ERROR
	ecall
	li     a7, 34
	csrrci a0, 66, 0
	ecall
	li     a7, 4
	la     a0, INSTRUCTION_ERROR
	ecall
	li     a7, 34
	csrrci a0, 65, 0
	ecall
handlerQuit:
	li     a7, 10
	ecall	# End of program








#---------------------------------------------------------------------------------------------
# printAllWalls
#
# Subroutine description: This subroutine prints all the walls within which the snake moves
# 
#   Args:
#  		None
#
# Register Usage
#      s0: the current row
#      s1: the end row
#
# Return Values:
#	None
#---------------------------------------------------------------------------------------------
printAllWalls:
	# Stack
	addi   sp, sp, -12
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	# print the top wall
	li     a0, 21
	li     a1, 0
	li     a2, 0
	la     a3, Brick
	lbu    a3, 0(a3)
	jal    ra, printMultipleSameChars

	li     s0, 1	# s0 <- startRow
	li     s1, 10	# s1 <- endRow
printAllWallsLoop:
	bge    s0, s1, printAllWallsLoopEnd
	# print the first brick
	la     a0, Brick	# a0 <- address(Brick)
	lbu    a0, 0(a0)	# a0 <- '#'
	mv     a1, s0		# a1 <- row
	li     a2, 0		# a2 <- col
	jal    ra, printChar
	# print the second brick
	la     a0, Brick
	lbu    a0, 0(a0)
	mv     a1, s0
	li     a2, 20
	jal    ra, printChar
	
	addi   s0, s0, 1
	jal    zero, printAllWallsLoop

printAllWallsLoopEnd:
	# print the bottom wall
	li     a0, 21
	li     a1, 10
	li     a2, 0
	la     a3, Brick
	lbu    a3, 0(a3)
	jal    ra, printMultipleSameChars

	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	addi   sp, sp, 12
	jalr   zero, ra, 0


#---------------------------------------------------------------------------------------------
# printMultipleSameChars
# 
# Subroutine description: This subroutine prints white spaces in the Keyboard and Display MMIO Simulator terminal at the
# given row and column.
# 
#   Args:
#   a0: length of the chars
# 	a1: row - The row to print on.
# 	a2: col - The column to start printing on.
#   a3: char to print
#
# Register Usage
#      s0: the remaining number of cahrs
#      s1: the current row
#      s2: the current column
#      s3: the char to be printed
#
# Return Values:
#	None
#---------------------------------------------------------------------------------------------
printMultipleSameChars:
	# Stack
	addi   sp, sp, -20
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	sw     s2, 12(sp)
	sw     s3, 16(sp)

	mv     s0, a0
	mv     s1, a1
	mv     s2, a2
	mv     s3, a3

# the loop for printing the chars
printMultipleSameCharsLoop:
	beq    s0, zero, printMultipleSameCharsLoopEnd   # branch if there's no remaining white space to print
	# Print character
	mv     a0, s3	# a0 <- char
	mv     a1, s1	# a1 <- row
	mv     a2, s2	# a2 <- col
	jal    ra, printChar
		
	addi   s0, s0, -1	# s0--
	addi   s2, s2, 1	# col++
	jal    zero, printMultipleSameCharsLoop

# All the printing chars work is done
printMultipleSameCharsLoopEnd:	
	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	lw     s2, 12(sp)
	lw     s3, 16(sp)
	addi   sp, sp, 20
	jalr   zero, ra, 0


#------------------------------------------------------------------------------
# printStr
#
# Subroutine description: Prints a string in the Keyboard and Display MMIO Simulator terminal at the
# given row and column.
#
# Args:
# 	a0: strAddr - The address of the null-terminated string to be printed.
# 	a1: row - The row to print on.
# 	a2: col - The column to start printing on.
#
# Register Usage
#      s0: The address of the string to be printed.
#      s1: The current row
#      s2: The current column
#      t0: The current character
#      t1: '\n'
#
# Return Values:
#	None
#
# References: This peice of code is adjusted from displayDemo.s(Zachary Selk, Jul 18, 2019)
#------------------------------------------------------------------------------
printStr:
	# Stack
	addi   sp, sp, -16
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	sw     s2, 12(sp)

	mv     s0, a0
	mv     s1, a1
	mv     s2, a2

# the loop for printing string
printStrLoop:
	# Check for null-character
	lb     t0, 0(s0)
	# Loop while(str[i] != '\0')
	beq    t0, zero, printStrLoopEnd

	# Print Char
	mv     a0, t0
	mv     a1, s1
	mv     a2, s2
	jal    ra, printChar

	addi   s0, s0, 1	# i++
	addi   s2, s2, 1	# col++
	jal    zero, printStrLoop

printStrLoopEnd:
	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	lw     s2, 12(sp)
	addi   sp, sp, 16
	jalr   zero, ra, 0



#------------------------------------------------------------------------------
# printChar
#
# Subroutine description: Prints a single character to the Keyboard and Display MMIO Simulator terminal
# at the given row and column.
#
# Args:
# 	a0: char - The character to print
#	a1: row - The row to print the given character
#	a2: col - The column to print the given character
#
# Register Usage
#      s0: The character to be printed.
#      s1: the current row
#      s2: the current column
#      t0: Bell ascii 7
#      t1: DISPLAY_DATA
#
# Return Values:
#	None
#
# References: This peice of code is adjusted from displayDemo.s(Zachary Selk, Jul 18, 2019)
#------------------------------------------------------------------------------
printChar:
	# Stack
	addi   sp, sp, -16
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	sw     s2, 12(sp)
	# save parameters
	mv     s0, a0
	mv     s1, a1
	mv     s2, a2

	jal    ra, waitForDisplayReady

	# Load bell and position into a register
	addi   t0, zero, 7	# Bell ascii
	slli   s1, s1, 8	# Shift row into position
	slli   s2, s2, 20	# Shift col into position
	or     t0, t0, s1
	or     t0, t0, s2	# Combine ascii, row, & col
	
	# Move cursor
	lw     t1, DISPLAY_DATA
	sw     t0, 0(t1)
	jal    waitForDisplayReady	# Wait for display before printing
	
	# Print char
	lw     t0, DISPLAY_DATA
	sw     s0, 0(t0)
	
	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	lw     s2, 12(sp)
	addi   sp, sp, 16
	jalr   zero, ra, 0



#------------------------------------------------------------------------------
# waitForDisplayReady
#
# Subroutine description: A method that will check if the Keyboard and Display MMIO Simulator terminal
# can be writen to, busy-waiting until it can.
#
# Args:
# 	None
#
# Register Usage
#      t0: used for DISPLAY_CONTROL
#
# Return Values:
#	None
#
# References: This peice of code is adjusted from displayDemo.s(Zachary Selk, Jul 18, 2019)
#------------------------------------------------------------------------------
waitForDisplayReady:
	# Loop while display ready bit is zero
	lw     t0, DISPLAY_CONTROL
	lw     t0, 0(t0)
	andi   t0, t0, 1
	beq    t0, zero, waitForDisplayReady
	jalr   zero, ra, 0

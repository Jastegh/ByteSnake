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
# Author: 
# Date: 
# TA: 
#
#-------------------------------

.include "common.s"

.data
.align 2



INTERRUPT_ERROR:	.asciz "Error: Unhandled interrupt with exception code: "
INSTRUCTION_ERROR:	.asciz "\n   Originating from the instruction at address: "


.text



snakeGame:






random:







handler:

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
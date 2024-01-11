#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2020 University of Alberta
# Copyright 2021 Emily Vandermeer
# Copyright 2022 Yufei Chen
#
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
# Author: Yufei Chen
# Date: May 16, 2022
#
# Adapted from:
# Author: Emily Vandermeer
# Date: June 11, 2021
#
# This program initializes four global variables to be used by the student-written function: random. 
#   Then this program jumps to the student code under the label "snakeGame" which is responsible for executing a snake game
#-------------------------------

.data
iTrapData:	.space	256	# allocate space for the interrupt trap data

.align  2        
XiVar:  	.word   17 	# starting seed of the LCG 
aVar:   	.word   10	# constant multiplier of the LCG 
cVar:   	.word   13  # constant increment of the LCG 
mVar:   	.word   9 	# the modulus of the LCG should be kept as 9

.text 
main:
	# Setup the uscratch control status register
	la	    t0, iTrapData		# t0 <- Addr[iTrapData]
	csrw	t0, 0x040		# CSR #64 (uscratch) <- Addr[iTrapData]
	jal 	ra, snakeGame	
	beqz 	zero, main_done


main_done:
	li      a7, 10      # ecall 10 exits the program with code 0
	ecall

#
# FILE:         sudoku.asm
# AUTHOR:       Jesse Burdick-Pless
#
# DESCRIPTION:	This program gets an initial 6x6 Sudoku puzzle from the
#		standard input as an ASCII text stream. It prints out
#		the unsolved puzzle, solves the puzzle, then prints the
#		solved version with all missing values entered. 
#		
#		Error messages:
#		If the input contains a value not in the range 0-6, the
#		input error message is printed and the program terminates.
#		
#		If the puzzle is impossible to solve, the puzzle error 
#		message is printed and the program terminates.
#

#-------------------------------

#
# CONSTANTS
#

SIZE = 36			# the number of elements in a puzzle

# syscall codes
PRINT_INT =     1
PRINT_STRING =  4
READ_INT =      5
EXIT =          10

#-------------------------------

#
# DATA AREAS
#

        .data

        .align  2               # word data must be on word boundaries

puzzle_array:
        .space  4*SIZE      	# Reserve space for an array to hold the puzzle.
                                # The array is 36 words wide (4 bytes each). 
				# Note the array is not initialized.

#
# The print constants for the code
#
        .align  0               # string data does not have to be aligned
space:
        .asciiz " "

new_line:
        .asciiz "\n"

banner:
	.asciiz "\n**************\n**  SUDOKU  **\n**************\n\n"

initial_msg:
        .asciiz "Initial Puzzle\n"

final_msg:
        .asciiz "Final Puzzle\n"

input_error_msg:
        .asciiz "ERROR: bad input value, Sudoku terminating\n"

puzzle_error_msg:
        .asciiz "Impossible Puzzle\n"

row_separator:
	.asciiz "\n+-----+-----+\n"

col_separator:
	.asciiz "|"

#-------------------------------

#
# CODE AREAS
#
        .text                   # this is program code
        .align  2               # instructions must be on word boundaries
        .globl  main            # main is a global label
	.globl	read
	.globl  write
	.globl  solve
	.globl 	print_puzzle
	
#
# Name:         MAIN PROGRAM
#
# Description:  Main logic for the program.
#
#       This program gets an initial 6x6 Sudoku puzzle from the standard 
#	input as an ASCII text stream. It prints out the unsolved puzzle, 
#	solves the puzzle, then prints the solved version with all missing 
#	values entered.
#
#	Error messages:
#	If the input contains a value not in the range 0-6, the input error 
#	message is printed and the program terminates.
#
#	If the puzzle is impossible to solve, the puzzle error message is 
#	printed and the program terminates.
#

main:
	addi	$sp, $sp, -8		# allocate space for the stack frame
	sw      $ra, 4($sp)		# store the ra on the stack
	
	#
	# Print banner
	#

	li 	$v0, PRINT_STRING	# print the Sudoku banner
	la	$a0, banner
	syscall
	
	#
	# Read in input for the puzzle
	#
	
	li      $t0, 0                  # initialize read counter
        li      $t2, SIZE		# the number of input values to read
        la      $t1, puzzle_array       # t1 is a pointer to an array to hold the puzzle

input_loop:
	beq     $t0, $t2, input_done    # done if t0 = 36

        li      $v0, READ_INT           # read one int
        syscall

	slt	$t3, $v0, $zero		# stop if the value read in is less than 0
        bnez    $t3, input_error 
	
	addi	$t3, $v0, -7		# stop if the value read in is greater than 6
	bgez	$t3, input_error	

        sw      $v0, 0($t1)             # save the value in the array

        addi    $t1, $t1, 4             # update pointer
        addi    $t0, $t0, 1             # increment counter
        j input_loop

input_done:
	
	#
	# Print the initial puzzle and message
	#

	li	$v0, PRINT_STRING	# print the initial puzzle message
	la	$a0, initial_msg
	syscall	

	la      $a0, puzzle_array       # print the initial puzzle
        jal     print_puzzle

	#
	# Solve the puzzle
	#
		
	la	$a0, puzzle_array 	# solve the puzzle
	jal 	solve

	beqz	$v0, impossible 	# if v0 = 0, the puzzle is impossible
	
	move    $t0, $v0		# put the address into t0

	#
	# Print the final puzzle and message
	# 
	
	li      $v0, PRINT_STRING       # print the final puzzle message
        la      $a0, final_msg
        syscall

	move	$a0, $t0		# print the final puzzle
        jal	print_puzzle

	j main_done


impossible:
	li      $v0, PRINT_STRING       # print impossible puzzle message
        la      $a0, puzzle_error_msg
        syscall
	j main_done
	

input_error:
	li      $v0, PRINT_STRING	# print input error message
        la      $a0, input_error_msg
        syscall
	
	j main_done			# exit the program

#
# All done -- exit the program!
#
main_done:
        lw      $ra, 4($sp)
        addi    $sp, $sp, 8    		# deallocate space for the return address
        jr      $ra             	# return from main and exit



#
# Name:         print_puzzle
#
# Description:  Prints a Sudoku puzzle.
#
# Arguments:    a0 the address of the array containing the puzzle to print
#
# Returns:      none
#

print_puzzle:
	addi    $sp, $sp, -24   # allocate space for the return address, s0, s1, s2, s3, and s4
        sw      $ra, 20($sp)    # store the ra on the stack
        sw      $s4, 16($sp)
        sw      $s3, 12($sp)
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

        li      $s0, 0			# iinitialize loop counter (i = 0)
        li 	$s2, SIZE		# the number of items to print
	li	$s3, 0			# initialize column counter
	li	$s4, 12			# initialize row counter
	move    $s1, $a0        	# save the address of the puzzle into s1
	
	j print_row_separator	

print_loop:
        beq     $s0, $s2, print_done	# done if loop counter == 36

        lw      $a0, 0($s1)             # get a[i]

	addi    $s1, $s1, 4             # update pointer
        addi    $s0, $s0, 1             # increment counter
	
	beqz	$a0, print_blank	# if the number read is 0, print a blank space
        
	li      $v0, PRINT_INT		# otherwise, print the number
        syscall                         
	j print_separators

print_blank:
	li      $v0, PRINT_STRING	# print a blank space
        la      $a0, space
        syscall
	j print_separators

print_separators:
	slti	$t5, $s3, 2		# if column counter = 2, print "|" instead of " "
	beqz	$t5, print_col_separator
	
	addi    $s3, $s3, 1             # increment column counter
	
	li      $v0, PRINT_STRING	# print a blank space
	la	$a0, space
	syscall
	j print_row_separator	

print_new_line:
	li      $v0, PRINT_STRING       # print a new_line
        la      $a0, new_line
        syscall
	li      $v0, PRINT_STRING       # print a col_separator: "|"
        la      $a0, col_separator
        syscall
	j print_row_separator


print_col_separator:
	li	$s3, 0			# reset column counter
	li      $v0, PRINT_STRING       # print a col_separator: "|"
        la      $a0, col_separator
        syscall
	li    	$t5, 5            	# if row counter == 5, jump to print_new_line
        beq    	$s4, $t5, print_new_line

#
# Fall through to print_row_separator
#

print_row_separator:
        addi    $s4, $s4, 1             # increment row counter
        slti    $t5, $s4, 12            # if row counter < 12, jump to print_loop
        bnez    $t5, print_loop

        li      $s4, 0                  # reset row counter
        li      $v0, PRINT_STRING       # print a row_separator: "+-----+-----+"
        la      $a0, row_separator
        syscall
        bne	$s0, $s2, start_new_line
	j print_loop

start_new_line:
	li      $v0, PRINT_STRING       # print a col_separator: "|"
        la      $a0, col_separator
        syscall
	j print_loop

print_done:
        li      $v0, PRINT_STRING	# print a new_line
        la      $a0, new_line
        syscall                         

	lw      $ra, 20($sp)    	# tear down this stack frame and return
        lw      $s4, 16($sp)
        lw      $s3, 12($sp)
        lw      $s2, 8($sp)
        lw      $s1, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp, $sp, 24
        jr      $ra

	

#
# File:         backtracker.asm
# Author:       Jesse Burdick-Pless
#
# Description:  Use the classic recursive backtracking algorithm to solve a
#		Sudoku puzzle.
#

#-------------------------------

# CONSTANTS
#

SIZE = 36			# the number of elements in a puzzle
VMAX  = 7			# the largest valid integer in a puzzle plus 1

#-------------------------------

#
# DATA AREAS
#

        .data

        .align  2               # word data must be on word boundaries
puzzle:
        .space  4*SIZE	        # Reserve space for an array to hold a copy of the initial puzzle.
				# The array is 36 words wide (4 bytes each).
				# Note the array is not initialized. 

#-------------------------------

#
# CODE AREAS
#

	.text			# this is program code
	.align 2		# instructions must be on word boundaries

	.globl	solve
	.globl	read
	.globl	write
	.globl	is_valid
	.globl	check_puzzle

#
# Name:         solve
#
# Description:  The startup routine for the backtracking algorithm. The initial
#		puzzle given in a0 is copied into the array 'puzzle'. Once the
#		puzzle has been copied, solve_rec is called.
#
# Arguments:    a0 the address of the initial puzzle
#
# Returns:      The address of the completed puzzle if solving the puzzle is 
# 		possible. 0 otherwise.
#

solve:
	addi    $sp, $sp, -24   # allocate space for the return address, and s0-s4
        sw      $ra, 20($sp)    # store the ra on the stack
	sw      $s4, 16($sp)
	sw      $s3, 12($sp)
	sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

	move 	$s0, $a0	# save the address of the initial puzzle into s0
	move	$s1, $zero	# initialize index counter
	la	$s2, puzzle	# put the address of the puzzle copy into s2

startup_loop:
	slti	$t0, $s1, SIZE	# if the index >= the size of the puzzle, goto begin_solve
	beqz	$t0, begin_solve

	move	$a0, $s0	# read the value at this index in the initial puzzle
	move	$a1, $s1
	jal	read
	
	sll     $t0, $s1, 2	# multiply s1 by 4 to get the byte offset
        add     $t1, $s2, $t0	# t1 = puzzle address + byte offset
	sw      $v0, 0($t1)     # put the value into the puzzle copy
	addi	$s1, $s1, 1	# increment index counter
	j startup_loop

begin_solve:
	move	$s3, $s2	# save the address of the puzzle copy into s3
	move    $a1, $zero      # set starting index to 0
	addi    $a2, $zero, 1	# set starting test value to 1
	jal	solve_rec

solve_done:
	lw      $ra, 20($sp)	# tear down this stack frame and return
        lw      $s3, 16($sp)
	lw      $s3, 12($sp)
	lw      $s2, 8($sp)
        lw      $s1, 4($sp)
	lw      $s0, 0($sp)
        addi    $sp, $sp, 24
        jr      $ra


#
# Name:         solve_rec
#
# Description:  Find the next empty space in the puzzle given in a0, starting
# 		at the index given in a1. Then try inserting test values, 
#		starting with the value given in a2. If the resulting puzzle
#		is valid, recursively call solve_rec. If the puzzle cannot
#		be solved, increment the test value and repeat. If no value 
#		gives a solveable puzzle, backtrack to the last valid puzzle.
#
# Arguments:    a0 the address of the initial puzzle
#               a1 the index in the puzzle to find a value for
#               a2 the current value to try
#
# Returns:      The address of the completed puzzle if solving the puzzle is
#               possible. 0 otherwise.
#

solve_rec:
	addi    $sp, $sp, -12	# allocate space for the return address, s1 and s2
        sw      $ra, 8($sp)	# store the ra on the stack
        sw      $s2, 4($sp)
        sw      $s1, 0($sp)
	
	move	$s1, $a1	# initialize index
	move    $s2, $a2	# initialize test value

find_next_index:
	slti    $t0, $s1, SIZE  # if index >= size of the puzzle, goto is_goal
        beqz    $t0, is_goal

	move    $a0, $s0	# read the value at the current index from the initial puzzle
        move    $a1, $s1
        jal     read

	beqz	$v0, solve_loop	# if the value is 0, goto solve_loop
	
	addi    $s1, $s1, 1	# otherwise, increment the index
	addi    $s2, $zero, 1	# reset the test value
	j find_next_index
	
solve_loop:
	slti	$t0, $s1, SIZE	# if the index >= the size of the puzzle, backtrack
	beqz	$t0, backtrack
	slti    $t0, $s2, VMAX	# if the test value >= max allowed int + 1, backtrack
        beqz    $t0, backtrack

	move    $a0, $s3        # call write on the puzzle copy to put the value in s2
        move    $a1, $s1	# at the index in s1
        move    $a2, $s2
        jal     write
	
	move	$a0, $s3	# call is_valid to check if the row, column, 
	move	$a1, $s1	# and box containg the current index are valid
	jal	is_valid	# after inserting the last value

	beqz	$v0, increment	# if the puzzle is invalid, goto increment

is_goal:
	li	$t0, SIZE
	bne	$t0, $s1, rec	# if the index != the size of the puzzle, goto rec

	move	$a0, $s3	# call check_puzzle to check if the puzzle is valid
	jal     check_puzzle
	
	beqz    $v0, increment  # if the puzzle is invalid, goto increment
	
	addi	$s4, $zero, 1	# set s4 to 1 to indicate that the puzzle is solved
	move	$v0, $s3	# put the address of the solved puzzle into v0
	j solve_rec_done

rec:
	addi	$a1, $s1, 1	# put the index + 1 into a1solve_rec
	addi	$a2, $zero, 1	# set a2 to 1
	jal	solve_rec	# recursively call solve_rec

	beqz    $s4, increment	# if the puzzle has not been solved, goto increment
#				
# if s4 != 0, the puzzle has been solved
#
	move    $v0, $s3        # put the address of the solved puzzle into v0
	j solve_rec_done
	
increment:
	addi	$s2, $s2, 1	# increment the test value
	j solve_loop	


backtrack:			
#
# set the value at the index s1 in the puzzle copy to its initial value
#
	move    $a0, $s0        # get the value at index s1 in the initial puzzle 
        move    $a1, $s1
        jal     read
        move    $t2, $v0        # save the value read into t2
        move    $a0, $s3        # set up parameters and call write
        move    $a1, $s1
        move    $a2, $t2
        jal     write

	move	$v0, $s4	# copy s4 into v0 before returning

solve_rec_done:
 	lw      $ra, 8($sp)	# tear down this stack frame and return
        lw      $s2, 4($sp)
        lw      $s1, 0($sp)
        addi    $sp, $sp, 12
        jr      $ra
		

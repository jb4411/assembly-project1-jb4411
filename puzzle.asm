#
# File:         puzzle.asm
# Author:       Jesse Burdick-Pless
#
# Description: Functions for interacting with Sudoku puzzles. 
#

#-------------------------------

#
# CONSTANTS
#

SIZE = 36			# the number of elements in a puzzle
MOD = 6				# the number of elements in a row
BOX = 3				# the width of a box

#-------------------------------

#
# DATA AREAS
#
	.data
	.align 1

seen:
        .space MOD              # Reserve space for an array with one byte 
				# corresponding to each valid number (1-6)
				# found in a puzzle. This array is used to
				# keep track of which numbers have been
                                # seen when checking if a puzzle is valid
				# The array is 6 bytes wide.
				# Note the array is not initialized.


        .text                   # this is program code
        .align 2                # instructions must be on word boundaries

        .globl	read
	.globl	write
	.globl	is_valid
	.globl	check_puzzle

#
# Name:         read
#
# Description:  Read and return the value at the position specified by the 
#		value given in a1 from the puzzle at the address given in a0.
#
# Arguments:    a0 the address of the puzzle to read from
#               a1 the index in the puzzle to read from
#
# Returns:      The value at the position given in a1
#

read:
	sll	$t0, $a1, 2	# multiply a1 by 4 to get the byte offset
	add	$t1, $a0, $t0	# t1 = puzzle address + byte offset
	lw      $v0, 0($t1)     # put the value at into $v0
	jr $ra			# return the value	


#
# Name:         write
#
# Description:  Insert the value given in a2 at the position specified by the
#               value given in a1 into the puzzle at the address given in a0.
#
# Arguments:    a0 the address of the puzzle to modify
#               a1 the index in the puzzle to insert the value
#		a2 the value to be inserted
#
# Returns:      none
#

write:
        sll     $t0, $a1, 2     # multiply a1 by 4 to get the byte offset
        add     $t1, $a0, $t0   # t1 = puzzle address + byte offset
        sw      $a2, 0($t1)     # put the value into the puzzle
        jr $ra


#
# Name:         is_valid
#
# Description:  Test if the row, column, and box that contain index a1
#		are all valid.
#
# Arguments:    a0 the address of the puzzle to check
#               a1 the index in the puzzle of the last value inserted
#
# Returns:      1 if the row, column, and box are valid, 0 otherwise
#

is_valid:
	addi    $sp, $sp, -28   # allocate space for the return address, and s0-s5
        sw      $ra, 24($sp)    # store the ra on the stack
        sw      $s5, 20($sp)
	sw      $s4, 16($sp)
	sw      $s3, 12($sp)
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

	move    $s0, $a0        # save the address of the puzzle into s0
        la      $s1, seen       # put the address of the seen array into s1
	
	li	$t0, MOD	# divide the index by 6
	div	$a1, $t0
	mfhi	$s2		# put the remainder into s2 (s2 = a1 modulo 6) 
				# this gives the column index
	move	$s5, $s2	# copy the column index into s5

	sub	$s3, $a1, $s2	# subtract the remainder from the index to get 
				# the row index (s3 = index - remainder)


pre_check_col:
        jal     clear_seen      # initialize the seen array

check_col:
        slti    $t0, $s2, SIZE  # if s2 >= the size of the puzzle, goto pre_check_row
        beqz    $t0, pre_check_row

        move    $a0, $s0        # read the next value from the puzzle
        move    $a1, $s2
        jal     read
	
	addi    $s2, $s2, MOD   # increment s2

        beqz	$v0, check_col	# if the value read is zero, goto check_col
	
	add     $t1, $s1, $v0   # t1 = address of the seen array + v0
        addi    $t1, $t1, -1    # t1 -= 1 to convert from number to index
        lb      $t2, 0($t1)     # if the value in seen is 1, this is a duplicate value
        bnez    $t2, return_invalid

        li      $t3, 1          # put a 1 into seen to mark this number as seen
        sb      $t3, 0($t1)
        j check_col


pre_check_row:
	jal     clear_seen      # clear the seen array
	move    $s2, $s3        # copy the row index into s2
	
	addi	$s4, $s3, MOD	# initialize the index of the end of this row

check_row:
	slt	$t0, $s3, $s4	# if s3 >= the end of this row, goto pre_check_box
	beqz	$t0, pre_check_box
	
	move	$a0, $s0	# read the next value from the puzzle
	move	$a1, $s3
	jal	read

	addi    $s3, $s3, 1     # increment s3
        
	beqz    $v0, check_row	# if the value read is zero, goto check_row
	
	add	$t1, $s1, $v0	# t1 = address of the seen array + v0
	addi	$t1, $t1, -1	# t1 -= 1 to convert from number to index
	lb	$t2, 0($t1)	# if the value in seen is 1, this is a duplicate value
	bnez	$t2, return_invalid
	
	li	$t3, 1		# put a 1 into seen to mark this number as seen
	sb	$t3, 0($t1)
	j check_row


pre_check_box:
	jal     clear_seen      # clear the seen array
#	
# s2 is the row index
# s5 is the column index
#	
	li	$t2, 4
	div	$s2, $t2	# divide the row index by 4
	mfhi	$t1		# t1 = row index modulo 4
	beqz	$t1, get_side	# if t1 is 0, goto directly to get_side
	
	addi	$s2, $s2, -MOD	# otherwise, decrement row index first

get_side:
	move 	$s3, $s2	# copy the row index into s3
	
	slti    $t0, $s5, BOX   # if the column index is less than the width of a
                                # box, the box is in the left half of the puzzle

	move	$s5, $zero	# initialize the loop counter to 0

	beqz    $t0, right_box  # otherwise, the box is in the right half of the puzzle
	
	li	$s4, BOX	# set the index of the ending column to 3
	add	$s4, $s4, $s2	# add the row index to get the array index
	j check_box

right_box:
	addi	$s3, $s3, BOX	# add the width of a box to get the array index
	li      $s4, MOD        # set the index of the ending column to 6
        add     $s4, $s4, $s2   # add the row index to get the array index

check_box:
#
# s3 is the current index
# s4 is the ending index
# s5 is the loop counter
#	
	slti	$t0, $s5, 6	# if the loop counter >= 6, the box is valid
	beqz	$t0, return_valid
	
	move    $a0, $s0        # read the next value from the puzzle
        move    $a1, $s3
        jal     read

	beqz    $v0, box_loop	# if the value read is zero, goto box_loop

        add     $t1, $s1, $v0   # t1 = address of the seen array + v0
        addi    $t1, $t1, -1    # t1 -= 1 to convert from number to index
        lb      $t2, 0($t1)     # if the value in seen is 1, this is a duplicate value
        bnez    $t2, return_invalid

        li      $t3, 1          # put a 1 into seen to mark this number as seen
        sb      $t3, 0($t1)

box_loop:
        addi    $s3, $s3, 1     # increment current index
	addi    $s5, $s5, 1     # increment loop counter       

	li	$t2, 3		# if the loop counter != 3, loop 
	bne    	$s5, $t2, check_box
				
				# otherwise, go to the next row in this box
	addi    $s3, $s3, BOX	# increment current index
	j check_box


return_valid:
	li	$v0, 1		# put 1 into v0 to indicate the puzzle is valid
	j is_valid_done

return_invalid:
	move	$v0, $zero	# put 0 into v0 to indicate the puzzle is invalid
	j is_valid_done

is_valid_done:
	lw      $ra, 24($sp)    # tear down this stack frame and return
        lw      $s5, 20($sp)
	lw      $s4, 16($sp)
	lw      $s3, 12($sp)
        lw      $s2, 8($sp)
        lw      $s1, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp, $sp, 28
        jr      $ra


#
# Name:		clear_seen
#
# Description:  Clear the seen array by writing 0 to each byte in the array.
#
# Arguments:    none
#
# Returns:      none
#

clear_seen:
	sb      $zero, 5($s1)	# write 0 to each element in the seen array
	sb      $zero, 4($s1)
        sb      $zero, 3($s1)
        sb      $zero, 2($s1)
        sb      $zero, 1($s1)
        sb      $zero, 0($s1)	

	jr $ra


#
# Name:         check_puzzle
#
# Description:  Check if the puzzle given in a0 is valid.
#
# Arguments:    a0 the address of the puzzle to check
#
# Returns:      1 if the puzzle is valid, 0 otherwise
#

check_puzzle:
	addi    $sp, $sp, -16   # allocate space for the return address, and s0-s2
        sw      $ra, 12($sp)    # store the ra on the stack
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)
	
	move    $s0, $a0        # save the address of the puzzle into s0
	move	$s1, $zero	# initialize index counter
	addi	$s2, $zero, 1	# initialize flip 

check_loop:
	slti    $t0, $s1, SIZE  # if s1 >= the size of the puzzle, goto check_done
	beqz	$t0, check_done

	move    $a0, $s3        # call is_valid to check if the row, column,
        move    $a1, $s1        # and box containg the current index are valid
        jal     is_valid

	beqz    $v0, check_done	# if the puzzle is invalid, goto check_done
	
	addi	$s1, $s1, 4	# increment index
	addi	$s2, $s2, 1	# increment flip

	slti	$t0, $s2, 2	# if flip < 2, goto check_loop
	bnez	$t0, check_loop	
	
	addi	$s1, $s1, 5	# increment index
	move	$s2, $zero	# set flip to 0
	j check_loop

check_done:
	lw      $ra, 12($sp)	# tear down this stack frame and return
        lw      $s2, 8($sp)
	lw      $s1, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp, $sp, 16
        jr      $ra
	

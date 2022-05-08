#
# Makefile for CSCI 250 Project 1 - Sudoku
#

#
# Location of the processing programs
#
RASM  = /home/fac/wrc/bin/rasm
RLINK = /home/fac/wrc/bin/rlink

#
# Suffixes to be used or created
#
.SUFFIXES:	.asm .obj .lst .out

#
# Object files
#
OBJFILES = sudoku.obj backtracker.obj puzzle.obj

#
# Transformation rule: .asm into .obj
#
.asm.obj:
	$(RASM) -l $*.asm > $*.lst

#
# Transformation rule: .obj into .out
#
.obj.out:
	$(RLINK) -m -o $*.out $*.obj > $*.map

#
# Main target
#
sudoku.out:	$(OBJFILES)
	$(RLINK) -m -o $*.out $(OBJFILES) > $*.map


# Author:	Seth Borkovec
# Date:		2020-12-12
# Description:	The classic codebreaker game.


	.data					# Constant and variable definitions

guide:	.asciiz "I've created a code 4 digits where each digit can be 1-6. Black pegs represent a digit that's in the correct position. White pegs represent a digit that's correct but in the wrong position. You have 10 attempts, good luck! "
m_win:	.asciiz "You got the code :)"
m_loss: .asciiz "You couldn't break the code :("
black:	.asciiz "Black: "
white:	.asciiz "White: "
newln:	.asciiz "\n"
prompt: .asciiz "Enter your guess: "
remain: .asciiz "Guesses remaining: "
code:	.space 20
guess:  .space 20


	.text					# Assembly instructions
	.globl main
##################### MAIN #####################
main:
	jal generate_code			# Get random code

	li $v0, 1
	lw $a0, guide
	syscall
	
	li $v0, 4
	la $a0, newln
	syscall
	syscall

	li $s4, 10				# Initialize number of guesses available
	
	jal game_loop				# Run game loop
	
	li $t0, 4
	bne $t0, $s0, lose_game			# Check for 4 black pegs (all digits of guess are correct)
	
	li $v0, 4
	la $a0, m_win
	syscall
	
	j exit
	
lose_game:
	li $v0, 4
	la $a0, m_loss
	syscall
	
	j exit
################# GENERATE CODE ################
generate_code:
	la $t0, code
	
	li $t1, 0
	sw $t1, ($t0)				# Zero out the code

	li $t1, 1000				# Loop index
	li $t2, 10				# Loop decrement factor
	
start_code_loop:
	beqz $t1, end_code_loop
	
	li $v0, 42
	li $a1, 6				# Random int in range [0, 5]
	syscall
	
	addi $t3, $a0, 1			# Random int now in range [1, 6]
	mul $t3, $t3, $t1			# Random int now in correct digit
	lw $t4, ($t0)				# Get the current value stored
	add $t3, $t4, $t3			# Add the new digit to stored code
	sw $t3, ($t0)				# Store the new code
	
	div $t1, $t2
	mflo $t1				# Decrement loop index by factor

	b start_code_loop
end_code_loop:
	jr $ra
################### GAME LOOP ##################
game_loop:	
	beqz $s4, end_game_loop			# While number of guesses > 0
	
	li $s0, 0				# Number of black pegs
	li $s1, 0				# Number of white pegs
	
	move $s7, $ra				# Save the return address
	jal get_input				# Get user guess
	move $ra, $s7				# Restore the return address
	
	subi $s4, $s4, 1			# Decrement guesses
	
	move $s7, $ra
	jal check_guess				# Check guess against code
	move $ra, $s7
	
	li $t0, 4				# Four black == all correct -> WIN!
	beq $t0, $s0, end_game_loop
	
	move $s7, $ra
	jal display_status			# Display status
	move $ra, $s7
	
	j game_loop				# Jump back to another iteration of the loop
	
end_game_loop:
	jr $ra					# Exit the game loop
################# CHECK GUESS ##################
check_guess:
	li $t0, 1000				# Loop index
	li $t1, 10				# Decrement factor
	
	lw $t2, code				# Load the code twice
	lw $t6, code
	lw $t3, guess				# Load the guess as a word
	
start_black_loop:
	beqz $t0, end_black_loop

	div $t6, $t0				# Get the digit from the code	
	mflo $t4
	mul $t4, $t4, $t0
	
	div $t3, $t0				# Get the digit from the guess
	mflo $t5
	mul $t5, $t5, $t0
	
	bne $t4, $t5, black_else		# Guess == Code in this position
			
	sub $t2, $t2, $t4			# Change this digit to 0 because it was already guessed
	addi $s0, $s0, 1			# Increment black
	
black_else:
	sub $t6, $t6, $t4			# Remove the digit from the code
	sub $t3, $t3, $t5			# Remove the digit from the guess
	
	div $t0, $t1				# Decrement index by factor of 10
	mflo $t0
	b start_black_loop
	
end_black_loop:
	li $t0, 1000				# Outer loop index
	li $t1, 10				# Decrement factor
	
	lw $t2, code
	lw $t6, code
	lw $t3, guess				# Reload the guess

start_white_loop:
	beqz $t0, end_white_loop
	
	div $t3, $t0				# Get the digit from the guess
	mflo $t5
	
	li $t9, 0				# Found flag
	li $t8, 1000				# Inner loop index
	
start_inner_loop:
	beqz $t8, end_inner_loop
	bnez $t9, end_inner_loop
	
	div $t6, $t8
	mflo $t4
	mul $t4, $t4, $t8			# Get the digit from the code
	mul $t7, $t5, $t8			# Get the digit from the guess
	
	bne $t4, $t7, white_else		# Guess == Code in this position
			
	sub $t2, $t2, $t4			# Change this digit to 0 because it was already guessed
	addi $s1, $s1, 1			# Increment white
	li $t9, 1				# Set found flag
	
white_else:
	sub $t6, $t6, $t4			# Remove the digit from the code
	
	div $t8, $t1
	mflo $t8
	b start_inner_loop
	
end_inner_loop:
	mul $t5, $t5, $t0
	sub $t3, $t3, $t5			# Remove the digit from the guess
	
	move $t6, $t2

	div $t0, $t1				# Decrement index by factor of 10
	mflo $t0
	b start_white_loop
	
end_white_loop:
	sub $s1, $s1, $s0			# Subtract black from white
	jr $ra
################ DISPLAY STATUS ################
display_status:

	li $v0, 4
	la $a0, newln
	syscall
	
	li $v0, 4
	la $a0, black
	syscall					# Display black pegs
	
	li $v0, 1
	move $a0, $s0
	syscall
	
	li $v0, 4
	la $a0, newln
	syscall
	
	li $v0, 4
	la $a0, white
	syscall					# Display white pegs
	
	li $v0, 1
	move $a0, $s1
	syscall
	
	li $v0, 4
	la $a0, newln
	syscall
	
	li $v0, 4
	la $a0, remain
	syscall					# Display remaining guesses
	
	li $v0, 1
	move $a0, $s4
	syscall
	
	li $v0, 4
	la $a0, newln
	syscall
	
	jr $ra
################# GET INPUT ####################
get_input:
	li $v0, 4
	la $a0, prompt
	syscall					# Display the prompt for a guess
	
	li $v0, 5
	syscall					# Get the user input as an integer
	
	la $t0, guess
	sw $v0, ($t0)				# Store the user's guess
	
	jr $ra
##################### EXIT #####################
exit:
	li $v0, 4
	la $a0, newln
	syscall
	
	li $v0, 10
	syscall

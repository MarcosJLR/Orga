.data

.align 2
program: .space 400
str:     .ascii "80a450003464000a00000000"
N:       .word 3

.align 2
coop:   .word haltF, 0, 0, 0, sllvF, bneF, beqF, 0, addiF, 0, 0 ,0, andiF, oriF
	.space 40
	.word multF
	.space 28
	.word addF, 0, subF, lwF, 0, orF, 0, 0, andF, 0, 0, swF
	.space 80

haltM:  .asciiz " R halt "
sllvM:  .asciiz " R sllv " 
bneM:   .asciiz " I bne "
beqM:   .asciiz " I beq "
addiM:  .asciiz " I addi "
andiM:  .asciiz " I andi "
oriM:   .asciiz " I ori " 
multM:  .asciiz " R mult "
addM:   .asciiz " R add "
subM:   .asciiz " R sub "
lwM:    .asciiz " I lw "
orM:    .asciiz " R or "
andM:   .asciiz " R and "
swM:    .asciiz " I sw "
newL:   .asciiz "\n"
bsp:    .asciiz " "
dollar: .asciiz "$"

.text

main:
	la $a0, str
	lw $s0, N
	la $s1, program
mainLoop:
	beqz $s0, outLoop
	jal toint
	sw $v0, ($s1)
	addi $s0, $s0, -1
	addi $a0, $a0, 8
	addi $s1, $s1, 4
	b mainLoop
outLoop:
	la $a2, program
	lw $s0, N
mainLoop2:
	beqz $s0, outLoop2
	jal printInst
	addi $a2, $a2, 4
	addi $s0, $s0, -1
	b mainLoop2
outLoop2:
	li $v0, 10
	syscall


toint:
	li $v0, 0
	li $t0, 0
	move $t1, $a0
tointLoop:
	bne $t0, 8, tointNotReturn
	j tointRet
tointNotReturn:
	lb $t2, ($t1)
	andi $t3, $t2, 0xf0
	beq $t3, 0x30, tointDigit
	andi $t3, $t2, 0xf
	addi $t3, $t3, 9
	sll $v0, $v0, 4
	or $v0, $v0, $t3
	b tointInc
tointDigit:
	andi $t3, $t2, 0xf
	sll $v0, $v0, 4
	or $v0, $v0, $t3
tointInc:
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	b tointLoop
tointRet:
	jr $ra
		
printInst:
	lw $a1, 0($a2)
	andi $t0, $a1, 0xfc000000
	srl $t0, $t0, 24
	lw $t1, coop($t0)
	#add $t1, $t0, $t1
	jalr $t1
printInstRet:
	li $v0, 4
	la $a0, newL
	syscall
	jr $ra
	
haltF:  
sllvF:  
bneF:   
beqF:   
addiF:  
andiF:  
oriF:   
multF:  
addF: 
	li $v0, 10
	syscall  
subF:   
lwF:    
orF:    
andF:   
swF:    
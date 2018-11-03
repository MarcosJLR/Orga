.data

.align 2
program: .space 400
str: .ascii "2402000d"

.text

toint:
	li $v0, 0
	li $t0, 0
	la $t1, str
tointLoop:
	bne $t0, 8, tointNotReturn
	j ret
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
	
ret:
	li $v0, 10
	syscall
		
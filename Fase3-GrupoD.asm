.data

.align 2
reg:     .space 128
pcvirt:  .word 0
dat:     .space 2000

.align 2
program: .space 400
file:    .space 24
str:     .space 1004
N:       .space 4
mes1:	 .asciiz "Introduzca la direccion del archivo:\n"
mes2:	 .asciiz "El archivo no fue encontrado.\n"
.align 2
coop:   .word haltF, 0, 0, 0, sllvF, bneF, beqF, 0, addiF, 0, 0 ,0, andiF, oriF
	.space 40
	.word multF
	.space 28
	.word addF, 0, subF, lwF, 0, orF, 0, 0, andF, 0, 0, swF
	.space 80
numData: .asciiz "Introduzca el numero de palabras del area de datos que desea imprimir:\n"
datMes:  .asciiz "Datos:\n"
regMes:  .asciiz "Registros:\n"
newL:    .asciiz "\n"
bSpace:  .asciiz " "
pcMes:   .asciiz "pc "
endline: .byte '\n'

.text

main:
	jal readfile
	la $a0, str
	lw $s0, N
	la $s1, program
mainLoop:
	beqz $s0, outLoop
	jal toint
	sw $v0, ($s1)
	addi $s0, $s0, -1
	addi $a0, $a0, 10
	addi $s1, $s1, 4
	b mainLoop
outLoop:
	sw $0, pcvirt
mainLoop2:
	jal execInst
	b mainLoop2

	#---------------------------------------------------------------------------------------------------------------#

toint:				#recibe en $a0 la direccion del primer char del string a traducir
				#retorna en $v0 el entero deseado
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

	#---------------------------------------------------------------------------------------------------------------#
read_again:				#Imprime mensaje diciendo que el archivo no se encontro
	la $a0, mes2
	li $v0, 4
	syscall			
readfile:				#Pide al usuario el nombre del archivo a leer, lo abre y almacena el contenido
					#en str, y guarda en N el numero de lineas de texto
	la $a0, mes1			#Imprime mensaje pidiendo la direccion del archivo
	li $v0, 4
	syscall				
	li $v0, 8			#Lee un string y lo guarda en la direccion file
	la $a0, file
	li $a1, 119
	syscall
	move $t0, $a0
	lb $t2, endline			#endLine contiene al byte de \n en ascii
	li $t3, 0
nloop:					#Revisa si hay un salto de linea en el string leido 
	lb $t1, 0($t0)			
	beq $t1, $t2, changen		
	beq $t1, $t3, endnloop
	addi $t0, $t0, 1
	b nloop
changen:
	sb $t3, 0($t0)
endnloop:
	li $v0, 13
	li $a1, 0
	li $a2, 0
	syscall
	blt $v0, $zero, read_again
	move $a0, $v0
	li $v0, 14
	la $a1, str
	li $a2, 1000
	syscall
	li $t2, 10
	div $v0, $t2
	mflo $t1
	sw $t1, N
	jr $ra

	#---------------------------------------------------------------------------------------------------------------#	
			
execInst:				#Ejecuta la instruccion a la que señala pcvirt
					#No recibe argumentos
	
	move $fp, $sp
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $fp, 8($sp)
	
	lw $t0, pcvirt
	lw $a0, program($t0)
	addi $t0, $t0, 4
	sw $t0, pcvirt
	
	andi $t0, $a0, 0xfc000000
	srl $t0, $t0, 24
	lw $t1, coop($t0)
		
	jalr $t1

	lw $ra, 4($sp)
	lw $fp, 8($sp)
	move $sp, $fp
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
haltF:  				#Termina la ejecucion del programa
					#No recibe argumentos
	jal printReg
	jal printData
	li $v0, 10
	syscall
	
	
	#---------------------------------------------------------------------------------------------------------------#

sllvF:  				#Recibe en $a0 la instruccion completa
					#Realiza el shift hacia la izquierda
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14
	lw $t1, reg($t1)		#Ahora $t1 contiene el contenido del registro $rt especificado
	
	andi $t2, $a0, 0x0000f800
	srl $t2, $t2, 9			#Ahora $t2 contiene el numero del registro destino especificado (multiplicado por 4)
	
	sllv $v0, $t1, $t0
	
	sw $v0, reg($t2)
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
bneF:     				#Recibe en $a0 la instruccion completa.
					#No retorna nada, modifica el pc virtual sumandole Offset si $rs es distinto de $rt
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14
	lw $t1, reg($t1)		#Ahora $t1 contiene el contenido del registro $rt especificado
	
	andi $t2, $a0, 0x0000ffff
	sll $t2, $t2, 16
	sra $t2, $t2, 14		#Ahora $t2 contiene el Offset especificado multiplicado por 4 con extension de signo.
	
	beq $t0, $t1, bneRet		#Si $rs y $rt son iguales retorna, sino cambia el valor del pc virtual
	lw $t0, pcvirt
	add $t0, $t0, $t2		
	sw $t0, pcvirt			#Se le sumo Offset a pcvirt, se realizo el branch
	
bneRet:
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
beqF:     				#Recibe en $a0 la instruccion completa.
					#No retorna nada, modifica el pc virtual sumandole Offset si $rs es igual a $rt
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14
	lw $t1, reg($t1)		#Ahora $t1 contiene el contenido del registro $rt especificado
	
	andi $t2, $a0, 0x0000ffff
	sll $t2, $t2, 16
	sra $t2, $t2, 14		#Ahora $t2 contiene el Offset especificado multiplicado por 4 con extension de signo.
	
	bne $t0, $t1, beqRet		#Si $rs y $rt son distintos retorna, sino cambia el valor del pc virtual
	lw $t0, pcvirt
	add $t0, $t0, $t2		
	sw $t0, pcvirt			#Se le sumo Offset a pcvirt, se realizo el branch
	
beqRet:
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
addiF:    				#Recibe en $a0 la instruccion completa.
					#No retorna nada. Le asigna a $rt el resultado de sumar el contenido de $rs mas
					#el valor de Offset.
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14		#Ahora $t1 contiene el numero del registro $rt (registro destino) especificado
					#Multiplicado por 4.
	
	andi $t2, $a0, 0x0000ffff
	sll $t2, $t2, 16
	sra $t2, $t2, 16		#Ahora $t2 contiene el Offset especificado con extension de signo.
	
	add $v0, $t0, $t2		#Guarda en $v0 la suma de $rs + Offset.
	sw $v0, reg($t1)		#Guarda el resultado en el registro virtual $rt.
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
andiF:    				#Recibe en $a0 la instruccion completa.
					#No retorna nada. Le asigna a $rt el resultado de hacer el bitwise AND del 
					#contenido de $rs y el valor de Offset.
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14		#Ahora $t1 contiene el numero del registro $rt (registro destino) especificado
					#Multiplicado por 4.
	
	andi $t2, $a0, 0x0000ffff	#Ahora $t2 contiene el Offset especificado con extension de ceros.
	
	and $v0, $t0, $t2		#Guarda en $v0 el resultado de $rs & Offset.
	sw $v0, reg($t1)		#Guarda el resultado en el registro virtual $rt.
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
oriF:     				#Recibe en $a0 la instruccion completa.
					#No retorna nada. Le asigna a $rt el resultado de sumar el contenido de $rs mas
					#el valor de Offset.
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14		#Ahora $t1 contiene el numero del registro $rt (registro destino) especificado
					#Multiplicado por 4.
	
	andi $t2, $a0, 0x0000ffff	#Ahora $t2 contiene el Offset especificado con extension de ceros.
	
	or $v0, $t0, $t2		#Guarda en $v0 el resultado de $rs | Offset.
	sw $v0, reg($t1)		#Guarda el resultado en el registro virtual $rt.
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
multF:    				#Recibe en $a0 la instruccion completa.
					#No retorna nada. Le asigna a $rt el resultado de hacer el bitwise AND del 
					#contenido de $rs y el valor de Offset.
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14		
	lw $t1, reg($t1)		#Ahora $t1 contiene el contenido del registro $rt especificado
	
	andi $t2, $a0, 0x0000f800
	srl $t2, $t2, 9			#Ahora $t2 contiene el numero del registro $rd (registro destino) especificado
					#Multiplicado por 4.
	
	mult $t0, $t1
	mflo $v0
	sw $v0, reg($t2)
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
addF:     				#Recibe en $a0 la instruccion completa.
					#No retorna nada. Le asigna a $rt el resultado de hacer el bitwise AND del 
					#contenido de $rs y el valor de Offset.
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14		
	lw $t1, reg($t1)		#Ahora $t1 contiene el contenido del registro $rt especificado
	
	andi $t2, $a0, 0x0000f800
	srl $t2, $t2, 9			#Ahora $t2 contiene el numero del registro $rd (registro destino) especificado
					#Multiplicado por 4.
	
	add $v0, $t0, $t1
	sw $v0, reg($t2)
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
subF:      				#Recibe en $a0 la instruccion completa.
					#No retorna nada. Le asigna a $rt el resultado de hacer el bitwise AND del 
					#contenido de $rs y el valor de Offset.
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14		
	lw $t1, reg($t1)		#Ahora $t1 contiene el contenido del registro $rt especificado
	
	andi $t2, $a0, 0x0000f800
	srl $t2, $t2, 9			#Ahora $t2 contiene el numero del registro $rd (registro destino) especificado
					#Multiplicado por 4.
	
	sub $v0, $t0, $t1
	sw $v0, reg($t2)
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
lwF:      				#Recibe en $a0 la instruccion completa.
					#No retorna nada. Le asigna a $rt el resultado de sumar el contenido de $rs mas
					#el valor de Offset.
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14		
	
	andi $t2, $a0, 0x0000ffff	#Ahora $t2 contiene el Offset especificado con extension de ceros.
	
	add $t0, $t0, $t2		#Suma el Offset al contenido de $rs para cargar de la direccion resultante de data
					#El contenido en $rt
	lw $v0, dat($t0)		#Carga el contenido en data dado por el Offset y $rs
	sw $v0, reg($t1)		#Guarda el resultado en el registro virtual $rt.
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
orF:       				#Recibe en $a0 la instruccion completa.
					#No retorna nada. Le asigna a $rt el resultado de hacer el bitwise AND del 
					#contenido de $rs y el valor de Offset.
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14		
	lw $t1, reg($t1)		#Ahora $t1 contiene el contenido del registro $rt especificado
	
	andi $t2, $a0, 0x0000f800
	srl $t2, $t2, 9			#Ahora $t2 contiene el numero del registro $rd (registro destino) especificado
					#Multiplicado por 4.
	
	or $v0, $t0, $t1		
	sw $v0, reg($t2)
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
andF:      				#Recibe en $a0 la instruccion completa.
					#No retorna nada. Le asigna a $rt el resultado de hacer el bitwise AND del 
					#contenido de $rs y el valor de Offset.
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14		
	lw $t1, reg($t1)		#Ahora $t1 contiene el contenido del registro $rt especificado
	
	andi $t2, $a0, 0x0000f800
	srl $t2, $t2, 9			#Ahora $t2 contiene el numero del registro $rd (registro destino) especificado
					#Multiplicado por 4.
	
	and $v0, $t0, $t1
	sw $v0, reg($t2)
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#
	
swF:      				#Recibe en $a0 la instruccion completa.
					#No retorna nada. Le asigna a $rt el resultado de sumar el contenido de $rs mas
					#el valor de Offset.
	
	andi $t0, $a0, 0x03e00000	
	srl $t0, $t0, 19
	lw $t0, reg($t0)		#Ahora $t0 contiene el contenido del registro $rs especificado
	
	andi $t1, $a0, 0x001f0000
	srl $t1, $t1, 14		
	lw $t1, reg($t1)		#Ahora $t1 contiene el numero del registro $rt especificado
	
	andi $t2, $a0, 0x0000ffff	#Ahora $t2 contiene el Offset especificado con extension de ceros.
	
	add $t0, $t0, $t2		#Suma el Offset al contenido de $rs para guardar en la direccion resultante de data
					#El contenido de $rt
	sw $t1, dat($t0)		#Guarda el contenido de $t1 en el sector de data
	
	jr $ra
	
	
	#---------------------------------------------------------------------------------------------------------------#

printReg:				#Imprime los registros virtuales.
					#No recibe argumentos.
	li $t2, 32
	move $t0, $0
	move $t1, $0
	
	li $v0, 4
	la $a0, regMes
	syscall
	
loopPReg:
	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, bSpace
	syscall
	
	li $v0, 34
	lw $a0, reg($t1)
	syscall
	
	li $v0, 4
	la $a0, newL
	syscall

	addi $t0, $t0, 1
	addi $t1, $t1, 4
	blt $t0, $t2, loopPReg
	
	li $v0, 4
	la $a0, pcMes
	syscall
	
	li $v0, 34
	lw $a0, pcvirt
	syscall
	
	li $v0, 4
	la $a0, newL
	syscall
	
	jr $ra
	
	#---------------------------------------------------------------------------------------------------------------#	
	
printData:			#Pregunta al usuario cuantas palabras del area de datos quiere
				#y luego procede a imprimir las primeras n palabras del area de
				#datos virtual.
				#No recibe argumentos.
	la $a0, numData
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	move $t2, $v0
	move $t0, $0
	move $t1, $0
	
	li $v0, 4
	la $a0, datMes
	syscall
loopPDat:
	li $v0, 34
	lw $a0, dat($t1)
	syscall
	
	li $v0, 4
	la $a0, newL
	syscall

	addi $t0, $t0, 1
	addi $t1, $t1, 4
	blt $t0, $t2, loopPDat
	
	jr $ra

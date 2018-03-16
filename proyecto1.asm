.data

lista: .space 4
nArchivos: .space 4
nLineas: .space 4
initFile: .asciiz "init.txt"
bienvenida1: .asciiz "BIENVENIDO AL INTERPRETE DE COMANDOS\n" 
bienvenida2: .asciiz "Aqui podra administrar su sistema de archivos\n\n" 
mensaje: .asciiz "\n\nIngrese comando: " 
error0: .asciiz "Se han ingresado caracteres invalidos. Solo se aceptan caracteres alfabeticos y '.'\n\n"
byte1: .ascii "\" 
byte2: .ascii "n" 
error1: .asciiz "Comando invalido\n\n"
error2: .asciiz "Cantidad erronea de parametros\n\n"
error3: .asciiz "El sistema no reconoce el/los parametro(s) especificado(s)\n\n"
error4: .asciiz "Espacio insuficiente en el sistema de directorio\n\n"
error5: .asciiz "El nombre de archivo ya ha sido usado, por favor ingrese un nombre diferente\n\n"
error6: .asciiz "El archivo especificado no existe\n\n"
error7: .asciiz "Alguno(s) de lo(s) parametro(s) de entrada posee(n) una longitud superior a la permitida de 20 caracteres\n\n"
error8: .asciiz "Error abriendo el archivo de inicializacion\n\n"
error9: .asciiz "Error leyendo el archivo de inicializacion\n\n"
error10: .asciiz "No puede haber mas de 65535 archivos para cargar en la inicializacion, este sistema no lo permite\n\n"
error11: .asciiz "No puede haber mas de 65535 lineas en un archivo para cargar en la inicializacion, este sistema no lo permite\n\n"
comando: .space 45
nombre1: .space 21
nombre2: .space 21
contenido: .space 101
fileBuffer: .space 100
contentBuffer: .space 100
procesBuffer: .space 45


.text

main:
# Inicializar sistema de archivos
jal dir_init
move $a0, $v0			# Reviso el estatus de finalizacion de la inicializacion
jal error 			# Muestro error si lo hubo
li $v0, 4 			# Indicar servicio de impresion por consola
la $a0, bienvenida1 		# Indicar ubicacion del mensaje a mostrar en memoria
syscall				# Muestro mensaje de bienvenida
la $a0, bienvenida2 		# Indicar ubicacion del mensaje a mostrar en memoria
syscall				# Muestro mensaje aclaratorio
entrada: la $a1, nombre1	# Apunto al espacio de memoria para el primer nombre de archivo de los comandos
li $a2, 20			# Indico la cantidad de caracteres de su longitud
jal limpiar			# Lo limpio luego de usarlo 
la $a1, nombre2			# Apunto al espacio de memoria para el segundo nombre de archivo de los comandos
li $a2, 20			# Indico la cantidad de caracteres de su longitud
jal limpiar			# Lo limpio luego de usarlo
li $v0, 4			# Indicar servicio de impresion por consola
la $a0, mensaje 		# Indicar ubicacion del mensaje a mostrar en memoria
syscall				# Muestro la orden de ingresar comando
li $v0, 8			# Indicar servicio de lectura por teclado
la $a0, comando			# Indicar direccion donde se guarda lo tecleado
li $a1, 45			# Indicar cantidad maxima de caracteres esperados
syscall 			# Ingreso comando
jal caracteres			# Invocacion de la rutina para chequear si se ingreso algun caracter invalido
beq $v0, 0, continuar		# Si la rutina indica que no hay caracteres especiales continua
li $a0, -12			# Si no coloco codigo de error 0 
jal error			# Imprimo el mensaje de error correspondiente en consola
j entrada			# Regreso a esperar comando
continuar: lb $t0, comando	# Tomo primer caracter del comando
lb $t1, comando+1		# Tomo segundo caracter del comando
lb $t2, comando+2		# Tomo tercer caracter del comando
move $a0, $t0			# Paso primer caracter a la rutina
jal minuscula			# Invocacion de la rutina para llevarlo a minuscula si es necesario
move $t0, $v0			# Recepcion del valor de retorno
move $a0, $t1			# Paso segundo caracter a la rutina
jal minuscula			# Invocacion de la rutina para llevarlo a minuscula si es necesario
move $t1, $v0			# Recepcion del valor de retorno
sll $t3, $t0, 16		# Desplazar el primer caracter a la posicion mas significante
sll $t4, $t1, 8			# Desplazar el segundo caracter a la segunda posicion mas significante
or $t0, $t3, $t4		# Unir en un mismo valor el primer y segundo caracter
or $t1, $t0, $t2		# Unir en un mismo valor el resultado anterior y tercer caracter
# Llamado a las funciones del manejador de archivos de acuerdo al comando:
bne $t1, 0x00637020, condicion1
jal dir_cp
bnez $v0, mostrarError
j entrada	
condicion1: bne $t1, 0x006D7620, condicion2
jal dir_ren
bnez $v0, mostrarError
j entrada
condicion2: bne $t1, 0x00726D20, condicion3
jal dir_rm
bnez $v0, mostrarError
j entrada
condicion3: seq $t0, $t1, 0x006C7320
seq $t2, $t1, 0x006C730A
or $t3, $t0, $t2
bne $t3, 1, condicion4
jal dir_ls
bnez $v0, mostrarError
j entrada
condicion4: bne $t1, 0x00637420, condicion5
jal dir_cat
bnez $v0, mostrarError
j entrada
condicion5: bne $t1, 0x00636920, condicion6
jal dir_ci
bnez $v0, mostrarError
j entrada
condicion6: bne $t1, 0x00646320, condicion7
jal dir_dc
bnez $v0, mostrarError
j entrada
condicion7: bne $t1, 0x006D6B20, condicion8
jal dir_mk
bnez $v0, mostrarError
j entrada
condicion8: bne $t1, 0x00617220, condicion9
jal procesar
bnez $v0, mostrarError
j entrada
condicion9: li $v0, -1		# Indico que hubo error en la sintaxis del comando
mostrarError: move  $a0, $v0 	# Reviso el estatus de la ronda actual de ejecucion de comandos
jal error			# Muestro error si lo hubo
j entrada 			# Volver  a esperar comando (salto)

# Rutina que chequea si se introdujo un caracter invalido
caracteres:
sw $fp, ($sp)			# Empila $fp
sw $s0, -4($sp)			# Empila $s0 
sw $s1, -8($sp)			# Empila $s1 
sw $s2, -12($sp)		# Empila $s2 
sw $s3, -16($sp)		# Empila $s3
sw $s4, -20($sp)		# Empila $s4
sw $s5, -24($sp)		# Empila $s5
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -28		# Moviliza el $sp 28 posiciones hacia arriba
li $s0, 0			# Inicializo $s0 con 0 (para indicar que no hay caracteres especiales aun)
la $s1, comando			# Cargo en $s1 la direccion donde esta almacenado el comando
caracteresInicio: lb $s2, ($s1)	# Cargo en $s2 el caracter apuntado por $s1
beq $s2, 0, caracteresFin	# Si el caracter es null termina el chequeo 
beq $s2, 0xA, caracteresFin	# Si el caracter es "\n" termina el chequeo
beq $s2, 0x20, siguiente	# Si el caracter es "espacio" continua la busqueda
beq $s2, 0x2e, siguiente	# Si el caracter es "." continua la busqueda
sgt $s3, $s2, 0x40		# Discriminamos letras anteriores a la A 
slti  $s4, $s2, 0x5b		# Discriminamos letras posteriores a la Z
and $s5, $s3, $s4		# Si el caracter esta entre A y Z lo indica $s5
beq $s5, 1, siguiente		# Si $s5 es 1 continua la busqueda
sgt $s3, $s2, 0x60		# Discriminamos letras anteriores a la a
slti $s4, $s2, 0x7b		# Discriminamos letras posteriores a la z
and $s5, $s3, $s4		# Si el caracter esta entre a y z lo indica $s5
beq $s5, 1, siguiente		# Si $s5 es 1 continua la busqueda
li $s0, 12			# Si no cumple lo anterior el caracter es especial y lo indica en $s0
siguiente: addi $s1, $s1, 1	# Incrementa el apuntador ($s1) 
j caracteresInicio		# Vuelve a buscar caracter
caracteresFin: move $v0, $s0	# Devuelve el resultado de la rutina
move $sp, $fp			# Restaura el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $s0, -4($sp)			# Desempilo $s0 
lw $s1, -8($sp)			# Desempilo $s1 
lw $s2, -12($sp)		# Desempilo $s2 
lw $s3, -16($sp)		# Desempilo $s3 
lw $s4, -20($sp)		# Desempilo $s4 
lw $s5, -24($sp)		# Desempilo $s5 
jr $ra  			# Retorna al llamador

# Rutina que chequea si un caracter esta entre 41 y 5A (rango de codigo ASCII de las mayusculas),
# de ser asi, le suma 20 (llevandola al codigo ASCII de su correspondiente minuscula)
minuscula:
sw $fp, ($sp)			# Empila $fp
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -4		# Moviliza el $sp 4 posiciones hacia arriba
blt $a0, 0x41, minusculaFin	# Discrimina los caracteres anteriores a la A 
bgt $a0, 0x5A, minusculaFin	# Discrimina los caracteres posteriores a la Z
addi $a0, $a0, 0x20		# Si el caracter esta entre A y Z lo convierte en minuscula
minusculaFin: move $v0, $a0	# Coloca el resultado como valor de retorno
move $sp, $fp			# Restaura el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 	
jr $ra  			# Retorna al llamador

# Rutina que retorna la cantidad de cadenas de caracteres (nombres) que posee el comando y almacena 
# los dos primeros por separado en memoria
nombres:
sw $fp, ($sp)			# Empila $fp 
sw $s0, -4($sp)			# Empila $s0 
sw $s1, -8($sp)			# Empila $s1 
sw $s2, -12($sp)		# Empila $s2 
lw $s3, -16($sp)		# Empilo $s3 
lw $s4, -20($sp)		# Empilo $s4 
lw $s5, -24($sp)		# Empilo $s5
lw $s6, -28($sp)		# Empilo $s6 
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -32		# Moviliza el $sp 32 posiciones hacia arriba
la $s3, nombre1			# Cargo en $s3 la direccion del primer nombre
la $s4, nombre2			# Cargo en $s4 la direccion del segundo nombre
la $s0, comando+2		# Cargo en $s0 la direccion del ultimo caracter chequeado en comando
li $s1, 0			# Inicializo $s1 con 0 (contador de nombres)
li $s6, 0			# Inicializo $s6 con 0 (indicador de exces0 de longitud)
li $s5, 0			# Inicializo $s5 con 0 (contador de caracteres por nombre)
loop: addi $s0, $s0, 1		# Aumento la posicion del apuntador al siguiente caracter ($s0)
lb $s2, ($s0) 			# Cargo el caracter en $s2
beq $s2, 0x20, loop		# Si el caracter es "espacio" continuo buscando inicio de nombre
beq $s2, 0Xa, loop2		# Si el caracter es "\n" termina el conteo
beq $s2, 0x0, loop2		# Si el caracter es "null" termina el conteo
blt $s5, 21, next2		# Si la cantidad de caracteres del nombre es menor a 21 continua
li $s6, 1			# Si no lo indica en $s6
next2: li $s5, 0		# Inicializo el contador de caracteres del nuevo nombre
addi $s1, $s1, 1 		# Si no es "espacio" cuento un nuevo nombre 
loop1: bne $s1, 1, next		# Si no es la primera palabra continua la ejecucion
sb $s2, ($s3)			# Si es, alamacena este caracter dentro de la primera palabra
addi $s3, $s3 ,1		# Incrementa el puntero de la primera palabra
addi $s5, $s5, 1		# Incremento el contador de caracteres para nombre1 en caso de ser el primer parametro
j next1				# Salta para continuar con el conteo
next: bne $s1, 2, next1		# Si no es la segunda palabra continua con la ejecucion
sb $s2, ($s4)			# Si es, almacena este caracter dentro de la segunda palabra
addi $s4, $s4 ,1		# Incrementa el puntero de la segunda palabra
addi $s5, $s5, 1		# Incremento el contador de caracteres para nombre2 en caso de ser el segundo parametro
next1: addi $s0, $s0, 1		# Aumento la posicion del apuntador al siguiente caracter ($s0)
lb $s2, ($s0) 			# Cargo el caracter en $s2
beq $s2, 0x20, loop		# Si el caracter es "espacio" busco el inicio del siguiente nombre
bne $s2, 0x0, loop1		# Si el caracter no es "espacio" y no es "null" sigo recorriendo el nombre
loop2: move $v0, $s1		# Si ya termino el comando (caracter "\n" o "null") retorno la cantidad de nombres contados
move $v1, $s6			# Retorno el indicador de exceso de longitud de nombres
move $sp, $fp			# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $s0, -4($sp)			# Desempilo $s0 
lw $s1, -8($sp)			# Desempilo $s1 
lw $s2, -12($sp)		# Desempilo $s2 
lw $s3, -16($sp)		# Desempilo $s3
lw $s4, -20($sp)		# Desempilo $s4 
lw $s5, -24($sp)		# Desempilo $s5
lw $s6, -28($sp)		# Desempilo $s6 
jr $ra				# Retorna al llamador

# dir_cp: Devuelve errores -2, -5, -6 y -7
dir_cp:
sw $fp, ($sp)			# Empila $fp 
sw $ra, -4($sp)			# Empila $ra
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -8		# Moviliza el $sp 8 posiciones hacia arriba
jal nombres			# Invocacion de la rutina que cuenta nombres
move $t0, $v0 			# Recibe la cantidad de nombres
bne $t0, 2, errorCopiar1	# Si la cantidad de nombres no es 2 debe mostrar error
move $t0, $v1			# Reviso si los nombres se excedieron en longitud
bnez $t0, errorCopiar4		# De ser asi muestro error
la $a0, nombre1			# Carga argumento para la rutina siguiente (Puntero al nombre del archivo a copiar)
jal buscar			# Invoca la rutina para verificar que el archivo existe
beqz $v0, errorCopiar2	 	# Si devolvio 0 (No consiguio archivo con este nombre) salta a mostrar error
move $t3, $v0			# Resguarda la direccion del archivo a copiar
la $a0, nombre2			# Carga argumento para la rutina siguiente (Puntero al nombre del archivo a crear)
jal buscar			# Invoca la rutina para verificar que el nombre de archivo no es usado por uno creado previamente
bnez $v0, errorCopiar3	 	# Si no devolvio 0 (Consiguio archivo con este nombre) salta a mostrar error
lw $t4, 40($t3)			# Reviso si la pieza de archivo actual es unica o la primera de un grupo
bnez $t4, variosCopiar		# Si no es unica salto al bloque de codigo de procesamiento multiple
lw $a3, 20($t3)			# Cargo el tamano del trozo de archivo
lw $a1, 24($t3)			# Cargo el puntero al contenido a replicar
lw $a2, 40($t3)			# Cargo el indicador de que la pieza de archivo actual es unica
jal duplicar			# Invoco la rutina que duplica un trozo de archivo
j exitoCopiar			# Al terminar salgo de la rutina
variosCopiar: lw $a3, 20($t3)	# Cargo el tamano del trozo de archivo
lw $a1, 24($t3)			# Cargo el puntero al contenido a replicar
lw $a2, 40($t3)			# Cargo el indicador de que posicion tiene la pieza de archivo en su grupo
jal duplicar			# Invoco la rutina que duplica un trozo de archivo
lw $t0, 36($t3)			# Ubico la siguiente pieza del grupo
move $a0, $t3			# Carga esa direccion 
move $a1, $t0			# Paso la direccion del actual 
jal comparar			# Invoco la rutina que asegura que pertenecen al mismo grupo
beqz $v0, exitoCopiar		# Si no lo son termino la operacion 
move $t3, $t0			# Si lo son indico el trozo ubicado como el siguiente
j variosCopiar			# Vuelvo a realizar la operacion
errorCopiar1: li $v0, -2	# Indicar el codigo del error
j copiarFin			# Saltar al bloque final
errorCopiar2: li $v0, -6	# Indicar el codigo del error
j copiarFin			# Saltar al bloque final
errorCopiar3: li $v0, -5	# Indicar el codigo del error
j copiarFin			# Saltar al bloque final
errorCopiar4: li $v0, -7	# Indicar el codigo del error
j copiarFin			# Saltar al bloque final
exitoCopiar: li $v0, 0		# Indico operacion exitosa
copiarFin: move $sp, $fp	# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $ra, -4($sp)			# Desempilo $ra 
jr $ra				# Retorna al llamador

# Rutina que copia un archivo dentro del sistema
duplicar:
sw $fp, ($sp)			# Empila $fp
sw $s0, -4($sp)			# Empila $s0 
sw $s1, -8($sp)			# Empila $s1
sw $s2, -12($sp)		# Empila $s2
sw $ra, -16($sp)		# Desempilo $ra 
move $fp, $sp 			# Mueve a $fp el valor de $sp
addi $sp, $sp, -20		# Moviliza el $sp 20 posiciones hacia arriba
li $v0, 9			# Indicar servicio de asignacion de espacio heap
li $a0, 101			# Indica el tamaño del espacio para el contenido 
syscall				# Ejecuta el servicio
move $s2, $v0			# Coloca el valor de la direccion de espacio heap asignado a $s2
li $s0, 0 			# Inicializa $a1 como apuntador del contenido a duplicar
llenarCopiar: lb $s1, ($a1)	# Cargo el caracter apuntado actualmente
sb $s1, ($s2)			# Lo almacena en el espacio heap asignado donde le corresponde
addi $a1, $a1, 1		# Incremento apuntador del contenido
addi $s2, $s2, 1		# Incremento apuntador del espacio heap
addi $s0, $s0, 1		# Decremento el contador de caracteres
bne $s0, 100, llenarCopiar	# Si este aun no es 0, continua trasladando el contenido por caracter
sb $zero, ($s2)			# Coloco null al final del contenido
la $a1, nombre2			# Carga $a1 como apuntador del nombre del archivo a crear
move $a0, $a2			# Dice que si es el primer trozo de archivo, si es unico, etc
move $a2, $a3			# Dice el tamano del trozo de archivo
move $a3, $v0			# Carga $a3 con la direccion definitiva el contenido del archivo a crear 
jal insertar			# Invoca la rutina para terminar de crear el archivo
move $sp, $fp			# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $s0, -4($sp)			# Desempilo $s0 
lw $s1, -8($sp)			# Desempilo $s1 
lw $s2, -12($sp)		# Desempilo $s2 
lw $ra, -16($sp)		# Desempilo $ra 
jr $ra				# Retorna al llamador

# dir_ren: Devuelve errores -2, -5, -6 y -7
dir_ren:
sw $fp, ($sp)			# Empila $fp 
sw $ra, -4($sp)			# Empila $ra
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -8		# Moviliza el $sp 8 posiciones hacia arriba
jal nombres			# Invocacion de la rutina que cuenta nombres
move $t0, $v0 			# Recibe la cantidad de nombres
bne $t0, 2, errorRenombrar1	# Si la cantidad de nombres no es 2 debe mostrar error
move $t0, $v1			# Reviso si los nombres se excedieron en longitud
bnez $t0, errorRenombrar4	# De ser asi muestro error
la $a0, nombre1			# Carga argumento para la rutina siguiente (Puntero al nombre del archivo a renombrar)
jal buscar			# Invoca la rutina para verificar que el archivo existe
beqz $v0, errorRenombrar2	# Si devolvio 0 (No consiguio archivo con este nombre) salta a mostrar error
move $t3, $v0			# Resguarda la direccion del archivo a renombrar
la $a0, nombre2			# Carga argumento para la rutina siguiente (Puntero al nuevo nombre del archivo)
jal buscar			# Invoca la rutina para verificar que el nombre de archivo no es usado por uno creado previamente
bnez $v0, errorRenombrar3	# Si no devolvio 0 (Consiguio archivo con este nombre) salta a mostrar error
lw $t4, 40($t3)			# Reviso si la pieza de archivo es unica o pertenece a un grupo
bnez $t4, variosRen		# De pertenecer un grupo salto al bloque de procesamiento multiple
la $a0, nombre2			# Cargo el nuevo nombre que se le colocara al archivo
move $a1, $t3			# Cargo la direccion del trozo de archivo
jal nombrado			# Invoco la rutina para cambiar el nombre de un trozo de archivo
j exitoRenombrar		# Al terminar salgo de la rutina
variosRen: lw $t0, 36($t3)	# Ubico el siguiente trozo de archivo
move $a0, $t3			# Cargo la direccion del trozo actual
move $a1, $t0			# Cargo la direccion del trozo siguiente
bnez $a1, sigueRen		# Si esta direccion apunta a algun trozo termina la operacion
li $t1, 0			# Si no indica que termino la operacion
j ultimoRen			# Salgo de procesamiento
sigueRen: jal comparar		# Invoco la rutina que asegura que ambos trozos pertenzcan al mismo grupo
move $t1, $v0			# Resguardo el resultado de la instruccion anterior
ultimoRen: la $a0, nombre2	# Indico el nuevo nombre del archivo
move $a1, $t3			# Cargo la direccion del trozo actual
jal nombrado			# Invoco la rutina que cambia el nombre del trozo actual
beqz $t1, exitoRenombrar	# Si la comparacion del trozo siguiente indica que no pertenece al grupo salgo
move $t3, $t0			# Si el trozo pertenece lo coloca como el trozo actual
j variosRen			# Vuelve para efectuar la operacion
errorRenombrar1: li $v0, -2	# Indicar el codigo del error
j renombrarFin			# Salto al bloque final
errorRenombrar2: li $v0, -6	# Indicar el codigo del error
j renombrarFin			# Saltar al bloque final
errorRenombrar3: li $v0, -5	# Indicar el codigo del error
j renombrarFin			# Saltar al bloque final
errorRenombrar4: li $v0, -7	# Indicar el codigo del error
j renombrarFin			# Saltar al bloque final
exitoRenombrar: li $v0, 0	# Indico operacion exitosa
renombrarFin: move $sp, $fp	# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $ra, -4($sp)			# Desempilo $ra 
jr $ra				# Retorna al llamador

# Rutina que renombra un archivo del sistema
nombrado:
sw $fp, ($sp)			# Empila $fp
sw $s0, -4($sp)			# Empila $s0 
sw $s2, -8($sp)			# Empila $s2
sw $s4, -12($sp)		# Empila $s4
sw $s5, -16($sp)		# Empila $s5
sw $s6, -20($sp)		# Empila $s6
move $fp, $sp 			# Mueve a $fp el valor de $sp
addi $sp, $sp, -24		# Moviliza el $sp 24 posiciones hacia arriba
li $s0, 20			# Inicializo contador de caracteres
nombrar: lb $s2, ($a0)		# Cargo el caracter actual del nuevo nombre
sb $s2, ($a1)			# Reemplazo dicho caracter en el nombre del archivo
addi $a0, $a0, 1		# Incremento apuntador del nombre nuevo
addi $a1, $a1, 1		# Incremento apuntador del nombre de archivo
addi $s0, $s0, -1		# Decremento el contador de caracteres
seq $s4, $s2, 0x0		# Verifico si el caracter es "null" 
seq $s5, $s2, 0xa		# Verifico si el caracter es "\n" 
seq $s6, $s2, 0x20		# Verifico si el caracter es "espacio" 
or $s4, $s4, $s5		# Evaluo si el caracter es "null" o "\n"
or $s4, $s4, $s6		# Evaluo si el caracter es alguno de los anteriores o "espacio"
beqz $s4, nombrar		# Si no es ninguno de los anteriores continuo reemplazando
beqz $s0, nombradoFin		# Si el contador indica que el reemplazo abarco los 20 caracteres finaliza
llenarCeros: sb $zero, ($a1)	# Si no lleno con cero los caracteres luego del reemplazo
addi $a1, $a1, 1		# Incrementa apuntador hasta el final de los caracteres faltantes
addi $s0, $s0, -1		# Decrementa el contador de caracteres
bnez $s0, llenarCeros		# Continua llenando hasta que el contador indique 0
nombradoFin: move $sp, $fp	# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $s0, -4($sp)			# Desempilo $s0 
lw $s2, -8($sp)			# Desempilo $s2 
lw $s4, -12($sp)		# Desempilo $s4 
lw $s5, -16($sp)		# Desempilo $s5 
lw $s6, -20($sp)		# Desempilo $s6 
jr $ra

# dir_rm: Devuelve errores -2, -6 y -7
dir_rm:
sw $fp, ($sp)			# Empila $fp 
sw $ra, -4($sp)			# Empila $ra
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -8		# Moviliza el $sp 8 posiciones hacia arriba
jal nombres			# Invocacion de la rutina que cuenta nombres
move $t0, $v0 			# Recibe la cantidad de nombres
bne $t0, 1, errorBorrar1	# Si la cantidad de nombres no /es 1 debe mostrar error/
move $t0, $v1			# Reviso si los nombres se excedieron en longitud
bnez $t0, errorBorrar3		# De ser asi muestro error
la $a0, nombre1			# Carga argumento para la rutina siguiente (Puntero al nombre del archivo a mostrar)
jal buscar			# Invoca la rutina para verificar que el archivo existe
beqz $v0, errorBorrar2	 	# Si devolvio 0 (No consiguio archivo con este nombre) salta a mostrar error
move $t3, $v0			# Carga la direccion del trozo de archivo actual
lw $t4, 40($t3)			# Revisa si es un trozo unico o parte de un grupo
bnez $t4, variosBorrar		# Si forma parte de un grupo va al codigo de procesamiento multiple
move $a0, $t3			# Carga la direccion del trozo de archivo actual
jal eliminar			# Invoca la rutina que lo elimina del sistema
j exitoBorrar			# Salto a finalizar
variosBorrar: lw $t0, 36($t3)	# Ubica el siguiente trozo
move $a0, $t3			# Carga la direccion del trozo actual
move $a1, $t0			# Carga la direccion el trozo siguiente
bnez $a1, sigueElm		# Si la direccion no apunta a algun trozo de archivo continua
li $t1, 0			# Indica que no hay que continuar la operacion
j ultimoElm			# Sale del procesamiento
sigueElm: jal comparar		# Si la direccion apunta a un trozo de archivo confirma que pertenecen al mismo grupo
move $t1, $v0			# Resguardo el resultado de la instruccion anterior
ultimoElm: move $a0, $t3	# Carga la direccion del trozo actual
jal eliminar			# Lo elimina del sistema
beqz $t1, exitoBorrar		# Si no hay mas trozos termina la operacion
move $t3, $t0			# Si el trozo siguiente pertenece al grupo lo coloca como el trozo actual
j variosBorrar			# Vuelve a realizar la operacion
errorBorrar1: li $v0, -2	# Indicar el codigo del error
j borrarFin			# Saltar al bloque final
errorBorrar2: li $v0, -6	# Indicar el codigo del error
j borrarFin			# Salta al bloque final
errorBorrar3: li $v0, -7	# Indicar el codigo del error
j borrarFin			# Saltar al bloque final
exitoBorrar: li $v0, 0		# Indicar operacion exitosa
borrarFin: move $sp, $fp	# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $ra, -4($sp)			# Desempilo $ra 
jr $ra				# Retorna al llamador

# Rutina que elimina un archivo del sistema de directorio
eliminar:
sw $fp, ($sp)			# Empila $fp
sw $s0, -4($sp)			# Empila $s0 
sw $s1, -8($sp)			# Empila $s1
sw $s2, -12($sp)		# Empila $s2
sw $s3, -16($sp)		# Empila $s3
sw $s4, -20($sp)		# Empila $s4
move $fp, $sp 			# Mueve a $fp el valor de $sp
addi $sp, $sp, -24		# Moviliza el $sp 24 posiciones hacia arriba
move $s0, $a0			# Recibo direccion nodo a eliminar
la $s1, lista			# Cargo direccion de nodo maestro
lw $s2, ($s1)			# Apunto al nodo maestro
lw $s4, 4($s2)			# Cargo el puntero del nodo inicial
bne $s0, $s4, sigElm		# Si el elemento a borrar es el primero sigo
lw $s3, 36($s0)			# Extraigo el puntero del nodo siguiente del nodo a eliminar
sw $s3, 4($s2)			# Lo ingreso como nodo inicial en el nodo maestro
sw $zero, 32($s3)		# Borro puntero a nodo anterior en el nodo inicial nuevo
j finalEliminar			# Final
sigElm: lw $s4, 8($s2)		# Cargo el puntero del nodo final
bne $s0, $s4, sigElm1		# Si el elemento no es el primero veo si es el ultimo
lw $s3, 32($s0)			# Si es el ultimo extraigo el puntero a su nodo anterior
sw $s3, 8($s2)			# Lo almaceno como el nodo final en el nodo maestro
sw $zero, 36($s3)		# Borro puntero a nodo siguiente el nodo final nuevo
j finalEliminar			# Final
sigElm1: lw $s3, 32($s0)	# Nodo Anterior del nodo a eliminar
lw $s4, 36($s0)			# Nodo Siguiente del nodo a eliminar
sw $s4, 36($s3)			# Almaceno nodo siguiente como tal en el anterior
sw $s3, 32($s4)			# Almaceno nodo anterior como tal en nodo siguiente
finalEliminar: lw $s4, ($s2)	# Extrae la cantidad de trozos de archivos
addi $s4, $s4, -1		# Lo decremento
sw $s4, ($s2)			# Lo almaceno nuevamente
move $sp, $fp			# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $s0, -4($sp)			# Desempilo $s0 
lw $s1, -8($sp)			# Desempilo $s1 
lw $s2, -12($sp)		# Desempilo $s2 
lw $s3, -16($sp)		# Desempilo $s1 
lw $s4, -20($sp)		# Desempilo $s2 
jr $ra

# dir_ls: Devuelve error -2
dir_ls:
sw $fp, ($sp)			# Empila $fp 
sw $ra, -4($sp)			# Empila $ra
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -8		# Moviliza el $sp 8 posiciones hacia arriba
jal nombres			# Invocacion de la rutina que cuenta nombres
move $t0, $v0 			# Recibe la cantidad de nombres
bne $t0, 0, errorListar1	# Si la cantidad de nombres no es 0 debe mostrar error
# Ejecucion listar
j exitoListar			# Saltar a exitoListar para no mostrar error
errorListar1: li $v0, -2	# Indicar el codigo del error
j listarFin			# Saltar al bloque final
exitoListar: li $v0, 0		# Indico operacion exitosa
listarFin: move $sp, $fp	# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $ra, -4($sp)			# Desempilo $ra 
jr $ra				# Retorna al llamador

# dir_cat: Devuelve errores -2, -6 y -7
dir_cat:
sw $fp, ($sp)			# Empila $fp 
sw $ra, -4($sp)			# Empila $ra
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -8		# Moviliza el $sp 8 posiciones hacia arriba
jal nombres			# Invocacion de la rutina que cuenta nombres
move $t0, $v0 			# Recibe la cantidad de nombres
bne $t0, 1, errorMostrar1	# Si la cantidad de nombres no es 1 debe mostrar error
move $t0, $v1			# Reviso si los nombres se excedieron en longitud
bnez $t0, errorMostrar3		# De ser asi muestro error
la $a0, nombre1			# Carga argumento para la rutina siguiente (Puntero al nombre del archivo a mostrar)
jal buscar			# Invoca la rutina para verificar que el archivo existe
beqz $v0, errorMostrar2	 	# Si devolvio 0 (No consiguio archivo con este nombre) salta a mostrar error
lw $t4, 40($v0)			# Revisa si el trozo es unico o parte de un archivo mas grande		
move $t3, $v0			# Carga la direccion del trozo actual
bnez $t4, variosMostrar		# Si no es unico salta a procesar multiples trozos
lw $a0, 24($t3)			# Cargo la direccion del contenido del trozo
jal mostrado			# Invoco la rutina que lo muestra
j exitoMostrar			# Sale del procesamiento
variosMostrar: lw $a0, 24($t3)	# Cargo la direccion del contenido del trozo
jal mostrado			# Invoco la rutina que lo muestra
lw $t0, 36($t3)			# Ubico el siguiente trozo
move $a0, $t3			# Cargo la direccion del trozo actual
move $a1, $t0			# Cargo la direccion del trozo siguiente
beqz $a1, exitoMostrar		# Si esta direccion no apunta a ningun trozo salto a finalizar
jal comparar			# Confirmo que el trozo siguiente forma parte del archivo
beqz $v0, exitoMostrar		# Si no es asi finalizo 
move $t3, $t0			# Si lo es, lo coloco como trozo actual
j variosMostrar			# Regreso para mostrarlo	
errorMostrar1: li $v0, -2	# Indicar el codigo del error
j mostrarFin			# Salta al bloque final
errorMostrar2: li $v0, -6	# Indicar el codigo del error
j mostrarFin			# Salta al bloque final
errorMostrar3: li $v0, -7	# Indicar el codigo del error
j mostrarFin			# Saltar al bloque final
exitoMostrar: li $v0, 0		# Indicar operacion exitosa
mostrarFin: move $sp, $fp	# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $ra, -4($sp)			# Desempilo $ra 
jr $ra				# Retorna al llamador

mostrado:
sw $fp, ($sp)			# Empila $fp 
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -4		# Moviliza el $sp 4 posiciones hacia arriba
li $v0, 4			# Indico el servicio de mostrar por consola
syscall				# Ejecuto el servicio
move $sp, $fp			# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
jr $ra				# Saltar a exitoMostrar para no mostrar error

# dir_ci: Devuelve errores -2 y -7
dir_ci:
sw $fp, ($sp)			# Empila $fp 
sw $ra, -4($sp)			# Empila $ra
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -8		# Moviliza el $sp 8 posiciones hacia arriba
jal nombres			# Invocacion de la rutina que cuenta nombres
move $t0, $v0 			# Recibe la cantidad de nombres
bne $t0, 2, errorCifrar1	# Si la cantidad de nombres no es 2 debe mostrar error
move $t0, $v1			# Reviso si los nombres se excedieron en longitud
bnez $t0, errorCifrar2		# De ser asi muestro error


# lw $t1, dirHeap #Cargamos el numero de lineas
lb $t3, byte1 #cargamos "\"
lb $t5, byte2 #cargamos "\"
# en a0 tenemos direccion donde empiza nuestro contenido de nuestro archivo
lb $t0, ($a0) #cargamos byte en t0

while:
bgtz $t1, finWhile   #While(cantidadDeLineasDocumento>0){
move $a0, $t0 #movemos el contenido (el byte a $a0) para cifrarlo
jalr  $a1 #$a1 tienen la direccion de la funcion que se le paso desde consola
sb $v0, ($t0) #$v0 esta el contenido (byte cidrado) y se guarda en la misma direccion donde se saco el byte
addi $t0, $zero, 1 #Nos movemos al sig byte
bne $t0, $t3, while #si $t0 != "\"
addi $t4, $t0, 1 #Nos movemos al sig byte
bne $t4, $t5, while #si $t4 != "n"
addi $t1,$t1, -1 #restamos 1 a la cantidad de linea
j while

finWhile:

#Aca solo falta moficar el nombre y ya del archivo

j exitoCifrar			# Saltar a cifrarFin para no mostrar error
errorCifrar1: li $v0, -2	# Indicar el codigo del error
j cifrarFin			# Salta al bloque final
errorCifrar2: li $v0, -7	# Indicar el codigo del error
j cifrarFin			# Saltar al bloque final
exitoCifrar: li $v0, 0		# Indicar operacion exitosa
cifrarFin: move $sp, $fp	# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $ra, -4($sp)			# Desempilo $ra 
jr $ra				# Retorna al llamador

# dir_dc: Devuelve errores -2 y -7
dir_dc:
sw $fp, ($sp)			# Empila $fp 
sw $ra, -4($sp)			# Empila $ra
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -8		# Moviliza el $sp 8 posiciones hacia arriba
jal nombres			# Invocacion de la rutina que cuenta nombres
move $t0, $v0 			# Recibe la cantidad de nombres
bne $t0, 2, errorDescifrar1	# Si la cantidad de nombres no es 2 debe mostrar error
move $t0, $v1			# Reviso si los nombres se excedieron en longitud
bnez $t0, errorDescifrar2	# De ser asi muestro error
# Ejecucion descifrar
j exitoDescifrar		# Saltar a exitoDescifrar para no mostrar error
errorDescifrar1: li $v0, -2	# Indicar el codigo del error
j descifrarFin			# Salta al bloque final
errorDescifrar2: li $v0, -7	# Indicar el codigo del error
j descifrarFin			# Saltar al bloque final
exitoDescifrar: li $v0, 0	# Indicar operacion exitosa
descifrarFin: move $sp, $fp	# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $ra, -4($sp)			# Desempilo $ra 
jr $ra				# Retorna al llamador

# dir_mk: Devuelve errores -2, -5 y -7
dir_mk:
sw $fp, ($sp)			# Empila $fp 
sw $ra, -4($sp)			# Empila $ra
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -8		# Moviliza el $sp 8 posiciones hacia arriba
jal nombres			# Invocacion de la rutina que cuenta nombres
move $t0, $v0 			# Recibe la cantidad de nombres
bne $t0, 1, errorCrear1		# Si la cantidad de nombres no es 1 debe mostrar error
move $t0, $v1			# Reviso si los nombres se excedieron en longitud
bnez $t0, errorCrear3		# De ser asi muestro error
la $a0, nombre1			# Carga argumento para la rutina siguiente (Puntero al nombre del archivo a crear)
jal buscar			# Invoca la rutina para verificar que el nombre de archivo no es usado por uno creado previamente
bnez $v0, errorCrear2	 	# Si no devolvio 0 (No consiguio archivo con este nombre) salta a mostrar error
li $v0, 8			# Indicar servicio de lectura por teclado
la $a0, contenido		# Indica direccion de memoria donde se almacenara lo ingresado
li $a1, 101			# Indica el maximo de caracteres esperados
syscall				# Ingreso el contenido del archivo
li $t0, 0			# Inicializo $t0 como contador de caracteres
contarCrear: lb $t1, ($a0)	# Cargo el caracter del contenido del archivo apuntado actualmente
addi $a0, $a0, 1		# Incremento el apuntador del contenido del archivo
addi $t0, $t0, 1		# Incremento el contador de caracteres
bne $t1, 0x0, contarCrear	# Si el caracter leido no es null continua recorriendo el contenido
li $v0, 9			# Indicar servicio de asignacion de espacio heap
li $a0, 101			# Indica el tamaño del espacio para el contenido 
syscall				# Ejecuta el servicio
move $t2, $v0			# Coloca el valor de la direccion de espacio heap asignado a $t2
la $a1, contenido		# Inicializa $a1 como apuntador del contenido
llenarCrear: lb $t1, ($a1)	# Cargo el caracter apuntado actualmente
sb $t1, ($t2)			# Lo almacena en el espacio heap asignado donde le corresponde
addi $a1, $a1, 1		# Incremento apuntador del contenido
addi $t2, $t2, 1		# Incremento apuntador del espacio heap
addi $t0, $t0, -1		# Decremento el contador de caracteres
bnez $t0, llenarCrear		# Si este aun no es 0, continua trasladando el contenido por caracter
sb $zero, ($t2)			# Cargo null al final del contenido
la $a1, nombre1			# Carga $a1 como apuntador del nombre del archivo a crear
move $a2, $a0			# Carga $a2 con el tamaño del contenido del archivo a crear
move $a3, $v0			# Carga $a3 con la direccion defnitiva el contenido del archivo a crear
li $a0, 0			# Indica que ocupa solo un sector de archivo
jal insertar			# Invoca la rutina para terminar de crear el archivo
j exitoCrear			# Saltar a exitoCrear para no mostrar error
errorCrear1: li $v0, -2		# Indicar codigo de error 
j crearFin			# Saltar al bloque final
errorCrear2: li $v0, -5		# Indicar codigo de error
j crearFin			# Saltar al bloque final
errorCrear3: li $v0, -7		# Indicar el codigo del error
j crearFin			# Saltar al bloque final
exitoCrear: li $v0, 0		# Indico operacion exitosa
crearFin: move $sp, $fp		# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $ra, -4($sp)			# Desempilo $ra 
jr $ra				# Retorna al llamador

# Rutina que inserta un archivo en el sistema de directorio
insertar: 
sw $fp, ($sp)			# Empila $fp
sw $s0, -4($sp)			# Empila $s0 
sw $s1, -8($sp)			# Empila $s1 
sw $s2, -12($sp)		# Empila $s2
sw $s3, -16($sp)		# Empila $s3
sw $s4, -20($sp)		# Empila $s4
sw $s5, -24($sp)		# Empila $s5
move $fp, $sp 			# Mueve a $fp el valor de $sp
addi $sp, $sp, -28		# Moviliza el $sp 28 posiciones hacia arriba
la $s5, lista			# Inicializo $s5 con la referencia al lugar donde se encuentra la direccion del nodo maestro
lw $s1, ($s5)			# Inicializo $s1 como el puntero al nodo maestro de la lista
li $v0, 9			# Indica servicio de asignacion de espacio heap
li $a0, 44			# Indica cantidad de espacio necesario
syscall				# Ejecuta el servicio
move $s2, $v0			# Creo en $s2 copia del valor de $v0 para preservarlo 
volver: lb $s0, ($a1)		# Cargo en el registro $s0 el caracter señalado por el puntero del nombre
beq $s0, 0x0, sig		# Continuo la carga del siguiente dato si el caracter es "null" 
beq $s0, 0xa, sig		# Continuo la carga del siguiente dato si el caracter es "\n" 
beq $s0, 0x20, sig		# Continuo la carga del siguiente dato si el caracter es "espacio" 
sb $s0, ($s2)			# Almaceno dicho caracter en la estructura recien creada
addi $s2, $s2, 1		# Incremento puntero del nodo creado para insertar siguiente caracter del nombre
addi $a1, $a1, 1		# Incremento el puntero para señalar al siguiente caracter del nombre
j volver			# Salto para continuar la carga del nombre
sig: sw $a2, 20($v0)		# Almaceno el tamaño del archivo
sw $a3, 24($v0)			# Almaceno la direccion que apunta al contenido del archivo
sw $zero, 28($v0)		# Inicializo el indicador de cifrado en cero
lw $s2, 4($s1)			# Almaceno en $s2 el puntero inicial de la lista
lw $s3, ($s1)			# Almaceno en $s3 la cantidad de elementos de la lista
lw $s4, 8($s1)			# Almaceno en $s4 el puntero final de la lista
bnez $s3, sig1			# Si el elemento a insertar no es el primero continuo la insercion
sw $v0, 4($s1)			# Si es el primer elemento coloco su direccion como puntero inicial
sig1: sw $v0, 8($s1)		# Almaceno la direccion del nodo actual como puntero final
sw $s4, 32($v0)			# Almaceno la direccion del puntero final como puntero anterior del nodo actual
beqz $s3, sig2			# Si el elemento a insertar es el primero continuo la insercion
sw $v0, 36($s4)			# Almaceno la direccion del nodo actual como puntero siguiente del nodo anterior
sw $a0, 40($v0)			# Indico si es el primer trozo de un archivo, si es unico, etc
sig2: addi $s3, $s3, 1		# Incremento el tamaño de la lista
sw $s3, ($s1)			# Actualizo el tamaño de la lista en el nodo maestro
move $sp, $fp			# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $s0, -4($sp)			# Desempilo $s0 
lw $s1, -8($sp)			# Desempilo $s1 
lw $s2, -12($sp)		# Desempilo $s2 
lw $s3, -16($sp)		# Desempilo $s3
lw $s4, -20($sp)		# Desempilo $s4
lw $s5, -24($sp)		# Desempilo $s5
jr $ra				# Retorna al llamador

# Rutina que verifica si dos nombres son iguales 
comparar:
sw $fp, ($sp)			# Empila $fp
sw $s0, -4($sp)			# Empila $s0 
sw $s1, -8($sp)			# Empila $s1
sw $s2, -12($sp)		# Empila $s2
sw $s3, -16($sp)		# Empila $s3
sw $s4, -20($sp)		# Empila $s4
sw $s5, -24($sp)		# Empila $s5
sw $s6, -28($sp)		# Empila $s6
sw $s7, -32($sp)		# Empila $s7
move $fp, $sp 			# Mueve a $fp el valor de $sp
addi $sp, $sp, -36		# Moviliza el $sp 36 posiciones hacia arriba
li $s0, 1			# Indico en $s0 que aun no he conseguido caracteres diferentes
li $s1, 1			# Indico en $s1 que aun no he llegado al final de ninguno de los nombres
volverComp: and $s2, $s0, $s1	# Evaluo las dos condiciones de parada
beqz $s2, compararFinal		# Si alguna de las dos condiciones deja de cumplirse termino la comparacion
lb $s3, ($a0)			# Cargo el caracter actual del nombre a verificar
lb $s4, ($a1)			# Cargo el caracter actual del nombre verificado
seq $s5, $s3, 0x0		# Verifico si el caracter es "null" 
seq $s6, $s3, 0xa		# Verifico si el caracter es "\n" 
seq $s7, $s3, 0x20		# Verifico si el caracter es "espacio" 
or $s5, $s5, $s6		# Evaluo si el caracter es "null" o "\n"
or $s5, $s5, $s7		# Evaluo si el caracter es alguno de los anteriores o "espacio"
beqz $s5, segComp		# Si no lo es continuo comparando
li $s1, 0			# Si lo es, lo reflejo en $s1
li $s3, 0x0			# Reemplazo caracter por null para unificar criterios
segComp: seq $s5, $s4, 0x0	# Verifico si el caracter es "null" 
seq $s6, $s4, 0xa		# Verifico si el caracter es "\n"  
seq $s7, $s4, 0x20		# Verifico si el caracter es "espacio 
or $s5, $s5, $s6		# Evaluo si el caracter es "null" o "\n"
or $s5, $s5, $s7		# Evaluo si el caracter es alguno de los anteriores o "espacio"
beqz $s5, segComp1		# Si no lo es continuo comparando
li $s1, 0			# Si lo es, lo reflejo en $s1
li $s4, 0x0			# Reemplazo caracter por null para unificar criterios
segComp1: beq $s3, $s4, segComp2# Si los dos caracteres son iguales continuo comparando
li $s0, 0			# Si no, lo reflejo en $s0
segComp2: addi $a0, $a0, 1	# Incremento el puntero del nombre a verificar
addi $a1, $a1, 1		# Incremento el puntero del nombre verificado
j volverComp			# Vuelvo a chequear las condiciones de parada
compararFinal: move $v0, $s0	# Cargo el resultado de la comparacion en $v0
move $sp, $fp			# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $s0, -4($sp)			# Desempilo $s0 
lw $s1, -8($sp)			# Desempilo $s1 
lw $s2, -12($sp)		# Desempilo $s2
lw $s3, -16($sp)		# Desempilo $s3
lw $s4, -20($sp)		# Desempilo $s4
lw $s5, -24($sp)		# Desempilo $s5
lw $s6, -28($sp)		# Desempilo $s6
lw $s7, -32($sp)		# Desempilo $s7
jr $ra				# Retorna al llamador

# Rutina que busca un archivo dentro del sistema de directorio
buscar:
sw $fp, ($sp)			# Empila $fp
sw $ra, -4($sp)			# Empila $ra
sw $s1, -8($sp)			# Empila $s1 
sw $s2, -12($sp)		# Empila $s2
sw $s3, -16($sp)		# Empila $s3
sw $s4, -20($sp)		# Empila $s4
sw $s5, -24($sp)		# Empila $s5
sw $s0, -28($sp)		# Empila $s0
move $fp, $sp 			# Mueve a $fp el valor de $sp
addi $sp, $sp, -32		# Moviliza el $sp 32 posiciones hacia arriba
la $s0, lista			# Inicializo $s0 con la referencia al lugar donde se encuentra la direccion del nodo maestro
lw $s1, ($s0)			# Inicializo $s1 como el puntero al nodo maestro de la lista
lw $s2, ($s1)			# Almaceno en $s2 la cantidad de elementos de la lista 
li $v0, 0			# Inicializo $v0 con 0 asumiendo inicialmente que no existe el elemento buscado
beqz $s2, ninguno		# Si no hay elementos suspendo la busqueda
lw $s3, 4($s1)			# Almaceno en $s3 la direccion del nodo inicial 
busqueda: move $a1, $s3		# Almaceno en $a1 la direccion donde esta el nombre del nodo actual
move $s5, $s3			# Almaceno en $s5 la direccion del nodo actual
sw $a0, ($sp)			# Empila $a0
sw $s1, -4($sp)			# Empila $s1
sw $s2, -8($sp)			# Empila $s2
sw $s3, -12($sp)		# Empila $s3
sw $s5, -16($sp)		# Empila $s5
addi $sp, $sp, -20		# Moviliza el $sp 20 posiciones hacia arriba
jal comparar			# Invocacion de la rutina para comparar nombres 
addi $sp, $sp, 20		# Restauro el valor del $sp
lw $a0, ($sp)			# Desempilo $a0
lw $s1, -4($sp)			# Desempilo $s1
lw $s2, -8($sp)			# Desempilo $s2
lw $s3, -12($sp)		# Desempilo $s3
lw $s5, -16($sp) 		# Desempilo $s5
bnez $v0, encontrado		# Si el retorno es distinto de cero contiene la direccion del nodo buscado 
lw $s4, 36($s3)			# Si no, ubico el puntero al siguiente nodo 
move $s3, $s4			# Cargo en $s3 la direccion del siguiente nodo
addi $s2, $s2, -1		# Decremento el contador de archivos revisados
bnez $s2, busqueda		# Si el contador no ha llegado a cero continuo la busqueda
ninguno: li $v0, 0		# Si no hay elementos en la lista retorno 0
j finalBuscar 			# Saltamos al bloque de salida de la rutina
encontrado: move $v0, $s5	# Si encontramos el archivo retornamos su direccion
finalBuscar: move $sp, $fp	# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $ra, -4($sp)			# Desempilo $ra
lw $s1, -8($sp)			# Desempilo $s1 
lw $s2, -12($sp)		# Desempilo $s2 
lw $s3, -16($sp)		# Desempilo $s3
lw $s4, -20($sp)		# Desempilo $s4
lw $s5, -24($sp)		# Desempilo $s5
lw $s0, -28($sp)		# Desempilo $s0
jr $ra				# Retorna al llamador

# dir_init: Devuelve errores -2, -8, -9, -10 y -11
dir_init: 
sw $fp, ($sp)			# Empila $fp
sw $s0, -4($sp)			# Empila $s0
sw $s1, -8($sp)			# Empila $s1
sw $s2, -12($sp)		# Empila $s2
sw $s3, -16($sp)		# Empila $s3
sw $s4, -20($sp)		# Empila $s4
sw $s5, -24($sp)		# Empila $s5
sw $s6, -28($sp)		# Empila $s6
sw $s7, -32($sp)		# Empila $s7
sw $ra, -36($sp)		# Empila $ra
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -40		# Moviliza el $sp 40 posiciones hacia arriba
# Alojo en memoria dinamica el nodo que contendra los metadatos de la lista
# de archivos
li $v0, 9
la $a0, 12
syscall 
sw $zero, ($v0)
sw $zero, 4($v0) 
sw $zero, 8($v0)
sw $v0, lista
# Realizo la operacion de apertura de archivo
# de inicializacion
li   $v0, 13       
la   $a0, initFile 
li   $a1, 0        
li   $a2, 0        
syscall            
bltz $v0, errorInit1
# Realizo la lectura de archivo
# de inicializacion
li $s0, 0	
move $s1, $v0  
leer: 
li $v0, 14
move $a0, $s1
la $a1, fileBuffer
li $a2, 100
syscall
bltz $v0, errorInit2
la $t7, fileBuffer
addi $t7, $t7, 100
# Realizo la extraccion del numero que indica
# la cantidad de archivos
move $s2, $a1
bnez $s0, label
li $s3, 0		
la $s5, nArchivos
contarNum1: lb $s4, ($s2)
addi $s2, $s2, 1
addi $s3, $s3, 1
bgt $s3, 4, errorInit3
sb $s4, ($s5)
addi $s5, $s5, 1
bne $s4, 0xD, contarNum1
la $a3, nArchivos
move $a2, $s3 
add $a2, $a2, -1
jal asciiToHex
sw $v0, ($a3)
li $s0, 1
la $s6, nombre1
li $s3, 0
addi $s2, $s2, 1
# Realizo la extraccion del nombre del archivo
# actual que debe ser creado 
label: bne $s0, 1, label1
move $s5, $s2
contarCaracter: lb $s4, ($s2)
addi $s2, $s2, 1
addi $s3, $s3, 1
beq $s2, $t7, cargarNombre
bne $s4, 0xD, contarCaracter
bgt $s3, 21, errorInit4
cargarNombre: move $s2, $s5
cargarCaracter: lb $s4, ($s2)	
sb $s4, ($s6)			
addi $s2, $s2, 1		
addi $s6, $s6, 1		
beq $s2, $t7, leer
bne $s4, 0xD, cargarCaracter	
sb $zero, -1($s6)
li $s0, 2
la $s5, nLineas
li $s3, 0
addi $s2, $s2, 1
# Realizo la extraccion del numero que indica
# la cantidad de lineas del archivo actual
label1: bne $s0, 2, label2
contarNum2: lb $s4, ($s2)
addi $s2, $s2, 1
addi $s3, $s3, 1
bgt $s3, 4, errorInit5
sb $s4, ($s5)
addi $s5, $s5, 1
beq $s2, $t7, leer
bne $s4, 0xD, contarNum2
la $a3, nLineas
move $a2, $s3 
addi $a2, $a2, -1
jal asciiToHex
sw $v0, ($a3)
move $s7, $v0
li $s0, 3
la $s5, contentBuffer
li $s3, 0
addi $s2, $s2, 1
li $s6, 100
# Realizo la extraccion de las lineas de 
# contenido del archivo actual y lo creo
label2: bnez $s6, cargaContent
li $s6, 100
cargaContent: lb $s4, ($s2)
sb $s4, ($s5)
addi $s2, $s2, 1
addi $s5, $s5, 1 
addi $s6, $s6, -1 
bne $s4, 0xA, sigueCarga
addi $s7, $s7, -1 
sigueCarga: beq $s2, $t7, leer
seq $t8, $s6, 0
seq $t9, $s7, 0
or $t9, $t8, $t9
beqz $t9, cargaContent
addi $a2, $s6, -100
li $v0, 9			
li $a0, 101			 
syscall				
move $t9, $v0			
la $t8, contentBuffer		
llenarCrear1: lb $s4, ($t8)	
sb $s4, ($t9)			
addi $t8, $t8, 1		
addi $t9, $t9, 1		
addi $s6, $s6, 1		
bne $s6, 100, llenarCrear1	
sb $zero, ($t9)
la $a1, nombre1
mul $a2, $a2, -1
move $a3, $v0 
beq $s7, 0, sector1
addi $s3, $s3, 1
sector1: beqz $s3, sector2 
addi $s3, $s3, 1
sector2: move $a0, $s3
jal insertar
beq $s7, 0, fileEnd
la $s5, contentBuffer
li $s6, 100
j cargaContent 
# Finaliza la extraccion de datos
# del archivo y la inicializacion
fileEnd: la $t9, nArchivos
lb $t8, ($t9)
addi $t8, $t8, -1
sb $t8, ($t9)
la $a1, nombre1
li $a2, 20
jal limpiar
beqz $t8, exitoInit 
# Si no ha finalizado leyendo el archivo
# continua la inicializacion
li $s0, 1
la $s6, nombre1
li $s3, 0
blt $s2, $t7, label
j leer
errorInit1: li $v0, -8		# Indicar codigo de error 
j finInit
errorInit2: li $v0, -9		# Indicar codigo de error 
j finInit
errorInit3: li $v0, -10		# Indicar codigo de error 
j finInit
errorInit4: li $v0, -2		# Indicar codigo de error 
j finInit
errorInit5: li $v0, -11		# Indicar codigo de error 
j finInit
exitoInit: li $v0, 0		# Indicar operacion exitosa
# Cierra el archivo de inicializacion
finInit: move $a0, $s1
move $s1, $v0
li $v0, 16
syscall
#Finaliza la rutina
move $v0, $s1
move $sp, $fp			# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $s0, -4($sp)			# Desempilo $s0 
lw $s1, -8($sp)			# Desempilo $s1 
lw $s2, -12($sp)		# Desempilo $s2 
lw $s3, -16($sp)		# Desempilo $s3 
lw $s4, -20($sp)		# Desempilo $s4 
lw $s5, -24($sp)		# Desempilo $s5 
lw $s6, -28($sp)		# Desempilo $s6 
lw $s7, -32($sp)		# Desempilo $s7 
lw $ra, -36($sp)		# Desempila $ra
jr $ra

# Rutina que recibe un numero ingresado en digitos ASCII y lo lleva a su valor en hexadecimal
asciiToHex:
sw $fp, ($sp)			# Empila $fp
sw $s0, -4($sp)			# Empila $s0
sw $s1, -8($sp)			# Empila $s0
sw $s2, -12($sp)		# Empila $s0
sw $s3, -16($sp)		# Empila $s0
sw $s4, -20($sp)		# Empila $s0
sw $s5, -24($sp)		# Empila $s0
sw $s6, -28($sp)		# Empila $s0
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -32		# Moviliza el $sp 8 posiciones hacia arriba
move $s2, $a2			# Contador de digitos
move $s0, $a3 			# Puntero donde esta el num en codigo ASCII #Puntero donde esta espacio almacenamiento temporal para uso de la rutina
move $s5, $s2 			# Resguardo contador de digitos
asciiToNum: lb $s3, ($s0)	# Cargo el digito actual
and $s3, $s3, 0xF		# Limpio su parte alta (codigo ASCII)
sb $s3, ($s0)			# Lo almaceno en su sitio nuevamente
addi $s0, $s0, 1		# Incremento apuntador
addi $s2, $s2, -1		# Decremento contador
bnez $s2, asciiToNum		# Si no es cero sigo la operacion
move $s0, $a3			# Refresco el puntero
move $s2, $s5			# Refresco el contador
li $s3, 0			# Inicializo variable que contendra el numero de decimal
rotarUnir: lb $s1, ($s0)	# Cargo el digito actual
addi $s6, $s2, -1		# Obtengo la posicion que debe tener el digito dentro del numero
mul $s4, $s6, 4			# Multiplico por la cantidad de 4 bits que tiene
sllv $s1, $s1, $s4		# Roto para posicionarlo en su lugar
or $s3, $s3, $s1		# Lo uno con el resto
addi $s0, $s0, 1		# Incremento apuntador
addi $s2, $s2, -1		# Decremento contador
bnez $s2, rotarUnir		# Si no es cero continuo
li $s0, 0			# Inicializa acumulador
decToHex: beqz $s3, finConvers	# Si el numero se ha decrementado parar
addi $s3, $s3, -1		# Decremento el numero en decimal
addi $s0, $s0, 1		# Incremento su equivalente en hexadecimal
# Realizo ajuste del numero decimal decrementado para que sea una operacion en decimal
and $s1, $s3, 0xF
bne $s1, 0xF, decToHex
addi $s3, $s3, -6
and $s1, $s3, 0XF0
bne $s1, 0xF0, decToHex
addi $s3, $s3, -0x60
and $s1, $s3, 0XF00
bne $s1, 0xF00, decToHex
addi $s3, $s3, -0x600
j decToHex			# Continuo la operacion hasta parar
finConvers: move $v0, $s0	# Devuelvo el resultado
move $sp, $fp			# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $s0, -4($sp)			# Desempilo $s0 
lw $s1, -8($sp)			# Desempilo $s0 
lw $s2, -12($sp)		# Desempilo $s0 
lw $s3, -16($sp)		# Desempilo $s0 
lw $s4, -20($sp)		# Desempilo $s0 
lw $s5, -24($sp)		# Desempilo $s0 
lw $s6, -28($sp)		# Desempilo $s0 
jr $ra

# Rutina que limpia espacios de memoria
limpiar:
sw $fp, ($sp)			# Empila $fp
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -4		# Moviliza el $sp 8 posiciones hacia arriba
# Llena con cero todas las posiciones indicadas del espacio de menoria indicado
limpieza: sb $zero, ($a1)
addi $a1, $a1, 1
add $a2, $a2, -1
bnez $a2, limpieza
move $sp, $fp			# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
jr $ra

# Rutina que imprime mensajes por consola ante posibles errores que puedan ocurrir durante la ejecucion
error:
sw $fp, ($sp)			# Empila $fp
sw $s0, -4($sp)			# Empila $s0
move $fp, $sp			# Mueve a $fp el valor de $sp
addi $sp, $sp, -8		# Moviliza el $sp 8 posiciones hacia arriba
# Muestra mensaje de error de acuerdo al argumento suministrado a esta rutina:
li $v0, 4 		
move $s0, $a0
bne $s0, -1, opcion1
la $a0, error1	
j ejecucion
opcion1: bne $s0, -2, opcion2
la, $a0, error2	
j ejecucion
opcion2: bne $s0, -3, opcion3
la $a0, error3	
j ejecucion
opcion3: bne $s0, -4, opcion4 
la $a0, error4	
j ejecucion			
opcion4: bne $s0, -5, opcion5
la $a0, error5
j ejecucion
opcion5: bne $s0, -6, opcion6
la $a0, error6
j ejecucion
opcion6: bne $s0, -7, opcion7
la $a0, error7
j ejecucion
opcion7: bne $s0, -8, opcion8
la $a0, error8
j ejecucion
opcion8: bne $s0, -9, opcion9
la $a0, error9
j ejecucion
opcion9: bne $s0, -10, opcion10
la $a0, error10
j ejecucion
opcion10: bne $s0, -11, opcion11
la $a0, error11
j ejecucion
opcion11: bne $s0, -12, opcion12
la $a0, error0
ejecucion: syscall
opcion12: move $sp, $fp		# Restauro el valor del $sp 
lw $fp, ($sp)			# Desempilo $fp 
lw $s0, -4($sp)			# Desempilo $s0 
jr $ra				# Retorna al llamado

# Funcion que realiza la apertura de un archivo
# y lee cada linea para procesarla como un comando
procesar:
jr $ra

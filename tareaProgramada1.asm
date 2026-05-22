%macro imprimir 2
	push rax
	push rcx
	push rdi
	push rsi
	push rdx
	push r9
	push r10
	push r8
	mov rax,1
	mov rdi,1
	mov rsi,%1
	mov rdx,%2
	syscall
	pop r8
	pop r10
	pop r9
	pop rdx
	pop rsi
	pop rdi
	pop rcx
	pop rax
%endmacro

section .data
	msgError db "hubo un error al leer",0xA
	msgInvalidCommand db "Comando invalido",0xA
	file db "borrar.txt",0
	digits db "0123456789ABCDEF", 0xA
	msgRow db "Ingrese el numero de linea: "
	msgText db "Ingrese el texto: "
	msgInvalidRow db "Numero de fila invalido",0xA
	nombre db "hola.txt",0

section .bss
	fileName resb 50 
	input resb 50
	fileDescriptor resb 5
	fileContent resb 4096
	newFileContent resb 8162
	contentNumberLines resb 10000	
	borrar resb 2
	itoaVariable resb 8
	countDigits resb 4
	rowNumberInput resb 5
	totalRows resb 5
	inputText resb 4096
	
section .text
	global _start
	
;===================================================================================
; Subrutina ITOA - Inicio
;===================================================================================
itoa:					;Inicialización del itoa para el editor 
	push rcx			;Se almacena el contador en la pila
	mov rcx,8			
	mov byte[itoaVariable+rcx],0	;Se pone un 0 para delimitar el final
	dec rcx
	mov byte[itoaVariable+rcx],"."	;El punto permite diferenciar el numero de linea con el texto
	dec rcx
	jmp startItoa
	
itoaHexa:				;Inicialización del itoa para visualizador hexadecimal
	push rcx
	mov rcx,7
	mov byte[itoaVariable+rcx],0
	dec rcx
startItoa:
	xor rdx,rdx			;se reinicia rdx
	mov rbx,r12		
	div rbx				;se divide por la base indicada
	cmp rax,0			;si el resultado de la division es 0 se agrega el ultimo numero y acaba
	je finalizeItoa
	
	mov bl,byte[digits+rdx]		;se guarda en bl el numero conseguido con digitos mas el residuo de la division
	mov byte[itoaVariable+rcx],bl		;se guarda en la misma posicion en la variable resultado
	dec rcx				;se reduce rcx y repite
	jmp startItoa

finalizeItoa:
	mov bl,byte[digits+rdx]
	mov byte[itoaVariable+rcx],bl
	mov r11,rcx			;rcx permite saber cuantos bytes fueron guardados en la variable
	pop rcx				;Se recupera el contador almacenado en la pila
	ret

;===================================================================================
; Subrutina ITOA - Fin
;===================================================================================	


;===================================================================================
; Subrutina ATOI - Inicio
;===================================================================================
	
atoi:
	mov bl,byte[r10+rcx]
	cmp bl,0xA
	je fin_atoi
	sub rbx, 30h	;A rbx se le resta 30h para obtener el resultado decimal
	inc rcx
	mov rdx,10
	mul rdx		;el numero se guarda en eax y se le multiplica 10
	add rax,rbx	;se le suma a ese el dato conseguido en rbx
	xor rbx,rbx
	xor rdx,rdx
	jmp atoi	;se reinicia 

fin_atoi:
	ret

;===================================================================================
; Subrutina ATOI - Fin
;===================================================================================

;===================================================================================
; Subrutina restartItoaVariable - Inicio
;===================================================================================

restartItoaVariable:
	push rcx
	xor rcx,rcx

restartCycleItoa:
	mov byte[itoaVariable+rcx],0
	inc rcx
	cmp rcx,8
	je finRestartItoa
	jmp restartCycleItoa
	
	
finRestartItoa:
	pop rcx
	ret
	
;===================================================================================
; Subrutina restartItoaVariable - Fin
;===================================================================================

;===================================================================================
; Subrutina restartInput - Inicio
;===================================================================================

restartInput:
	push rcx
	xor rcx,rcx

restartCycleInput:
	mov byte[input+rcx],0
	inc rcx
	cmp rcx,50
	je finRestart
	jmp restartCycleInput
	
	
finRestart:
	pop rcx
	ret
	
;===================================================================================
; Subrutina restartInput - Fin
;===================================================================================
	
;===================================================================================
; Subrutina addLines - Inicio
;===================================================================================

addLines:
	dec r10
	
addLinesCycle:
	cmp r9,rbx
	je finAddLines
	mov byte[newFileContent+r10],0xA
	inc r10
	inc r9
	mov al,0xA
	jmp addLinesCycle
	
finAddLines:
	jmp searchLine
	
;===================================================================================
; Subrutina addLines - Fin
;===================================================================================


;============================	
;print - inicio
;============================	

print:
	mov rax,1
	mov rdi,1
	syscall
	ret

;============================	
;print - final
;============================
		
	
	

	
;============================	
;error - inicio
;============================	

error:
	mov rsi,msgError
	mov rdx,35
	call print
	jmp terminateProgram
	
;============================
;error - final
;============================	


;============================	
;commandError - inicio
;============================	

commandError:
	mov rsi,msgInvalidCommand
	mov rdx,17
	call print
	
	call restartInput
	jmp _start
	
;============================
;error - final
;============================	
	
	
invalidRow:					;Si el numero de fila es invalido
	mov rsi,msgInvalidRow
	mov rdx,24
	call print

	jmp terminateProgram

_start:
	mov rax,0				;Se pide el nombre del archivo por consola
	mov rdi,0
	mov rsi,input
	mov rdx,50
	syscall
	xor rcx,rcx

deleteEndLine:			;Recorre el nombre del archivo para eliminar el salto de linea al final de este
	mov al, byte[input+rcx]	
	mov byte[fileName+rcx],al		;en fileName se guarda el nombre del archivo
	
	cmp al, 10
	je finDeleteEndLine
	cmp al, 32
	je finDeleteEndLine
	
	inc rcx
	jmp deleteEndLine

finDeleteEndLine:
	push rcx
	mov byte [fileName+rcx],0
	
	mov rax,2		;open
	mov rdi,fileName
	mov rsi,66
	;mov rdx,0777o
	syscall
	
	mov [fileDescriptor],rax		;Se almacena el file descriptor
	
	cmp rax,0				;Se valida si hay error
	je error
	
	mov rax, 0		;read		;Se almacena el texto en la variable fileContent
	mov rdi,[fileDescriptor]	
	mov rsi,fileContent
	mov rdx,4096
	syscall
	
;;;;;;;;;;;;;;;;;;
checkHexadecimalVisualizer:			;Si luego del nombre del archivo hay un -h salta al visualizador hexadecimal
	pop rcx
	inc rcx
	xor rax,rax
	mov ax,word[input+rcx]
	
	xor rcx,rcx
	cmp ax,0				;Si no hay nada luego del nombre del archivo salta al visualizador y editor decimal
	je decimalVisualizer
	cmp ax,"-h"
	je hexaVisualizer
	jmp commandError			;Si hay algo luego del nombre del archivo que no es "-h" es un comando invalido


hexaVisualizer:
	mov al,[fileContent+rcx]		;rcx indice del texto de entrada
	inc rcx					;r10 indice de la variable del texto en hexadecimal
	
	cmp al,0
	je finalHexaVisualizer			;Final del texto
	
	mov r12,16				;La base numerica
	call restartItoaVariable
	call itoaHexa

	mov al,byte[itoaVariable+5]		;primer caracter en hexadecimal

	cmp al,0				;si es 0 significa que el valor hexadecimal es de un solo caracter
	je nextByte				;se pasa al siguiente byte (el menos significativo)
	
	mov byte[newFileContent+r10],al		;se copia a el byte mas significativo a la nueva variable
	inc r10
	
nextByte:
	mov al,byte[itoaVariable+6]
	mov byte[newFileContent+r10],al
	inc r10
	jmp hexaVisualizer

;;;;;;;;;;;;;;;;;;	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;IMPRIMIR EL TEXTO CON NUMEROS DE LINEAS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
decimalVisualizer:
	mov r8, 2 				;Número de línea del editor
	
	mov word[contentNumberLines],"1."	;Se guarda el primer numero de linea
	mov r9,2				;Indice de nueva variable de texto

setRowsNumber:
	mov al,byte[fileContent+rcx]		;rcx es el indice del texto leido
	mov byte[contentNumberLines+r9],al
	
	inc rcx
	inc r9

	cmp al,0				;Final del texto
	je finalRowsNumber
	cmp al,10				;Final de linea
	je setRowNumber

	jmp setRowsNumber			;Si es cualquier otro caracter se repite el proceso
	

setRowNumber:
	mov rax,r8				;Se inicializan los datos para el itoa
	xor r11,r11
	mov r12,10
	call itoa				;Se guarda el numero de linea en ascii con el punto delimitador ej ("13.")
	call iterateRowNumber			;Se itera sobre la variable para almacenar sus bytes en el nuevo texto
	
	 
	inc r8					;Se incrementa el numero de linea
	jmp setRowsNumber			;Se vuelve al ciclo
	
iterateRowNumber:
	mov al,byte[itoaVariable+r11]		;r11 almacena el indice de itoaVariable
	mov byte[contentNumberLines+r9],al	
	
	
	inc r9
	
	cmp al,0
	je endSetRowNumber
	inc r11
	jmp iterateRowNumber
endSetRowNumber:
	ret

finalRowsNumber:
	mov byte[contentNumberLines+r9],0	;Este ciclo elimina un numero de linea incorrecto al final del texto	
	dec r9
	mov al,[contentNumberLines+r9]
	cmp al,10
	jne finalRowsNumber
	dec r9
	
	mov rsi,contentNumberLines
	mov rdx,10000
	call print
	
	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;FINAL IMPRIMIR TEXTO CON NUMERO DE LINEA;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	
	
	mov r9,0 		;Va a almacenar el total de lineas
	xor rcx,rcx	;Indice
rowCounter:
	mov al,[fileContent+rcx]
	cmp al,0
	je finalCounter
	inc rcx
	cmp al,10
	jne rowCounter
	inc r9
	jmp rowCounter

finalCounter:
	inc r9
	mov [totalRows],r9
	
	
	mov rsi,msgRow			;mensaje ingresar linea
	mov rdx,28
	;call print
		
	mov rax,0			;ingresar linea en consola
	mov rdi,0
	mov rsi,rowNumberInput
	mov rdx,5
	syscall
	
	xor rcx,rcx
	xor rax,rax
	mov r10,rowNumberInput
	call atoi
	xor r10,r10
	
	mov rbx,rax
		
		
	cmp rbx,[totalRows]
	;ja invalidRow
	cmp byte[totalRows],0
	jbe invalidRow
	
	mov rsi,msgText
	mov rdx,18
	call print
	
	mov rax,0
	mov rdi,0
	mov rsi,inputText
	mov rdx,4096
	syscall
	
	
	xor rcx,rcx
	mov r9,1		;Contador de líneas
	xor r10,r10		;r10 indice variable nueva
	xor r11,r11		;r11 indice inputText
	mov al,1		;Evitar que se salte al final en primera iteracion inicio
searchLine:
	cmp al,0
	je finalEditor
	cmp r9,rbx 		;rbx contiene la fila ingresada por el usuario y r9 la fila actual
	je replaceLine
	mov al,[fileContent+rcx]
	mov [newFileContent+r10],al
	
	inc rcx
	inc r10
	
	cmp al,10
	je incrementCounter2
	
	jmp searchLine

incrementCounter2:
	inc r9
	jmp searchLine

replaceLine:
	mov r9,4097
	;imprimir inputText,10
	mov al,[inputText+r11]
	mov [newFileContent+r10],al
	
	cmp al,10
	je passWord
	inc r10 
	inc r11
	jmp replaceLine

passWord:			;El contador de la variable del texto viejo debe ignorar la linea que fue modificada
	mov al,[fileContent+rcx]
	cmp al,10
	je searchLine
	cmp al,0
	je searchLine
	inc rcx
	jmp passWord

decrement:	
	xor rax,rax
	dec r10

finalEditor:
	cmp al,10
	je decrement	
	
	cmp r9,rbx
	jb addLines
	
	mov rax,3		;Close file
	mov rdi,[fileDescriptor]
	syscall 

	imprimir newFileContent,8162
	
	mov eax,10
	mov ebx,fileName
	int 80h
	
	mov rax,2		;open
	mov rdi,fileName
	mov rsi,66
	mov rdx,0777o
	syscall
	
	mov [fileDescriptor],rax
	
	mov rdi,[fileDescriptor]
	mov rax,1
	mov rsi,newFileContent
	sub r10,1			;Se ajusta el tamaño de newFileContent

	;mov byte[newFileContent+r10],0
	
	mov rdx,r10
	syscall
	
	mov rax,3
	mov rdi,[fileDescriptor]
	syscall
	
	jmp terminateProgram
	
finalHexaVisualizer:
	mov rax,3		;Cerrar archivo
	mov rdi,[fileDescriptor]
	syscall 
	
	mov rsi,newFileContent  ;Se imprime el texto en hexadecimal
	mov rdx,8162
	call print
	
	
terminateProgram:
	
	mov rdi,0
	mov rax,60
	syscall

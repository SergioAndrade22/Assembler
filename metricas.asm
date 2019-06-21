SYS_EXIT equ 1
SYS_READ equ 3
SYS_WRITE equ 4
SYS_OPEN equ 5
SYS_CLOSE equ 6

STDIN equ 0
STDOU equ 1

global _start

section .data

	ayuda dw 0xA, 0xD, "---", 0xA, "Este programa se encarga de contar la cantidad de letras, palabras, lineas y parrafos de un archivo de texto. ", 0xA, "El programa posee la siguiente sintaxis para ser llamado: ", 0xA, "metricas [-h] o bien, metricas [archivo_entrada] [archivo_salida] ", 0xA, "Con -h se llama a esta ayuda en pantalla, luego de la cuál finaliza la ejecución del programa. ", 0xA, "Donde archivo_entrada debe ser un archivo de texto previamente creado, sobre el cuál se realizarán las mediciones. ", 0xA, "Donde archivo_salida es un parámetro opcional que puede ser un archivo de texto previamente creado. ", 0xA, "Finalmente es posible llamar a metricas, sin especificar parámetros, en cuyo caso espera entrada por consola y para finalizar el input se debe presionar ctrl + D una sola vez si el último caracter fue un ENTER, o dos veces en caso contrario.", 0xA, "---", 0xA, 0xD 	; mensaje de ayuda
	longitudAyuda equ $-ayuda 	; Longitud de "ayuda"

	display dw 0xA, 0xD, "Ingrese el texto que desea analizar:", 0xA, 0xD	; Display para decirle al usuario que ingrese por consola
	longitudDisplay equ $-display						;longitud del texto
	
	exit0 dw 0xA, 0xD, "---", 0xA, "El programa termino su ejecucion sin errores. ", 0xA, "---", 0xA, 0xD	; Mensaje ejecucion sin error
	longitudExit0 equ $-exit0										; Longitud del mensaje

	exit1 dw 0xA, 0xD, "---", 0xA, "Se produjo un error en el parametro de entrada. ", 0xA, "---", 0xA, 0xD	; Mensaje de eror 1
	longitudExit1 equ $-exit1 										; Longitud del mensaje

	exit2 dw 0xA, 0xD, "---", 0xA, "Se produjo un error en el parametro de salida. ", 0xA, "---", 0xA, 0xD	; Mensaje de error 2
	longitudExit2 equ $-exit2 										; Longitud del mensaje

	exit3 dw 0xA, 0xD, "---", 0xA, "Debe ingresar un parametro valido para ejecutar el programa, ", 0xA, "use -h si necesita ayuda. ", 0xA, "---", 0xA, 0xD	; Mensaje de error 3
	longitudExit3 equ $-exit3 																; Longitud del mensaje
	
	letras dd 0	; contador para las letras
	palabras dd 0	; contador para las palabras
	lineas dd 0	; contador para las lineas
	parrafos dd 0	; contador para los parrafos

section .bss	

	buffer resb 1		; Buffer de 32 bites
	source resw 1		; File handler de entrada
	dest resw 1		; File handler de salida
	
section .text

_start: 			; Comienzo del procedimiento
	
	pop eax			; argc

	cmp eax, 1		; No ingresaron parámetros? Debo leer de consola
	je leoCons		; Vamos a leer de consola
	
	cmp eax, 2 		; Tengo 1 parametro? (puede ser -h o nombre_archivo)
	je paramUnico		; Como tengo un parametro, salto a la marca de parametro único
	
	cmp eax, 3 		; Tengo 2 parametros? (DEBE ser nombre_archivo y archivo_salida)
	je paramDoble		; Como tengo 2 parametros, salto a la marca de parametros dobles
	
	jmp errParams 		; Me pasaron mal los parametros, debo tirar error

leoCons:			; Marca para leer desde consola

	mov esi, STDIN		; muevo a esi el codigo del stdin
	mov [source], esi	; mi fuente de lectura será la consola

	mov eax, SYS_WRITE	; codigo de la llamada al sistema
	mov ebx, STDOU		; codigo para escribir por consola
	mov ecx, display	; mensaje a escribir
	mov edx, longitudDisplay; tamaño a escribir
	int 80h

inicio:				; etiqueta de incia de lectura

	mov eax, SYS_READ	; codigo de la llamada al sistema
	mov ebx, [source]	; codigo para leer por consola
	mov ecx, buffer		; lugar a almacenar el digito
	mov edx, 1		; voy a leer un byte
	int 80h	

	cmp eax, byte 00h	; comparo preguntando por EOF
	je end			; salto a la marca de finalizacion

	cmp [buffer], byte 0Ah	; comparo preguntando por Enter
	je inicio		; vuelvo a comenzar buscando algún caracter 

	; simulo if ( c > 65 && c < 90) para verificar si me encuentro con una letra mayúscula

	cmp [buffer], byte 'A'	; comparo con 'A' 
	jl intermedio		; jl, compara preguntando por menor, si lo es, es un separador

	cmp [buffer], byte 'Z'	; comparo con 'Z'  
	jl iniPalabra		; si es menor q 90 y mayor q 65, del calculo anterior, estoy en presencia de una letra mayúscula

	; simulo else if ( c > 97 && c < 122)

	cmp [buffer], byte 'a'	; comparo con 'a'
	jl intermedio		; estoy en el caso de un separador

	cmp [buffer], byte 'z'	; comparo con 'z'
	jl iniPalabra		; si es mayor q 97, caso anterior, y menor q 122, estoy en el caso de una letra minúscula

	; equivaldría a un else

	jmp intermedio		; como no encontré una letra solo resta que sea un separador

iniPalabra:

	mov eax, [letras]	; muevo a eax el contador de letras
	inc eax			; aumento el contador en 1
	mov [letras], eax	; muevo a letras el nuevo valor

	mov eax, [palabras]	; muevo a eax el contador de palabras
	inc eax			; aumento el contador en 1
	mov [palabras], eax	; muevo a palabras el nuevo valor

	mov eax, SYS_READ	; codigo de la llamada al sistema
	mov ebx, [source]	; codigo para leer por consola
	mov ecx, buffer		; lugar a almacenar el digito
	mov edx, 1		; voy a leer un byte
	int 80h	

	cmp eax, byte 00h	; comparo preguntando por EOF
	je end			; salto a la marca de finalizacion

	cmp [buffer], byte 0Ah	; comparo preguntando por Enter
	je nuevoParrafo		; vuelvo a comenzar buscando algún caracter 

	; simulo if ( c > 65 && c < 90) para verificar si me encuentro con una letra mayúscula

	cmp [buffer], byte 'A'	; comparo con 'A' 
	jl idle			; jl, compara preguntando por menor, si lo es, es un separador

	cmp [buffer], byte 'Z'	; comparo con 'Z'  
	jl enPalabra		; si es menor q 90 y mayor q 65, del calculo anterior, estoy en presencia de una letra mayúscula

	; simulo else if ( c > 97 && c < 122)

	cmp [buffer], byte 'a'	; comparo con 'a'
	jl idle			; estoy en el caso de un separador

	cmp [buffer], byte 'z'	; comparo con 'z'
	jl enPalabra		; si es mayor q 97, caso anterior, y menor q 122, estoy en el caso de una letra minúscula

	; equivaldría a un else

	jmp idle		; como no encontré una letra, ni un EOF, ni tampoco un salto de linea solo resta que sea un separador
	
enPalabra:

	mov eax, [letras]	; muevo a eax el contador de letras
	inc eax			; aumento el contador en 1
	mov [letras], eax

	mov eax, SYS_READ	; codigo de la llamada al sistema
	mov ebx, [source]	; codigo para leer por consola
	mov ecx, buffer		; lugar a almacenar el digito
	mov edx, 1		; voy a leer un byte
	int 80h	

	cmp eax, byte 00h	; comparo preguntando por EOF
	je end			; salto a la marca de finalizacion

	cmp [buffer], byte 0Ah	; comparo preguntando por Enter
	je nuevoParrafo		; vuelvo a comenzar buscando algún caracter 

	; simulo if ( c > 65 && c < 90) para verificar si me encuentro con una letra mayúscula

	cmp [buffer], byte 'A'	; comparo con 'A' 
	jl idle			; jl, compara preguntando por menor, si lo es, es un separador

	cmp [buffer], byte 'Z'	; comparo con 'Z'  
	jl enPalabra		; si es menor q 90 y mayor q 65, del calculo anterior, estoy en presencia de una letra mayúscula

	; simulo else if ( c > 97 && c < 122)

	cmp [buffer], byte 'a'	; comparo con 'a'
	jl idle			; estoy en el caso de un separador

	cmp [buffer], byte 'z'	; comparo con 'z'
	jl enPalabra		; si es mayor q 97, caso anterior, y menor q 122, estoy en el caso de una letra minúscula

	; equivaldría a un else

	jmp idle		; como no encontré una letra, ni un EOF, ni tampoco un salto de linea solo resta que sea un separador

idle:

	mov eax, SYS_READ	; codigo de la llamada al sistema
	mov ebx, [source]	; codigo para leer por consola
	mov ecx, buffer		; lugar a almacenar el digito
	mov edx, 1		; voy a leer un byte
	int 80h	

	cmp eax, byte 00h	; comparo preguntando por EOF
	je end			; salto a la marca de finalizacion

	cmp [buffer], byte 0Ah	; comparo preguntando por Enter
	je nuevoParrafo		; vuelvo a comenzar buscando algún caracter 

	; simulo if ( c > 65 && c < 90) para verificar si me encuentro con una letra mayúscula

	cmp [buffer], byte 'A'	; comparo con 'A' 
	jl idle			; jl, compara preguntando por menor, si lo es, es un separador

	cmp [buffer], byte 'Z'	; comparo con 'Z'  
	jl iniPalabra		; si es menor q 90 y mayor q 65, del calculo anterior, estoy en presencia de una letra mayúscula

	; simulo else if ( c > 97 && c < 122)

	cmp [buffer], byte 'a'	; comparo con 'a'
	jl idle			; estoy en el caso de un separador

	cmp [buffer], byte 'z'	; comparo con 'z'
	jl iniPalabra		; si es mayor q 97, caso anterior, y menor q 122, estoy en el caso de una letra minúscula

	; equivaldría a un else

	jmp idle		; como no encontré una letra, ni un EOF, ni tampoco un salto de linea solo resta que sea un separador

nuevoParrafo:

	mov eax, [lineas]	; muevo a eax el contador de parrafos
	inc eax			; aumento el contador en 1
	mov [lineas], eax

	mov eax, [parrafos]	; muevo a eax el contador de parrafos
	inc eax			; aumento el contador en 1
	mov [parrafos], eax

	mov eax, SYS_READ	; codigo de la llamada al sistema
	mov ebx, [source]	; codigo para leer por consola
	mov ecx, buffer		; lugar a almacenar el digito
	mov edx, 1		; voy a leer un byte
	int 80h	

	cmp eax, byte 00h	; comparo preguntando por EOF
	je end			; salto a la marca de finalizacion

	cmp [buffer], byte 0Ah	; comparo preguntando por Enter
	je inicio		; vuelvo a comenzar buscando algún caracter 

	; simulo if ( c > 65 && c < 90) para verificar si me encuentro con una letra mayúscula

	cmp [buffer], byte 'A'	; comparo con 'A' 
	jl intermedio		; jl, compara preguntando por menor, si lo es, es un separador

	cmp [buffer], byte 'Z'	; comparo con 'Z'  
	jl iniPalabra		; si es menor q 90 y mayor q 65, del calculo anterior, estoy en presencia de una letra mayúscula

	; simulo else if ( c > 97 && c < 122)

	cmp [buffer], byte 'a'	; comparo con 'a'
	jl intermedio		; estoy en el caso de un separador

	cmp [buffer], byte 'z'	; comparo con 'z'
	jl iniPalabra		; si es mayor q 97, caso anterior, y menor q 122, estoy en el caso de una letra minúscula

	; equivaldría a un else

	jmp idle		; como no encontré una letra, ni un EOF, ni tampoco un salto de linea solo resta que sea un separador

intermedio:

	mov eax, SYS_READ	; codigo de la llamada al sistema
	mov ebx, [source]	; codigo para leer por consola
	mov ecx, buffer		; lugar a almacenar el digito
	mov edx, 1		; voy a leer un byte
	int 80h	

	cmp eax, byte 00h	; comparo preguntando por EOF
	je end			; salto a la marca de finalizacion

	cmp [buffer], byte 0Ah	; comparo preguntando por Enter
	je nuevaLinea		; vuelvo a comenzar buscando algún caracter 

	; simulo if ( c > 65 && c < 90) para verificar si me encuentro con una letra mayúscula

	cmp [buffer], byte 'A'	; comparo con 'A' 
	jl intermedio		; jl, compara preguntando por menor, si lo es, es un separador

	cmp [buffer], byte 'Z'	; comparo con 'Z'  
	jl iniPalabra		; si es menor q 90 y mayor q 65, del calculo anterior, estoy en presencia de una letra mayúscula

	; simulo else if ( c > 97 && c < 122)

	cmp [buffer], byte 'a'	; comparo con 'a'
	jl intermedio		; estoy en el caso de un separador

	cmp [buffer], byte 'z'	; comparo con 'z'
	jl iniPalabra		; si es mayor q 97, caso anterior, y menor q 122, estoy en el caso de una letra minúscula

	; equivaldría a un else

	jmp intermedio		; como no encontré una letra, ni un EOF, ni tampoco un salto de linea solo resta que sea un separador

nuevaLinea:

	mov eax, [lineas]	; muevo a eax el contador de palabras
	inc eax			; aumento eax en 1
	mov [lineas], eax

	mov eax, SYS_READ	; codigo de la llamada al sistema
	mov ebx, [source]	; codigo para leer por consola
	mov ecx, buffer		; lugar a almacenar el digito
	mov edx, 1		; voy a leer un byte
	int 80h	

	cmp eax, byte 00h	; comparo preguntando por EOF
	je end			; salto a la marca de finalizacion

	cmp [buffer], byte 0Ah	; comparo preguntando por Enter
	je inicio		; vuelvo a comenzar buscando algún caracter 

	; simulo if ( c > 65 && c < 90) para verificar si me encuentro con una letra mayúscula

	cmp [buffer], byte 'A'	; comparo con 'A' 
	jl intermedio		; jl, compara preguntando por menor, si lo es, es un separador

	cmp [buffer], byte 'Z'	; comparo con 'Z'  
	jl iniPalabra		; si es menor q 90 y mayor q 65, del calculo anterior, estoy en presencia de una letra mayúscula

	; simulo else if ( c > 97 && c < 122)

	cmp [buffer], byte 'a'	; comparo con 'a'
	jl intermedio		; estoy en el caso de un separador

	cmp [buffer], byte 'z'	; comparo con 'z'
	jl iniPalabra		; si es mayor q 97, caso anterior, y menor q 122, estoy en el caso de una letra minúscula

	; equivaldría a un else

	jmp intermedio		; como no encontré una letra, ni un EOF, ni tampoco un salto de linea solo resta que sea un separador

paramUnico: 			; Marca que, sabiendo que hay un argumento en argc, determina que contiene argv y salta dependiendo de eso
	
	pop ebx			; descarto argv [0]
	pop ebx			; conservo argv [1]
	
	mov esi, [ebx + 0]	; guardo el primer caracter en esi
	mov [buffer], esi	; luego lo guardo en el buffer
	cmp [buffer], byte '-'	; verifico si tengo el '-'
	jne noAyuda		; si no es igual, sigo normalmente
	
	mov esi, [ebx + 1]	; guardo el segundo caracter en esi
	mov [buffer], esi	; luego lo guardo en el buffer
	cmp [buffer], byte 'h'	; verifico si tengo el 'h'
	jne entradaError	; si no es igual, mensaje de error
	
	mov esi, [ebx + 2]	; guardo el tercer caracter en esi
	mov [buffer], esi	; luego lo guardo en el buffer
	cmp [buffer], byte ''	; verifico si termino el nombre
	je msgHelp		; si se cumple todo esto (tengo '-h' como parametro), muestro el mensaje de ayuda
	
noAyuda: 			; Marca en la cual se entra si no obtengo -h como parametro de entrada
	
	mov eax, SYS_OPEN	; codigo de llamada al sistema
	mov ecx, 0		; flags
	mov edx, 0		; para solo lectura
	int 80h			; en ebx ya se encuentra el filepath
	
	cmp eax, 0		; verifico si el archivo se abrio correctamente
	jl entradaError		; si es menor a 0, se produjo un error y lo detecto

	mov [source], eax	; pongo en source el file descriptor del archivo de entrada
	
	call inicio		; comienzo a leer source
	
paramDoble: 			; etiqueta de dos argumentos en argc, obtiene los argumentos y comienza a trabajar
	
	pop ebx			; descarto argv [0]
	pop ebx			; conservo argv [1]
	mov [source], ebx	; guardo la direccion del archivo de entrada en source
	
	mov eax, SYS_OPEN	; codigo de la llamada al sistema
	mov ebx, [source]	; archivo origen
	mov ecx, 0		; flags
	mov edx, 0		; para solo lectura
	int 80h			

	cmp eax, 0		; verifico si el archivo se abrio correctamente
	jl entradaError		; si es menor a 0, se produjo un error y lo detecto
	
	mov [source], eax	; pongo en source el file descriptor del archivo de entrada

	pop ebx			; conservo argv [2]
	mov [dest], ebx		; guardo la direccion del archivo de salida en dest
	
	mov eax, SYS_OPEN	; codigo de la llamada al sistema
	mov ebx, [dest]		; archivo origen
	mov ecx, 0		; flags
	mov edx, 1		; solo escritura
	int 80h			
	
	cmp eax, 0		; verifico si el archivo se creo correctamente
	jl salidaError		; si es menor a 0, se produjo un error y lo detecto
	
	mov [dest], eax		; pongo en dest el file descriptor del archivo de salida

	call inicio		; comienzo a leer source
	
msgHelp: ; Marca que se encargará de mostrar la ayuda si argc = 2 y argv[1] = "-h"

	mov eax, SYS_WRITE	; sys_write
	mov ebx, STDOU		; stdout
	mov ecx, ayuda 		; mensaje de ayuda
	mov edx, longitudAyuda	; largo de ayuda
	int 80h			; llamada al SO
	
	jmp exit		; salgo del programa normalmente (sin errores)

end: 				; Marca que se encarga de escribir la cantidad de lineas totales
	
	mov eax, 0Ah		; guardo el salto de linea en eax temporalmente
	mov [buffer], eax	; guardo lo que contiene eax en el buffer para escribir
	
	mov eax, SYS_WRITE	; sys_write
	mov ebx, [dest]		; direccion del archivo de escritura
	mov ecx, buffer		; contenido a escribir (en este caso, un salto de linea)
	mov edx, 1		; escribo solamente 1 byte
	int 80h			; llamada al SO
	
	mov eax, [letras]	; pongo en eax el contador de letras
	xor edx, edx		; pongo 0 en edx (no importa lo que contenia edx)
	xor ebp, ebp		; pongo 0 en ebp para usarlo de contador
	
	call representarN	; voy a una etiqueta que me permita representar el contador

	call printSpace		; imprime un space
	
	mov eax, [palabras]	; pongo en eax el contador de palabras
	xor edx, edx		; pongo 0 en edx (no importa lo que contenia edx)
	xor ebp, ebp		; pongo 0 en ebp para usarlo de contador
	
	call representarN	; voy a una etiqueta que me permita representar el contador

	call printSpace		; imprime un space

	mov eax, [lineas]	; pongo en eax el contador de lineas
	xor edx, edx		; pongo 0 en edx (no importa lo que contenia edx)
	xor ebp, ebp		; pongo 0 en ebp para usarlo de contador
	
	call representarN	; voy a una etiqueta que me permita representar el contador

	call printSpace		; imprime un space
	
	mov eax, [parrafos]	; pongo en eax el contador de parrafos
	xor edx, edx		; pongo 0 en edx (no importa lo que contenia edx)
	xor ebp, ebp		; pongo 0 en ebp para usarlo de contador
	
	call representarN	; voy a una etiqueta que me permita representar el contador

	jmp exit		; voy a la etiqueta para finalizar
	
printSpace:			; marca que imprime un space
	
	mov [buffer], byte ' '	; muevo el espacio al buffer
	mov eax, SYS_WRITE	; sys_write
	mov ebx, [dest]		; direccion del archivo de escritura
	mov ecx, buffer		; contenido a escribir (en este caso, un salto de linea)
	mov edx, 1		; escribo solamente 1 byte
	int 80h			; llamada al SO

	ret			; devuelvo el flujo al lugar desde donde se realizo la llamada

representarN: 			; Marca que se encarga de tomar un numero de una longitud dada y representarlo correctamente
	
	mov ecx, 0Ah		; guardo el valor 10 en ecx
	div ecx			; divido eax por 10 y el resultado queda en eax y el resto en edx
	
	push edx		; guardo el resto en la pila
	inc ebp			; incremento el contador ebp
	
	xor edx, edx		; vuelvo a poner edx en 0
	
	cmp eax, 00h		; verifico si sigo con un numero mayor a 0
	jg representarN		; si es mayor a 0, entonces repito desde el principio representarN	
	
escribirN: 			; Marca que se encarga de escribir el numero de linea en pantalla
	
	pop edx			; saco un digito de la pila para representarlo
	dec ebp			; decremento el contador ebp
	
	mov eax, 48		; guardo 48 en eax
	add eax, edx		; sumo 48 + X para representarlo correctamente
	mov [buffer], eax	; guardo el resultado en el buffer
	
	mov eax, SYS_WRITE     	; sys_write
	mov ebx, [dest]    	; direccion al archivo de escritura
	mov ecx, buffer		; contenido a escribir (en este caso, el numero de linea actual)
	mov edx, 1      	; escribo un byte
	int 80h          	; llamada al SO
	
	cmp ebp, 00h		; verifico si ebp es mayor a 0
	jg escribirN		; si lo es, entonces aun quedan elementos de la pila por sacar

	ret			; termine de representar y vuelvo a la escritura normal

entradaError: 			; Marca que se encarga de tirar error si el archivo de entrada presenta errores
	
	mov eax, SYS_WRITE	; sys_write
	mov ebx, STDOU 		; stdout
	mov ecx, exit1 		; mensaje de ayuda al recibir este error
	mov edx, longitudExit1	; largo de exit1
	int 80h			; llamada al SO
	
	mov ebx, 1 		; terminacion anormal por error en el archivo de entrada
	jmp terminar		; salto a finalizar el programa

salidaError: 			; Marca que se encarga de tirar error si el archivo de salida presenta errores
	
	mov eax, SYS_WRITE	; sys_write
	mov ebx, STDOU		; stdout
	mov ecx, exit2	 	; mensaje de ayuda al recibir este error
	mov edx, longitudExit2	; largo de exit2
	int 80h			; llamada al SO
	
	mov ebx, 2		; terminacion anormal por error en el archivo de salida 
	jmp terminar		; salto a finalizar el programa

errParams: 			; Marca que tira error ya que hubo un error en la cantidad de parámetros de la entrada del programa
	
	mov eax, SYS_WRITE	; sys_write
	mov ebx, STDOU 		; stdout
	mov ecx, exit3	 	; mensaje de ayuda al recibir este error
	mov edx, longitudExit3	; largo de exit3
	int 80h			; llamada al SO
	
	mov ebx, 3		; terminacion anormal por otras causas
	jmp terminar		; salto a finalizar el programa
	
exit: 				; Marca que se encargara de enviar un mensaje de finalizacion sin problemas y de cerrar el programa
	
	mov eax, SYS_WRITE	; sys_write
	mov ebx, STDOU 		; stdout
	mov ecx, exit0	 	; mensaje de que todo salio correctamente
	mov edx, longitudExit0	; largo de exit0
	int 80h			; llamada al SO
	
	mov ebx, 0 		; no hubo errores
	
	cmp [source], byte STDIN	; reviso si hubo archivo de entrada
	je terminar			; si son iguales no hay archivo que cerrar

	mov eax, SYS_CLOSE	; sys_close
	mov ebx, [source]	; archivo de entrada
	int 80h			; llamada al SO
	
	cmp [dest], byte STDOU	; reviso si hubo archivo de salida
	je terminar		; si son iguales no hay archivo que cerrar

	mov eax, SYS_CLOSE	; sys_close
	mov ebx, [dest]		; archivo de salida
	int 80h			; llamada al SO

terminar:			; etiqueta que cierra el programa

	mov eax, 1 		; sys _exit
	int 80h    		; llamada al SO

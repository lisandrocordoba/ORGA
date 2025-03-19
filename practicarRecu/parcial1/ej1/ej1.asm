extern malloc

section .rodata
; Acá se pueden poner todas las máscaras y datos que necesiten para el ejercicio

section .text
; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - es_indice_ordenado
global EJERCICIO_1A_HECHO
EJERCICIO_1A_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - indice_a_inventario
global EJERCICIO_1B_HECHO
EJERCICIO_1B_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

;; La funcion debe verificar si una vista del inventario está correctamente 
;; ordenada de acuerdo a un criterio (comparador)

;; bool es_indice_ordenado(item_t** inventario, uint16_t* indice, uint16_t tamanio, comparador_t comparador);

;; Dónde:
;; - `inventario`: Un array de punteros a ítems que representa el inventario a
;;   procesar.
;; - `indice`: El arreglo de índices en el inventario que representa la vista.
;; - `tamanio`: El tamaño del inventario (y de la vista).
;; - `comparador`: La función de comparación que a utilizar para verificar el
;;   orden.
;; 
;; Tenga en consideración:
;; - `tamanio` es un valor de 16 bits. La parte alta del registro en dónde viene
;;   como parámetro podría tener basura.
;; - `comparador` es una dirección de memoria a la que se debe saltar (vía `jmp` o
;;   `call`) para comenzar la ejecución de la subrutina en cuestión.
;; - Los tamaños de los arrays `inventario` e `indice` son ambos `tamanio`.
;; - `false` es el valor `0` y `true` es todo valor distinto de `0`.
;; - Importa que los ítems estén ordenados según el comparador. No hay necesidad
;;   de verificar que el orden sea estable.

global es_indice_ordenado
es_indice_ordenado:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;

	; rdi -> item_t** inventario
	; rsi -> uint16_t* indice
	; dx -> uint16_t tamanio
	; rcx -> comparador_t comparador

	prologo:
		push rbp
		mov rbp, rsp

		push r12
		mov r12, rdi	; r12 = inventario

		push r13
		mov r13, rsi	; r13 = indice

		push r14
		xor r14, r14
		mov r14w, dx	; r14w = tamanio

		push r15
		mov r15, rcx	; r15 = comparador

		push rbx
		xor rbx, rbx	; rbx = i = 0


	sub r14, 1			; r14 = tamanio - 1
	while:
		cmp rbx, r14
		jge epilogo			; if(i >= tamanio - 1) {return}

		indices_vista_para_comparar:
		mov r9, rbx				; r9 = copia de i

		sal r9, 1				; r9 = iterador * 2
		xor r10, r10
		mov r10w, [r13 + r9]	; r10 = indice[i]

		add r9, 2				; r9 = (iterador+1) * 2
		xor r11, r11
		mov r11w, [r13 + r9]	; r11w = indice[i+1]


		items_vista_para_comparar:
		sal r10, 3				; r10 = indice[i] * 8
		mov rdi, [r12 + r10]	; rdi = inventario[indice[i]]

		sal r11, 3				; r11 = indice[i+1] * 8
		mov rsi, [r12 + r11]	; rsi = inventario[indice[i+1]]

		comparar:
		sub rsp, 8				; Alineo la pila
		call r15				; Call comparador(rdi, rsi)
		add rsp, 8

		cmp al, 0x0
		je no_esta_ordenado				; if(!ordenado) {return 0} 

		inc bx
		jmp while				; i++ y seguir el while

	no_esta_ordenado:
		mov rax, 0x0

	epilogo:
		pop rbx
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbp
		ret
















;------------------------------------------------------------------------------------------------


;; Dado un inventario y una vista, crear un nuevo inventario que mantenga el
;; orden descrito por la misma.

;; La memoria a solicitar para el nuevo inventario debe poder ser liberada
;; utilizando `free(ptr)`.

;; item_t** indice_a_inventario(item_t** inventario, uint16_t* indice, uint16_t tamanio);

;; Donde:
;; - `inventario` un array de punteros a ítems que representa el inventario a
;;   procesar.
;; - `indice` es el arreglo de índices en el inventario que representa la vista
;;   que vamos a usar para reorganizar el inventario.
;; - `tamanio` es el tamaño del inventario.
;; 
;; Tenga en consideración:
;; - Tanto los elementos de `inventario` como los del resultado son punteros a
;;   `ítems`. Se pide *copiar* estos punteros, **no se deben crear ni clonar
;;   ítems**



global indice_a_inventario
indice_a_inventario:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;

	; rdi -> item_t** inventario
	; rsi -> uint16_t* indice
	; dx -> uint16_t tamanio

	prologo2:
		push rbp
		mov rbp, rsp
		; Preservo los no volatiles en la pila
		push r12
		push r13
		push r14
		push rbx	; La pila queda alineada

	; Preservo los argumentos e iterador en no volatiles
	mov r12, rdi	; r12 = inventario
	mov r13, rsi	; r13 = indice
	xor r14, r14
	mov r14w, dx	; r14 = tamanio
	xor rbx,rbx		; rbx = i = 0

	; Pido memoria para el nuevo inventario
	mov rdi, r14	; rdi = tamanio
	sal rdi, 3		; rdi = tamanio * sizeof(item_t*) = tamanio * 8 (tamaño de puntero)
	call malloc		; rax = puntero a inventario_res

	; Recorro el invetario original y agrego al inventario_res los items reordenados 
	while2:
		; Accedo a indice[i]
		mov r8, rbx				; r8 = copia de i
		sal r8, 1 				; r8 = i * 2 (tamaño de uint16_t)
		xor r9, r9
		mov r9w, [r13 + r8]		; r9 = indice[i]
		
		; Accedo al inventario[indice[i]]
		sal r9, 3				; r9 = indice[i] * 8 (tamaño de puntero)
		mov r10, [r12 + r9]		; r10 = inventario[indice[i]]

		; Guardo el item en resultado[i]
		mov r8, rbx				; r8 = copia de i
		sal r8, 3				; r8 = i * 8 (tamaño de puntero)
		mov [rax + r8], r10		; resultado[i] = inventario[indice[i]]

		; Siguiente iteracion
		inc rbx
		cmp rbx, r14
		jl while2
	
	epilogo2: 
		pop rbx
		pop r14
		pop r13
		pop r12
		pop rbp
		ret
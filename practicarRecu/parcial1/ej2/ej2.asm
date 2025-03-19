section .rodata
; Acá se pueden poner todas las máscaras y datos que necesiten para el filtro
ALIGN 16
mask_limpiar_parte_alta_de_quadword dq 0x0000_0000_FFFF_FFFF
ALIGN 16
words_128 times 8 dw 128 
ALIGN 16
mask_pshufb_amount db 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF
ALIGN 16
coeficientes_alfa dw 0x0000, 0x0000, 0x0000, 0xFF00, 0x0000, 0x0000, 0x0000, 0xFF00
ALIGN 16
coeficientes_max0 times 8 dw 0
ALIGN 16
coeficientes_min255 times 8 dw 255

section .text

; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; Marca el ejercicio 2A como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - ej2a
global EJERCICIO_2A_HECHO
EJERCICIO_2A_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 2B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - ej2b
global EJERCICIO_2B_HECHO
EJERCICIO_2B_HECHO: db FALSE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 2C (opcional) como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - ej2c
global EJERCICIO_2C_HECHO
EJERCICIO_2C_HECHO: db FALSE ; Cambiar por `TRUE` para correr los tests.

; Dada una imagen origen ajusta su contraste de acuerdo a la parametrización
; provista.
;
; Parámetros:
;   - dst:    La imagen destino. Es RGBA (8 bits sin signo por canal).
;   - src:    La imagen origen. Es RGBA (8 bits sin signo por canal).
;   - width:  El ancho en píxeles de `dst`, `src` y `mask`.
;   - height: El alto en píxeles de `dst`, `src` y `mask`.
;   - amount: El nivel de intensidad a aplicar.
global ej2a
ej2a:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; rdi = rgba_t*  dst
	; rsi = rgba_t*  src
	; edx = uint32_t width
	; ecx = uint32_t height
	; r8b = uint8_t  amount
	
	epilogo:
		push rbp
		mov rbp, rsp

	and rdx, [mask_limpiar_parte_alta_de_quadword]
	and rcx, [mask_limpiar_parte_alta_de_quadword]
	imul rcx, rdx 					; rcx = width * height
	shr rcx, 2						; rcx = (width * height) / 4 = cantidad de pixeles / 4 = cantidad de iteraciones

	; Cargo las mascaras y coeficientes
	movdqa xmm15, [words_128]

	movq xmm14, r8						; xmm14 tiene en su byte menos significativo el amount, el resto puede ser basura
	pshufb xmm14, [mask_pshufb_amount]	; xmm14 = 00AM|00AM|00AM|00AM| // |00AM|00AM|00AM|00AM

	movdqa xmm13, [coeficientes_alfa]

	movdqa xmm12, [coeficientes_max0]

	movdqa xmm11, [coeficientes_min255]

	; COMENTO TODO Y SIGUE TIRANDO LA MISMA IMAGEN, QUE CHOTA LE PASA??????????????''''

	while:
		movdqu xmm1, [rsi]			; xmm1 = A4|B4|G4|R4 // A3|B3|G3|R3 // A2|B2|G2|R2 // A1|B1|G1|R1|
		pmovzxbw xmm2, xmm1			; xmm2 = AA22|BB22|GG22|RR22 // AA11|BB11|GG11|RR11

		psrldq xmm1, 8				; xmm1 = 00|00|00|00 // 00|00|00|00 // A4|B4|G4|R4 // A3|B3|G3|R3|
		pmovzxbw xmm3, xmm1			; xmm3 = AA44|BB44|GG44|RR44 // AA33|BB33|GG33|RR33

		psubw xmm2, xmm15			; xmm2 = xmm2 - 128 	(word a word)
		psubw xmm3, xmm15			; xmm3 = xmm3 - 128 	(word a word)

		pmullw xmm2, xmm14			; xmm2 = (xmm2 - 128)*amount 	(word a word)
		pmullw xmm3, xmm14			; xmm3 = (xmm3 - 128)*amount 	(word a word)

		psrlw xmm2, 32				; xmm2 = ((xmm2 - 128)*amount) / 32	 	(word a word)
		psrlw xmm3, 32				; xmm3 = ((xmm3 - 128)*amount) / 32 	(word a word)

		paddusw xmm2, xmm15			; xmm2 = 255, (((xmm2 - 128)*amount) / 32) + 128
		paddusw xmm3, xmm15			; xmm3 = 255, (((xmm3 - 128)*amount) / 32) + 128

		pmaxuw xmm2, xmm12
		pmaxuw xmm3, xmm12

		pminuw xmm2, xmm11
		pminuw xmm3, xmm11

		; Seteo los campos alfa en 255 
		pblendw xmm2, xmm13, 0b10001000	
		pblendw xmm2, xmm13, 0b10001000

		packuswb xmm2, xmm13		; Pongo los 4 pixeles en xmm2
		movdqa xmm2, [rdi]			; Escribo a dst los 4 pixeles procesados

		; Avanzamos 4 pixeles
		add rsi, 16
		add rdi, 16
		
		loop while					; Decrementa ecx, si es >0 vuelve al while

	prologo:
		pop rbp
		ret

; Dada una imagen origen ajusta su contraste de acuerdo a la parametrización
; provista.
;
; Parámetros:
;   - dst:    La imagen destino. Es RGBA (8 bits sin signo por canal).
;   - src:    La imagen origen. Es RGBA (8 bits sin signo por canal).
;   - width:  El ancho en píxeles de `dst`, `src` y `mask`.
;   - height: El alto en píxeles de `dst`, `src` y `mask`.
;   - amount: El nivel de intensidad a aplicar.
;   - mask:   Una máscara que regula por cada píxel si el filtro debe o no ser
;             aplicado. Los valores de esta máscara son siempre 0 o 255.
global ej2b
ej2b:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; r/m64 = rgba_t*  dst
	; r/m64 = rgba_t*  src
	; r/m32 = uint32_t width
	; r/m32 = uint32_t height
	; r/m8  = uint8_t  amount
	; r/m64 = uint8_t* mask

	ret

; [IMPLEMENTACIÓN OPCIONAL]
; El enunciado sólo solicita "la idea" de este ejercicio.
;
; Dada una imagen origen ajusta su contraste de acuerdo a la parametrización
; provista.
;
; Parámetros:
;   - dst:     La imagen destino. Es RGBA (8 bits sin signo por canal).
;   - src:     La imagen origen. Es RGBA (8 bits sin signo por canal).
;   - width:   El ancho en píxeles de `dst`, `src` y `mask`.
;   - height:  El alto en píxeles de `dst`, `src` y `mask`.
;   - control: Una imagen que que regula el nivel de intensidad del filtro en
;              cada píxel. Es en escala de grises a 8 bits por canal.
global ej2c
ej2c:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits o 8 bits.
	;
	; r/m64 = rgba_t*  dst
	; r/m64 = rgba_t*  src
	; r/m32 = uint32_t width
	; r/m32 = uint32_t height
	; r/m64 = uint8_t* control

	ret

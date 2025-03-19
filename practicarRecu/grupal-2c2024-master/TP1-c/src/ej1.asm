section .rodata
; Poner acá todas las máscaras y coeficientes que necesiten para el filtro
ALIGN 16
PSHUFB_DESARMAR_PIXELES db 0x0, 0x4, 0x8, 0xC, 0x1, 0x5, 0x9, 0xD, 0x2, 0x6, 0xA, 0xE, 0x3, 0x7, 0xB, 0xF
COEFICIENTES_ROJO times 4 dd 0.2126
COEFICIENTES_VERDE times 4 dd 0.7152
COEFICIENTES_AZUL times 4 dd 0.0722
PSHUFB_REARMAR_PIXELES db 0x0, 0x0, 0x0, 0x80, 0x1, 0x1, 0x1, 0x80, 0x2, 0x2, 0x2, 0x80, 0x3, 0x3, 0x3, 0x80
COEFICIENTES_ALFA times 4 db 0x0, 0x0, 0x0, 0xFF

section .text

; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; Marca el ejercicio 1 como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - ej1
global EJERCICIO_1_HECHO
EJERCICIO_1_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Convierte una imagen dada (`src`) a escala de grises y la escribe en el
; canvas proporcionado (`dst`).
;
; Para convertir un píxel a escala de grises alcanza con realizar el siguiente
; cálculo:
; ```
; luminosidad = 0.2126 * rojo + 0.7152 * verde + 0.0722 * azul 
; ```
;
; Como los píxeles de las imágenes son RGB entonces el píxel destino será
; ```
; rojo  = luminosidad
; verde = luminosidad
; azul  = luminosidad
; alfa  = 255
; ```
;
; Parámetros:
;   - dst:    La imagen destino. Está a color (RGBA) en 8 bits sin signo por
;             canal.
;   - src:    La imagen origen A. Está a color (RGBA) en 8 bits sin signo por
;             canal.
;   - width:  El ancho en píxeles de `src` y `dst`.
;   - height: El alto en píxeles de `src` y `dst`.
global ej1
ej1:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits.
	;
	; rdi = rgba_t*  dst
	; rsi = rgba_t*  src
	; edx = uint32_t width
	; ecx = uint32_t height
	prologo:
	push rbp
	mov rbp, rsp

	; calculo cantidad de pixeles
	xor r8, r8
	mov r8d, edx
	xor r9, r9
	mov r9d, ecx
	imul r8, r9		; r8 = width * height
	mov rcx, r8		
	sar rcx, 2		; ecx = (width * height) / 4 = cantidad de iteraciones, pues proceso de a 4 pixeles

	; guardo las mascaras/coeficientes en los registros
	movdqu xmm15, [PSHUFB_DESARMAR_PIXELES]
	movdqu xmm14, [COEFICIENTES_ROJO]
	movdqu xmm13, [COEFICIENTES_VERDE]
	movdqu xmm12, [COEFICIENTES_AZUL]
	movdqu xmm11, [PSHUFB_REARMAR_PIXELES]
	movdqu xmm10, [COEFICIENTES_ALFA]

	; ACLARACION: dibujo/escribo los registros de la forma xmm = mas significativo -> menos significativo
	while:
		movdqa xmm1, [rsi]		; xmm1 = A|B|G|R | A|B|G|R | A|B|G|R | A|B|G|R|A	
		pshufb xmm1, xmm15		; xmm1 = A|A|A|A | B|B|B|B | G|G|G|G | R|R|R|R
		movdqa xmm2, xmm1		; xmm2 = copia de xmm1
		movdqa xmm3, xmm1		; xmm3 = copia de xmm1
	
		; proceso el RED
		pmovzxbd xmm1, xmm1		; xmm1 = RRRR | RRRR | RRRR | RRRR
		;vcvtudq2ps xmm1, xmm1	; xmm1 = float(RRRR) | float(RRRR) | float(RRRR) | float(RRRR)
		cvtdq2ps xmm1, xmm1	; xmm1 = float(RRRR) | float(RRRR) | float(RRRR) | float(RRRR)

		mulps xmm1, xmm14		; xmm1 = float(RRRR)*0.2126 | float(RRRR)*0.2126 | float(RRRR)*0.2126 | float(RRRR)*0.2126 

		; proceso el GREEN
		psrld xmm2, 32			; xmm2 = 0|0|0|0 | A|A|A|A | B|B|B|B | G|G|G|G
		pmovzxbd xmm2, xmm2		; xmm2 = GGGG | GGGG | GGGG | GGGG
		;vcvtudq2ps xmm2, xmm2	; xmm2 = float(GGGG) | float(GGGG) | float(GGGG) | float(GGGG)
		cvtdq2ps xmm2, xmm2	; xmm2 = float(GGGG) | float(GGGG) | float(GGGG) | float(GGGG)
		mulps xmm2, xmm13		; xmm2 = float(GGGG)*0.7152 | float(GGGG)*0.7152 | float(GGGG)*0.7152 | float(GGGG)*0.7152 

		; proceso el BLUE
		psrld xmm3, 64			; xmm3 = 0|0|0|0 | 0|0|0|0 | A|A|A|A | B|B|B|B
		pmovzxbd xmm3, xmm3		; xmm3 = BBBB | BBBB | BBBB | BBBB
		;vcvtudq2ps xmm3, xmm3	; xmm3 = float(BBBB) | float(BBBB) | float(BBBB) | float(BBBB)
		cvtdq2ps xmm3, xmm3	; xmm3 = float(BBBB) | float(BBBB) | float(BBBB) | float(BBBB)
		mulps xmm3, xmm12		; xmm3 = float(BBBB)*0.0722 | float(BBBB)*0.0722 | float(BBBB)*0.0722 | float(BBBB)*0.0722 
		
		; calculo la luminosidad
		addps xmm1, xmm2		
		addps xmm1, xmm3		; xmm1 = L4 | L3 | L2 | L1

		; rearmo los pixeles
		;vcvtps2udq xmm1, xmm1	; xmm1 pasado de single floats a dwords
		cvttps2dq xmm1, xmm1	; xmm1 pasado de single floats a dwords
		;vpmovusdb xmm1, xmm1	; xmm1 = 0|0|0|0 | 0|0|0|0 | 0|0|0|0 | L4|L3|L2|L1		 NO SE PQ ESTA INSTRUCCION DE MIERDA ME TIRA ERROR
		; --------- ESTO LO TUVE Q PONER PARA ARRGLAR LA MIERDA DE vpmovusdb
		packusdw xmm1, xmm2		; xmm1 =  ??|??|??|?? | L4|L3|L2|L1
		packuswb xmm1, xmm2 	; xmm1 = 0|0|0|0 | 0|0|0|0 | 0|0|0|0 | L4|L3|L2|L1
		; ----------
		pshufb xmm1, xmm11		; xmm1 = 0|L4|L4|L4 | 0|L3|L3|L3 | 0|L2|L2|L2 | 0|L1|L1|L1
		pand xmm1, xmm10		; xmm1 = FF|L4|L4|L4 | FF|L3|L3|L3 | FF|L2|L2|L2 | FF|L1|L1|L1

		; escribo en destino
		movdqa [rdi], xmm1

		; siguiente iteracion
		add rdi, 16
		add rsi, 16
		loop while			

	epilogo:
	pop rbp


	ret


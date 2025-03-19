section .rodata
; Acá se pueden poner todas las máscaras y datos que necesiten para el filtro
ALIGN 16
mask_parte_baja64 dq 0x0000_0000_FFFF_FFFF

ALIGN 16
mask_shuffle_ammount db 0x00,0xFF,0xFF,0xFF,0x00,0xFF,0xFF,0xFF,0x00,0xFF,0xFF,0xFF,0x00,0xFF,0xFF,0xFF

ALIGN 16
mask_byte_mas_bajo db 0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00

ALIGN 16
mask_128 times 4 dd 128

ALIGN 16
mask_max0 times 4 dd 0

ALIGN 16
mask_min255 times 4 dd 255

ALIGN 16
mask_setear_alfa_en_255 db 0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF

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
EJERCICIO_2B_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Marca el ejercicio 2C (opcional) como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:mask_byte_mas_bajo db 0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00
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
	; r/m64 rdi = rgba_t*  dst
	; r/m64 rsi = rgba_t*  src
	; r/m32 rdx= uint32_t width
	; r/m32 rcx= uint32_t height
	; r/m8  r8 = uint8_t  amount
	push rbp
	mov rbp, rsp

	; cantidad total de pixeles
	xor rax, rax
	and rdx, [mask_parte_baja64]
	and rcx, [mask_parte_baja64]
	mov rax, rdx
	imul rax, rcx 					; rax = width * height

	movdqa xmm14, [mask_shuffle_ammount]
	movq xmm15, r8				;cargo r8 que tiene en su byte menos significativo el amount, con la mascara me quedo solo con ese byte pues el resto es basura.
	pshufb xmm15, xmm14			; cargo en xmm15 000A | 000A | 000A | 000A

	movdqa xmm8, [mask_max0]
	movdqa xmm7, [mask_min255]
	movdqa xmm6, [mask_setear_alfa_en_255]
	movdqa xmm13, [mask_128]			; mascara para restar 128

while:
	movdqu xmm1, [rsi]	; cargo 4 pixeles
	movdqu xmm2, xmm1
	movdqu xmm3, xmm1   ;copias de los pixeles originales
	movdqu xmm4, xmm1

	psrld xmm3, 8         ; pongo el green en el byte menos significativo  
    psrld xmm4, 16         ; el azul en el byte menos significativo
	;xmm2 para rojos, xmm3 para ver, xmm4 para azules

	pand xmm2, [mask_byte_mas_bajo]    ; me quedo solo con el Rojo     0 0 0 R
    pand xmm3, [mask_byte_mas_bajo]    ; me quedo solo con el verde    0 0 0 G
    pand xmm4, [mask_byte_mas_bajo]    ; me quedo solo con el AZUL     0 0 0 B


	;armo el valor rojo de 4 pixeles
	psubd xmm2, xmm13		; ROJO - 128
	pmulld xmm2, xmm15		; (ROJO - 128 ) * contraste
	psrad xmm2, 5			; shifteo 5 bits para dividir por 32
	paddd xmm2, xmm13		; al resultado, le sumo 128
	pmaxsd xmm2, xmm8			; max(0 ,resultado total de la cuenta)	
	pminsd xmm2, xmm7			; min(255, resultado total de la cuenta)		
	;de esta forma me queda en xmm2 el valor correcto, sea x,0 o 255		000 R | 000 R | 000 R | 000 R

	;armo el valor VERDE de 4 pixeles
	psubd xmm3, xmm13		; VERDE - 128
	pmulld xmm3, xmm15		; (VERDE - 128 ) * contraste
	psrad xmm3, 5			; shifteo 5 bits para dividir por 32
	paddd xmm3, xmm13		; al resultado, le sumo 128
	pmaxsd xmm3, xmm8			; max(0 ,resultado total de la cuenta)	
	pminsd xmm3, xmm7			; min(255, resultado total de la cuenta)		
	;de esta forma me queda en xmm3 el valor correcto, sea x,0 o 255		000 G | 000 G | 000 G | 000 G

	;armo el valor AZUL de 4 pixeles
	psubd xmm4, xmm13		; AZUL - 128
	pmulld xmm4, xmm15		; (AZUL - 128 ) * contraste
	psrad xmm4, 5			; shifteo 5 bits para dividir por 32
	paddd xmm4, xmm13		; al resultado, le sumo 128
	pmaxsd xmm4, xmm8			; max(0 ,resultado total de la cuenta)	
	pminsd xmm4, xmm7			; min(255, resultado total de la cuenta)		
	;de esta forma me queda en xmm4 el valor correcto, sea x,0 o 255		000 B | 000 B | 000 B | 000 B

	;shifteo el azul y el verde para que queden alineados y luego poder hacer el por
	;en xmm2 esta el color rojo correspondiente ya alineado
	pslld xmm3, 8     ; 000G ----> 0 0 G 0 | ....
	pslld xmm4, 16     ; 000B ----> 0 B 0 0 | ....

	;empaqueto los resultados obtenidos en un xmm para luego ponerlo en dst

	por xmm2, xmm3		; R Y G ----->  00GR | 00GR | 00GR | 00GR
	por xmm2, xmm4		; R G y B ----> 0BGR | 0BGR | 0BGR | 0BGR
	por xmm2, xmm6		; agrego el Alfa en 255  ---> ABGR | ABGR | ABGR | ABGR

	;escribo los 4 pixeles en destinoFALSE
	movdqa [rdi], xmm2

	add rsi, 16				; avanzamos src en 4 pixeles
	add rdi, 16				; avanzamos dst en 4 pixeles
	sub rax, 4				; disminuimos en 4 los pixeles restantes
	cmp rax, 0				
	jg while

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
	; r/m64 rdi = rgba_t*  dst
	; r/m64 rsi = rgba_t*  src
	; r/m32 rdx = uint32_t width
	; r/m32 rcx = uint32_t height
	; r/m8  r8 = uint8_t  amount
	; r/m64 r9 = uint8_t* mask
	push rbp
	mov rbp, rsp

	; cantidad total de pixeles
	xor rax, rax
	and rdx, [mask_parte_baja64]
	and rcx, [mask_parte_baja64]
	mov rax, rdx
	imul rax, rcx 					; rax = width * height

	movdqa xmm14, [mask_shuffle_ammount]
	movq xmm15, r8				;cargo r8 que tiene en su byte menos significativo el amount, con la mascara me quedo solo con ese byte pues el resto es basura.
	pshufb xmm15, xmm14			; cargo en xmm15 000A | 000A | 000A | 000A

	movdqa xmm8, [mask_max0]
	movdqa xmm7, [mask_min255]
	movdqa xmm6, [mask_setear_alfa_en_255]
	movdqa xmm13, [mask_128]			; mascara para restar 128

while2:
	mov edx, dword [r9]	;cargo la mascara para los siguientes 4 pixeles
	movd xmm0, edx		; cargo la mascara en la primer dw
	pmovsxbd xmm0, xmm0	; extiendo cada byte a dword con signo para tener la mascara para cada pixel

	movdqu xmm1, [rsi]	; cargo 4 pixeles
	movdqu xmm2, xmm1
	movdqu xmm3, xmm1   ;copias de los pixeles originales
	movdqu xmm4, xmm1

	psrld xmm3, 8         ; pongo el green en el byte menos significativo  
    psrld xmm4, 16         ; el azul en el byte menos significativo
	;xmm2 para rojos, xmm3 para ver, xmm4 para azules

	pand xmm2, [mask_byte_mas_bajo]    ; me quedo solo con el Rojo     0 0 0 R
    pand xmm3, [mask_byte_mas_bajo]    ; me quedo solo con el verde    0 0 0 G
    pand xmm4, [mask_byte_mas_bajo]    ; me quedo solo con el AZUL     0 0 0 B


	;armo el valor rojo de 4 pixeles
	psubd xmm2, xmm13		; ROJO - 128
	pmulld xmm2, xmm15		; (ROJO - 128 ) * contraste
	psrad xmm2, 5			; shifteo 5 bits para dividir por 32
	paddd xmm2, xmm13		; al resultado, le sumo 128
	pmaxsd xmm2, xmm8			; max(0 ,resultado total de la cuenta)	
	pminsd xmm2, xmm7			; min(255, resultado total de la cuenta)		
	;de esta forma me queda en xmm2 el valor correcto, sea x,0 o 255		000 R | 000 R | 000 R | 000 R

	;armo el valor VERDE de 4 pixeles
	psubd xmm3, xmm13		; VERDE - 128
	pmulld xmm3, xmm15		; (VERDE - 128 ) * contraste
	psrad xmm3, 5			; shifteo 5 bits para dividir por 3FALSE2
	paddd xmm3, xmm13		; al resultado, le sumo 128
	pmaxsd xmm3, xmm8			; max(0 ,resultado total de la cuenta)	
	pminsd xmm3, xmm7			; min(255, resultado total de la cuenta)		
	;de esta forma me queda en xmm3 el valor correcto, sea x,0 o 255		000 G | 000 G | 000 G | 000 G

	;armo el valor AZUL de 4 pixeles
	psubd xmm4, xmm13		; AZUL - 128
	pmulld xmm4, xmm15		; (AZUL - 128 ) * contraste
	psrad xmm4, 5			; shifteo 5 bits para dividir por 32
	paddd xmm4, xmm13		; al resultado, le sumo 128
	pmaxsd xmm4, xmm8			; max(0 ,resultado total de la cuenta)	
	pminsd xmm4, xmm7			; min(255, resultado total de la cuenta)		
	;de esta forma me queda en xmm4 el valor correcto, sea x,0 FALSEo 255		000 B | 000 B | 000 B | 000 B

	;shifteo el azul y el verde para que queden alineados y luego poder hacer el por
	;en xmm2 esta el color rojo correspondiente ya alineado
	pslld xmm3, 8     ; 000G ----> 0 0 G 0 | ....
	pslld xmm4, 16     ; 000B ----> 0 B 0 0 | ....

	;empaqueto los resultados obtenidos en un xmm para luego ponerlo en dst

	por xmm2, xmm3		; R Y G ----->  00GR | 00GR | 00GR | 00GR
	por xmm2, xmm4		; R G y B ----> 0BGR | 0BGR | 0BGR | 0BGR
	por xmm2, xmm6		; agrego el Alfa en 255  ---> ABGR | ABGR | ABGR | ABGR

	;escribo los 4 pixeles en destinoFALSE

	pblendvb xmm1, xmm2		; si la mascara tiene 0's pongo el pixel original, si tiene 1's aplico filtro

	movdqa [rdi], xmm1

	add rsi, 16				; avanzamos src en 4 pixeles
	add rdi, 16				; avanzamos dst en 4 pixeles
	add r9, 4				; avanzo 4 bytes en la mascara
	sub rax, 4				; disminuimos en 4 los pixeles restantes
	cmp rax, 0				
	jg while2

	pop rbp
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
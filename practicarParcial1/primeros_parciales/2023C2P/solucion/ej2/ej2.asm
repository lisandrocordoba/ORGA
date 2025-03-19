global mezclarColores

section .data
mask_byte_mas_bajo db 0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00
mask_shuffle_cond1 db 0x02,0x00,0x01,0xFF,0x06,0x04,0x05,0xFF,0x0A,0x08,0x09,0xFF,0x0E,0x0C,0x0D,0xFF  ;;; si pongo 0x80 me carga 0?
mask_shuffle_cond2 db 0x01,0x02,0x00,0xFF,0x05,0x06,0x04,0xFF,0x09,0x0A,0x08,0xFF,0x0D,0x0E,0x0C,0xFF


;########### SECCION DE TEXTO (PROGRAMA)
section .text

;void mezclarColores(uint8_t *src, uint8_t *dst, uint32_t width, uint32_t height);
; ARGUMENTOS
; rdi = uint8_t *src
; rsi = uint8_t *dst
; rdx = uint32_t width
; rcx = uint32_t height

mezclarColores:
    ;prologo
    push rbp
    mov rbp, rsp

    ; calcular cantidad de pixeles
    xor rax, rax
    mov eax, edx        ; rax = width
    xor r10, r10
    mov r10d, ecx       ; r10 = height
    imul rax, r10       ; rax = pixel_amount

    ; iterar por toda la imagen
    while:
        movdqu xmm1, [rdi]       ; tomo 4 pixeles de la imagen original (ABGR_ABGR_ABGR_ABGR)
        movdqu xmm2, xmm1    
        movdqu xmm3, xmm1        ; hago 2 copias para aplicarle los shuffles de la condicion

        movdqu xmm5, [mask_shuffle_cond1]
        movdqu xmm4, [mask_shuffle_cond2]
        pshufb xmm2, xmm5 ; xmm2 tendra pixeles bajo la condicion 1
        pshufb xmm3, xmm4 ; xmm3 tendra pixeles bajo la condicion 2

        pslld xmm1, 8  
        psrld xmm1, 8              ; con esto limpio el alfa, queda en 0

        movdqu xmm13, xmm1
        movdqu xmm14, xmm1       ; copia de xmm1
        movdqu xmm15, xmm1       ; copia de xmm1                          
        psrld xmm15, 8           ; pongo el green en el byte menos significativo  
        psrld xmm13, 16          ; el azul en el byte menos significativo    

        pand xmm14, [mask_byte_mas_bajo]    ; me quedo solo con el Rojo     0 0 0 R
        pand xmm15, [mask_byte_mas_bajo]    ; me quedo solo con el verde    0 0 0 G
        pand xmm13, [mask_byte_mas_bajo]    ; me quedo solo con el AZUL     0 0 0 B

        vpcmpgtd xmm12, xmm14, xmm15                ; 1111 si ROJO > VERDE en xmm12
        vpcmpgtd xmm11, xmm15, xmm13                ; 1111 si VERDE > BLUE en xmm11
        ; para que se cumpla la condicion1 , ambas cosas tienen q pasar a la vez, hago un AND.
        pand xmm11, xmm12           ; en xmm11 tengo los pixeles que cumplen la condicion 1

        pand xmm2, xmm11            ; en xmm2 tengo SOLO los pixeles q cumplen la condicion 1, resto en 0

        ;ahora vamos a ver la condicion 2 R < G < B

        vpcmpgtd xmm10, xmm13, xmm15       ; 1111 SI AZUL > GREEN en xmm10
        vpcmpgtd xmm9, xmm15, xmm14       ; 1111 SI GREEN > RED en xmm9   
        pand xmm9, xmm10   ; deben pasar ambas cosas para que el pixel sea procesado en la condicion 2

        pand xmm3, xmm9    ; pongo SOLO los pixeles bajo la condicion2

        ; tengo en xmm9 los q van con condicion2, en xmm11 los que van en condicion 1, la negacion de esta mascara son los que quedan igual
        ; primero las combino
        por xmm9, xmm11
        pandn xmm9, xmm1        ; se la aplico al pixel orginial (estamos en el caso "sino")
        ; en xmm9 me quedan los pixeles que van bajo la condicion "sino"

        por xmm9, xmm3      ; PIXELES CONDICION 2 + CONDICION 3
        por xmm9, xmm2      ; PIXELES Q CUMPLEN COND1, COND2 Y COND 3.

        movdqu [rsi], xmm9  ; muevo los pixeles al dst

        siguiente_iteracion:
        add rdi, 16         ; avanzo 4 pixeles en X
        add rsi, 16         ; avanzo 4 pixeles en Y
        sub rax, 4          ; resto 4 a la cantidad de pixeles que quedan por procesar
        cmp rax, 0
        jne while

    pop rbp
    ret


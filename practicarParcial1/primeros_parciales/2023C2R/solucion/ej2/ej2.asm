global combinarImagenes_asm

section .data

    mask_pshufb db 0x02, 0xFF, 0x00, 0xFF, 0x06, 0xFF, 0x04, 0xFF, 0x0A, 0xFF, 0x08, 0xFF, 0x0E, 0xFF, 0x0C, 0xFF
    mask_blend_BLUE_WITH_RED db 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00
    mask_blend_BLUE_AND_RED_WITH_GREEN db 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00
    mask_blend_BLUE_AND_RED_AND_GREEN_WITH_ALFA db 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0xFF
    coeficientes_alfa times 16 db 255
    todos128 times 16 db 128
;########### SECCION DE TEXTO (PROGRAMA)
section .text

; ARGUMENTOS
;   rdi = uint8_t *src1
;   rsi = uint8_t *src2
;   rdx = uint8_t *dst
;   rcx = uint32_t width
;   r8 = uint32_t height

combinarImagenes_asm:
    ;prologo
    push rbp
    mov rbp, rsp

    ; calcular cantidad de pixeles
    xor rax, rax
    mov eax, ecx        ; rax = width
    xor r10, r10
    mov r10d, r8d       ; r10 = height
    imul rax, r10       ; rax = pixel_amount


    ; cargar mascaras
    movdqu xmm15, [mask_pshufb]
    movdqu xmm14, [coeficientes_alfa]
    movdqu xmm13, [mask_blend_BLUE_WITH_RED]
    movdqu xmm12, [mask_blend_BLUE_AND_RED_WITH_GREEN]
    movdqu xmm11, [mask_blend_BLUE_AND_RED_AND_GREEN_WITH_ALFA]
    movdqu xmm10, [todos128]

    ; iterar por toda la imagen
    while:
        ; cargar pixeles actuales 
        movdqu xmm1, [rdi]      ; xmm1 = ARGB_ARGB_ARGB_ARGB  de A 
        movdqu xmm2, [rsi]      ; xmm2 = ARGB_ARGB_ARGB_ARGB  de B

        ; procesar
        ;componente azul
        movdqu xmm4, xmm2          ; xmm4 = copia de los pixeles de B
        pshufb xmm4, xmm15         ; xmm4 = ABGR_ABGR_ABGR_ABGR
        paddusb xmm4, xmm1         ; xmm4 tiene las componentes blue de destino

        ;componente roja
        movdqu xmm5, xmm2          ; xmm5 = copia de los pixeles de B
        pshufb xmm5, xmm15         ; xmm5 = ABGR_ABGR_ABGR_ABGR
        psubusb  xmm5, xmm1        ; xmm5 tiene las componentes red de destino

        ;componente verde
        ; caso A > B
        movdqu xmm6, xmm1          ; xmm6 = copia de los pixeles de A
        psubusb xmm6, xmm2         ; xmm6 = gA - gB (componente green en el caso gA > gB)
        ; caso A <= B
        movdqu xmm7, xmm1          ; xmm7 = copia de los pixeles de A
        pavgb xmm7, xmm2           ; xmm7 = promedio(gA,gB) (componente green en el caso gA <= gB)
        ; escribir el caso correspondiente
        movdqu xmm0, xmm1          ; xmm0 = copia de los pixeles de A
        movdqu xmm8, xmm2          ; xmm8 = copia de los pixeles de B
        paddb xmm0, xmm10          ; truquito de sumarle 128 para mantener relacion de orden pq pcmpgtb usa signed
        paddb xmm8, xmm10          ; truquito de sumarle 128 para mantener relacion de orden pq pcmpgtb usa signed

        pcmpgtb xmm0, xmm8         ; mascara para el blend (1 si gA > gB y 0 si gA <= gB)
        pblendvb xmm7, xmm6        ; xmm7 tiene las componentes green de destino

        ; unir las componentes
        movdqu xmm0, xmm13          ; cargar en xmm0 mascara para unir xmm4(azul) con xmm5(rojo)
        pblendvb xmm4, xmm5         ; xmm4 tiene las comp blue y red de destino

        movdqu xmm0, xmm12          ;cargar en xmm0 mascara para unir xmm4(azul y rojo) con xmm7(verde)
        pblendvb xmm4, xmm7         ; xmm4 tiene las comp azul, rojo y verde de destino

        movdqu xmm0, xmm11          ; cargar en xmm0 mascara para unir xmm4(axul, rojo y verde) con xmm14 (alfa)
        pblendvb xmm4, xmm14        ; xmm4 tiene todos los campos de los pixeles a escribir en destino

        ; escribir 4 pixels en dst
        movdqu [rdx], xmm4 

        ;seguir while
        sub rax, 4          ; decremento en 4 los pixeles restantes
        add rdi, 16          ; avanzamos 4 pixeles en A 
        add rsi, 16          ; avanzamos 4 pixeles en B
        add rdx, 16          ; avanzamos 4 pixeles en dst
        cmp rax, 0
        jg while

    ;epilogo
    pop rbp
    ret 
section .data
%define NULL 0

%define OFFSET_LIST_FIRST 0
%define OFFSET_LIST_LAST 8

%define OFFSET_NODE_DATA 0
%define OFFSET_NODE_NEXT 8   
%define OFFSET_NODE_PREV 16

%define OFFSET_MONTO_PAGO 0
%define OFFSET_APROBADO_PAGO 1
%define OFFSET_PAGADOR_PAGO 8
%define OFFSET_COBRADOR_PAGO 16

section .text

global contar_pagos_aprobados_asm
global contar_pagos_rechazados_asm

global split_pagos_usuario_asm

extern malloc
extern free
extern strcmp


;########### SECCION DE TEXTO (PROGRAMA)

; uint8_t contar_pagos_aprobados_asm(list_t* pList, char* usuario);
; ARGUMENTOS
; rdi = list_t* pList
; rsi =  char* usuario
contar_pagos_aprobados_asm:
    ;prologo
    push rbp
    mov rbp, rsp

    ; preservo r12, r13, r14, r15 en la pila pues son no volatiles y los voy a utilizar
    push r12
    push r13
    push r14
    push r15            ; PILA ALINEADA

    ; preservo los argumentos en no volatiles (r12 y r13)
    mov r12, rdi                            ; r12 = list
    mov r13, rsi                            ; r13 = usuario     

    ; inicializo cantidadDeRechazados = 0 en r14
    xor r14, r14                            ; r14 = cantidadDeRechazados = 0

    ; inicializo nodo_actual = list->first en r15
    mov r15, [r12 + OFFSET_LIST_FIRST]      ; r15 = nodo_actual = list->first

    ; si list->first = NULL, salgo
    cmp r15, NULL
    je fin


    ; recorro todos los pagos de la lista
    while:
        mov r8, [r15 + OFFSET_NODE_DATA]    ; r8 = pago_actual
        mov rdi, [r8 + OFFSET_COBRADOR_PAGO]; rdi = pagador_actual
        mov rsi, r13                        ; rsi = usuario
        ; si pago_actual rechazado, avanzo al siguiente pago
        cmp byte [r8 + OFFSET_APROBADO_PAGO], 1                         ;;;;;;;;; APROBADO SERIA 1????????????'
        jne siguiente_iteracion
        ; si pagador != usuario, avanzo al siguiente pago
        call strcmp                         ; retorna 0 en rax si (rdi == rsi)
        cmp rax, 0
        jne siguiente_iteracion
        ; aca se que el pago es aprobado y el pagador es 'usuario'
        inc r14                             ; cantidadDeRechazados++

        siguiente_iteracion:
        mov r15, [r15 + OFFSET_NODE_NEXT]   ; r15 = nodo_actual->next
        cmp r15, NULL
        jne while

    ;epilogo
    fin:
    mov rax, r14
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp

    ret

; uint8_t contar_pagos_rechazados_asm(list_t* pList, char* usuario);
contar_pagos_rechazados_asm:
    ;prologo
    push rbp
    mov rbp, rsp

    ; preservo r12, r13, r14, r15 en la pila pues son no volatiles y los voy a utilizar
    push r12
    push r13
    push r14
    push r15            ; PILA ALINEADA

    ; preservo los argumentos en no volatiles (r12 y r13)
    mov r12, rdi                            ; r12 = list
    mov r13, rsi                            ; r13 = usuario     

    ; inicializo cantidadDeRechazados = 0 en r14
    xor r14, r14                            ; r14 = cantidadDeRechazados = 0

    ; inicializo nodo_actual = list->first en r15
    mov r15, [r12 + OFFSET_LIST_FIRST]      ; r15 = nodo_actual = list->first

    ; si list->first = NULL, salgo
    cmp r15, NULL
    je fin2


    ; recorro todos los pagos de la lista
    while2:
        mov r8, [r15 + OFFSET_NODE_DATA]     ; r8 = pago_actual
        mov rdi, [r8 + OFFSET_COBRADOR_PAGO] ; rdi = pagador_actual
        mov rsi, r13                         ; rsi = usuario
        ; si pago_actual aprobado, avanzo al siguiente pago
        cmp byte [r8 + OFFSET_APROBADO_PAGO], 0                         ;;;;;;;;; RECHAZAZDO SERIA 0????????????'
        jne siguiente_iteracion2
        ; si pagador != usuario, avanzo al siguiente pago
        call strcmp                         ; retorna 0 en rax si (rdi == rsi)
        cmp rax, 0
        jne siguiente_iteracion2
        ; aca se que el pago es rechazado y el pagador es 'usuario'
        inc r14                             ; cantidadDeRechazados++

        siguiente_iteracion2:
        mov r15, [r15 + OFFSET_NODE_NEXT]   ; r15 = nodo_actual->next
        cmp r15, NULL
        jne while2

    ;epilogo
    fin2:
    mov rax, r14
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp

    ret



; pagoSplitted_t* split_pagos_usuario_asm(list_t* pList, char* usuario);
; ARGUMENTOS
; rdi = list_t* pList
; rsi = char* usuario
split_pagos_usuario_asm:
    ;epilogo
    push rbp
    mov rbp, rsp

    ; preservar en la pila los no volatiles que uso (r12, r13, r14 y r15)
    push r12
    push r13
    push r14
    push r15

    ; preservar en no volatiles los argumentos (r12 y r13)
    mov r12, rdi                    ; r12 = list
    mov r13, rsi                    ; r13 = usuario

    ; inicializar registros
    xor r14, r14                    ; r14 = cantidadPagosRechazados = 0
    xor r15, r15                    ; r15 = cantidadPagosAprobados = 0

    ; llamar a contar_pagos_aprobados (obs los argumentos rdi y rsi ya estan bien)
    call contar_pagos_aprobados     ; en rax queda cantidadPagosAprobados
    mov r14b, al                    ; r14 = cantidadPagosAprobados
    

    ; llamar a contar_pagos_rechazados
    mov rdi, r12
    mov rsi, r13
    call contar_pagos_rechazados    ; en rax queda cantidadPagosRechazados
    mov r15b, al                    ; r15 = cantidadPagosRechazados

    ; reservar la memoria del struct splitted
    xor rdi, rdi
    add rdi, 24
    call malloc
    mov rbx, rax                    ; rbx = puntero a splitted

    ; setear el campo cant_aprobados
    movb [rbx + OFFSET_CANT_APROBABOS], r14b   
    ; setear el campo cant_rechazados
    movb [rbx + OFFSET_CANT_RECHAZADOS], r15b

    ; setear el array **aprobados
    xor rax, rax
    mov rax, 8                      
    mul 14b                         ; rax = cantidadPagosAprobados * 8 (tamaño del struct pago_t)        
    xor rdi, rdi
    mov rdi, rax                    
    call malloc                     ; rax = puntero al array de aprobados
    mov [rbx + OFFSET_ARRAY_APROBADOS], rax

    xor rax, rax
    mov rax, 8
    mul 15b                         ; rax = cantidadPagosRechazados * 8 (tamaño del struct pago_t)
    xor rdi, rdi
    mov rdi, rax
    call malloc                     ; rax = puntero al array de desaprobados
    mov [rbx + OFFSET_ARRAY_DESAPROBADOS], rax

    ; ACA YA PUEDO REUTILIZAR R14 Y R15 
    
    ; inicializo nodo_actual = list->first en r15
    mov r15, [r12 + OFFSET_LIST_FIRST]      ; r15 = nodo_actual = list->first
    ; si list->first = NULL, salgo
    cmp r15, NULL
    je fin3


    ; recorrer todos los pagos
    while3:
        mov r8, [r15 + OFFSET_NODE_DATA]            ; r8 = pago_actual
        cmp byte [r8 + OFFSET_APROBADO_PAGO], 0 



    siguiente_iteracion3:




    fin3:
    mov rax, rbx
    ;prologo

    


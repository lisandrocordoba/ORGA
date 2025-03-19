section .data
%define OFFSET_FIRST_LIST 0

%define OFFSET_DATA_LIST_ELEM 0
%define OFFSET_NEXT_ELEM_LIST 8

%define OFFSET_APROBADO_PAGO 1
%define OFFSET_PAGADOR_PAGO 8
%define OFFSET_COBRADOR_PAGO 16

%define OFFSET_CANTIDAD_APROBADOS_SPLITTED 0
%define OFFSET_CANTIDAD_RECHAZADOS_SPLITTED 1
%define OFFSET_APROBADOS_SPLITTED 8
%define OFFSET_RECHAZADOS_SPLITTED 16

%define OFFSET_INDICE_APROBADOS 1
%define OFFSET_INDICE_RECHAZADOS 2




section .text

global contar_pagos_aprobados_asm
global contar_pagos_rechazados_asm

global split_pagos_usuario_asm

extern malloc
extern free
extern strcmp


;########### SECCION DE TEXTO (PROGRAMA)

; uint8_t contar_pagos_aprobados_asm(list_t* pList, char* usuario);
;   ARGUMENTOS
;   rdi -> list_t* pList
;   rsi -> char* usuario
contar_pagos_aprobados_asm:
    prologo:
        push rbp
        mov rbp, rsp
        ; Preservo los volatiles
        push rbx
        push r12
        push r13
        push r14
        push r15
        sub rsp, 8  ; PILA ALINEADA

    xor rbx, rbx    ; rbx = contador = 0
    mov r12, rsi    ; r12 = usuario

    mov r13, [rdi + OFFSET_FIRST_LIST]  ; r13 = elem_actual = pList->first
    while:
        ; if (elem_actual == NULL) {salir}
        cmp r13, 0
        je fin  

        mov r14, [r13 + OFFSET_DATA_LIST_ELEM]  ; r14 = pago_actual = elem_actual->data
        xor r15, r15
        mov r15b, [r14 + OFFSET_APROBADO_PAGO]   ; r15 = pago_actual->aprobado

        ; if (!(pago_actual->aprobado)) {siguiente iteracion}
        cmp r15, 1
        jne siguiente_iteracion

        ; if ((pago_actual->pagador) != usuario) {siguiente iteracion}
        mov rdi, [r14 + OFFSET_PAGADOR_PAGO]    ; rdi = pago_actual->pagador
        mov rsi, r12                            ; rsi = usuario
        call strcmp
        cmp rax, 0
        jne siguiente_iteracion

        ; si llegó hasta aca, contador++
        inc rbx

        siguiente_iteracion:
        mov r13, [r13 +  OFFSET_NEXT_ELEM_LIST]     ; r13 = elem_actual->next
        jmp while

    fin:
    mov rax, rbx    ; rax = contador

    epilogo:
        add rsp, 8 
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        pop rbp

        ret

; uint8_t contar_pagos_rechazados_asm(list_t* pList, char* usuario);
contar_pagos_rechazados_asm:
    prologo2:
        push rbp
        mov rbp, rsp
        ; Preservo los volatiles
        push rbx
        push r12
        push r13
        push r14
        push r15
        sub rsp, 8  ; PILA ALINEADA

    xor rbx, rbx    ; rbx = contador = 0
    mov r12, rsi    ; r12 = usuario

    mov r13, [rdi + OFFSET_FIRST_LIST]  ; r13 = elem_actual = pList->first
    while2:
        ; if (elem_actual == NULL) {salir}
        cmp r13, 0
        je fin2

        mov r14, [r13 + OFFSET_DATA_LIST_ELEM]  ; r14 = pago_actual = elem_actual->data
        xor r15, r15
        mov r15b, [r14 + OFFSET_APROBADO_PAGO]   ; r15 = pago_actual->aprobado

        ; if ((pago_actual->aprobado)) {siguiente iteracion}
        cmp r15, 0
        jne siguiente_iteracion2

        ; if ((pago_actual->pagador) != usuario) {siguiente iteracion}
        mov rdi, [r14 + OFFSET_PAGADOR_PAGO]    ; rdi = pago_actual->pagador
        mov rsi, r12                            ; rsi = usuario
        call strcmp
        cmp rax, 0
        jne siguiente_iteracion2

        ; si llegó hasta aca, contador++
        inc rbx

        siguiente_iteracion2:
        mov r13, [r13 +  OFFSET_NEXT_ELEM_LIST]     ; r13 = elem_actual->next
        jmp while2

    fin2:
    mov rax, rbx    ; rax = contador

    epilogo2:
        add rsp, 8
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        pop rbp

        ret


; pagoSplitted_t* split_pagos_usuario_asm(list_t* pList, char* usuario)
;   ARGUMENTOS
;   rdi -> list_t* pList
;   rsi -> char* usuario
split_pagos_usuario_asm:
    prologo3:
        push rbp
        mov rbp, rsp

        ; preservo los no volatiles y hago lugar para variables
        sub rsp, 8      
        push rbx
        push r12
        push r13
        push r14
        push r15        ; PILA ALINEADA

    mov r12, rdi                            ; r12 = list
    mov r13, rsi                            ; r13 = usuario

    mov rdi, 24
    call malloc
    mov r14, rax                            ; r14 = pagoSplitted_t* splitted

    ; reservar memoria para el array de pagos aprobados
    mov rdi, r12
    mov rsi, r13
    call contar_pagos_aprobados_asm         ; al = cantidad pagos aprobados del usuario
    mov [r14 +  OFFSET_CANTIDAD_APROBADOS_SPLITTED], al

    xor rdi, rdi
    mov dil, al                             ; rdi = cantidad pagos aprobados del usuario
    mov rax, 24                             ; rax = 24
    imul rdi, rax                           ; rdi = sizeof(pago_t) * cantidad pagos aprobados
    call malloc                             ; rax = puntero a array de aprobados
    mov [r14 + OFFSET_APROBADOS_SPLITTED], rax

    ; reservar memoria para el array de pagos rechazados
    mov rdi, r12
    mov rsi, r13
    call contar_pagos_rechazados_asm         ; al = cantidad pagos rechazados del usuario
    mov [r14 +  OFFSET_CANTIDAD_RECHAZADOS_SPLITTED], al

    xor rdi, rdi
    mov dil, al                             ; rdi = cantidad pagos aprobados del usuario
    mov rax, 24                             ; rax = 24
    imul rdi, rax                           ; rdi = sizeof(pago_t) * cantidad pagos aprobados
    call malloc                             ; rax = puntero a array de aprobados
    mov [r14 + OFFSET_RECHAZADOS_SPLITTED], rax

    ; itero por la lista de pagos y los voy guardando en aprobados/desaprobados
    mov r12, [r12 + OFFSET_FIRST_LIST]            ; r12 = elem_actual = list->first
    mov [rbp - OFFSET_INDICE_APROBADOS], byte 0   ; i_aprobados = 0
    mov [rbp - OFFSET_INDICE_RECHAZADOS], byte 0  ; i_rechazados = 0

    while3:
        ; if (elem_actual == NULL) {salir}
        cmp r12, 0
        je fin3

        mov r15, [r12 + OFFSET_DATA_LIST_ELEM]  ; r15 = pago_actual = elem_actual->data

        ; if (!(pago_actual->cobrador == usuario )) {siguiente iteracion}
        mov rdi, [r15 + OFFSET_COBRADOR_PAGO]   ; rdi = pago_actual->cobrador
        mov rsi, r13                            ; rsi = usuario
        call strcmp
        cmp rax, 0
        jne siguiente_iteracion3


        ; if (pago_actual->aprobado == 1) {agregar pago a lista de aprobados}
        mov dil, [r15 + OFFSET_APROBADO_PAGO]
        cmp dil, 1
        je agregar_pago_aprobado 

        ; else {agregar pago a lista de rechazados}
        jmp agregar_pago_rechazado

        agregar_pago_aprobado:
            xor r8, r8
            mov r8, [rbp - OFFSET_INDICE_APROBADOS]     ; r8 = i_aprobados
            shl r8, 3                                   ; r8 = i_aprobados * sizeof(pago_t*)
            mov r9, [r14 + OFFSET_APROBADOS_SPLITTED]   ; r9 = array de aprobados
            mov [r9 + r8], r15                          ; agrego el pago
            inc byte [rbp - OFFSET_INDICE_APROBADOS]          ; i_aprobados++
            jmp siguiente_iteracion3

        agregar_pago_rechazado:
            xor r8, r8
            mov r8, [rbp - OFFSET_INDICE_RECHAZADOS]    ; r8 = i_rechazados
            shl r8, 3                                   ; r8 = i_rechazados * sizeof(pago_t*)
            mov r9, [r14 + OFFSET_RECHAZADOS_SPLITTED]  ; r9 = array de rechazados
            mov [r9 + r8], r15                          ; agrego el pago
            inc byte [rbp - OFFSET_INDICE_RECHAZADOS]        ; i_rechazados++
            jmp siguiente_iteracion3

        siguiente_iteracion3:
        mov r12, [r12 +  OFFSET_NEXT_ELEM_LIST]     ; r13 = elem_actual->next
        jmp while3

    fin3:
    mov rax, r14

    epilogo3:
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        add rsp, 8
        pop rbp

        ret


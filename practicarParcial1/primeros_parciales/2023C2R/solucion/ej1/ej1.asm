; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data
%define SIZE_STRUCT_LIST 16
%define SIZE_STRUCT_NODE 32
%define SIZE_EMPTY_STRING 1
%define OFFSET_LIST_FIRST 0
%define OFFSET_LIST_LAST 8
%define OFFSET_NODE_NEXT 0
%define OFFSET_NODE_PREVIOUS 8
%define OFFSET_NODE_TYPE 16
%define OFFSET_NODE_HASH 24

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat


string_proc_list_create_asm:
    ;prologo
    push rbp
    mov rbp, rsp
    
    mov rdi, SIZE_STRUCT_LIST            ; rdi = argumento (16 bytes) para malloc
    call malloc                          ; en rax queda el puntero a la nueva lista

    mov qword [rax + OFFSET_LIST_FIRST], NULL                ; seteo list->first en 0 (NULL) 
    mov qword [rax + OFFSET_LIST_LAST], NULL            ; seteo list->last en 0 (NULL) 

    ;epilogo
    pop rbp

    ret

string_proc_node_create_asm:
    ; rdi = uint8_t type
    ; rsi = char* hash

    ;prologo
    push rbp
    mov rbp, rsp

    ; preservo los argumentos, pues sino los puedo perder al llamar a funcion
    push rdi
    push rsi

    mov rdi, SIZE_STRUCT_NODE                  ; rdi = argumento (64 bytes) para malloc
    call malloc                         ; en rax queda el puntero al nuevo nodo

    ; recupero de la pila los argumentos 
    pop rsi
    pop rdi

    mov qword [rax + OFFSET_NODE_NEXT], NULL                ; seteo nodo->next en 0 (NULL) 
    mov qword [rax + OFFSET_NODE_PREVIOUS], NULL            ; seteo nodo->previous en 0 (NULL)
    mov [rax + OFFSET_NODE_TYPE], dil                  ; seteo nodo->type en type
    mov [rax + OFFSET_NODE_HASH], rsi                  ; seteo nodo->hash en hash

    ;epilogo
    pop rbp

    ret



string_proc_list_add_node_asm:
    ; rdi = string_proc_list* list
    ; rsi = uint8_t type
    ; rdx = char* hash

    ;prologo
    push rbp
    mov rbp, rsp

    ; preservo rdi, pues no quiero perder el puntero a list al llamar a funcion
    push rdi
    sub rsp, 8                              ; alineo la pila
    
    ;reacomodo los argumentos para llamar a string_proc_node_create_asm
    mov rdi, rsi                            ; rdi = uint8_t type
    mov rsi, rdx                            ; rsi = char* hash

    call string_proc_node_create_asm        ; rax = puntero a new_node
    add rsp, 8                              ; dejo la pila como estaba

    pop rdi                                 ; rdi = puntero a list
    mov r11, [rdi + OFFSET_LIST_LAST]       ; actual_node = list->last
    mov [rdi + OFFSET_LIST_LAST], rax       ; list->last = new_nodo

    cmp r11, 0               
    jne insertarNodo                        ; si actual_node != null

    mov [rdi + OFFSET_LIST_FIRST], rax      ; list->first = new_node
    jmp fin

    insertarNodo:
    mov [r11 + OFFSET_NODE_NEXT], rax       ; actual_node->next = new_node
    mov [rax + OFFSET_NODE_PREVIOUS], r11   ; new_node->previous = actual_node

    fin:
    ;epilogo
    pop rbp

    ret


string_proc_list_concat_asm:
    ; rdi = string_proc_list* list
    ; rsi = uint8_t type
    ; rdx = char* hash

    ;prologo
    push rbp
    mov rbp, rsp

    sub rsp, 8                  ; STACK DESALINEADO

    ; preservo argumentos
    push r12
    push r13
    push r14                    ; STACK ALINEADO
    mov r12, rdi                ; r12 = list
    mov r13, rsi                ; r13 = type
    mov r14, rdx                ; r14 = hash

    mov rdi, SIZE_EMPTY_STRING
    call malloc                 ; rax = puntero a 1 byte
    mov byte [rax], 0           ; rax = ""

    ; acomodo los argumentos para concat
    mov rdi, rax                ; rdi = ""
    mov rsi, r14                ; rsi = hash original
    mov r14, rax                ; r14 = memoria 'vieja' del ""
    call str_concat             ; rax = nuevo hash igual al original
    
    ; libero memoria de ""
    mov rdi, r14                ; paso el argumento para free
    mov r14, rax                ; en r14 preservo el puntero al nuevo hash
    call free                   

    ; recorro todos los nodos
    mov rdi, r12                            ; rdi = list
    mov rdi, [rdi + OFFSET_LIST_FIRST]      ; rdi = list->first
    cmp rdi, 0
    je fin2                                  ; si lista->first == NULL, no entro al while
    while:
        ; si es del mismo tipo agrego al hash
        mov r10b, [rdi + OFFSET_NODE_TYPE]   ; r10b = actual->type
        xor rsi, rsi    
        mov rsi, r13                         ; sil = type
        cmp r10b, sil
        jne siguienteIteracion               ; si no son del mismo tipo, voy a la sgte iteracion

        ; concatenacion
        mov r12, rdi                         ; en r12 preservo el nodo actual
        mov rsi, [rdi + OFFSET_NODE_HASH]    ; rsi = actual->hash
        mov rdi, r14                         ; rdi = concatenacion actual de hashes
        call str_concat                      ; rax = hash actualizado (concatenado)

        ; libero memoria de la concatenacion anterior
        mov rdi, r14
        mov r14, rax                         ; en r14 preservo la nueva concatenacion
        call free
        mov rdi, r12                        ; rdi = actual

        siguienteIteracion:
        mov rdi, [rdi + OFFSET_NODE_NEXT]   ; rdi = actual->next
        cmp rdi, 0                          
        jnz while                           ; si actual != null sigo el while

    fin2:
    ;epilogo
    mov rax, r14                            ; dejo en rax el puntero al nuevohash

    pop r14
    pop r13
    pop r12
    add rsp, 8
    pop rbp

    ret

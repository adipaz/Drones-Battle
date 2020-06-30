

section .data
%define X 0
%define Y 4
%define STK 4



section .text
    align 16
    global func_target
    global create_target
    extern TARGET
    extern SCALE
    extern random
    extern printf
    extern generate_random
    extern x_target
    extern y_target
    extern resume
    extern curr_i
    extern CORS

func_target:

    call create_target      ; create a new target with random coordinates on the game board
    
    mov ebx,dword[curr_i]
    mov ecx,dword[CORS]
    shl ebx,3
    add ebx,ecx
    call resume                  ;  switch to the co-routine of the "current" drone by calling resume(drone id) function

    jmp func_target


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;CREATE_TARGET;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_target:
    push ebp
    mov ebp,esp

    mov dword[SCALE],100    ; we want to generate number in range [0,100]

    call generate_random    ; generate x
    mov ebx,dword[random]
    mov dword[x_target],ebx ; x_target = x

    mov dword[SCALE],100

    call generate_random    ; generate y
    mov ebx,dword[random]
    mov dword[y_target],ebx ; y_target = y


    mov esp, ebp
    pop ebp
    ret
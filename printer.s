section	.rodata
    format_target: db "%.2f , %.2f",10,0
    format_drone: db "%d , %.2f , %.2f , %.2f , %.2f , %d",10,0
    new_line: db 10

section .data
    %define ID 0
    %define co_X 4
    %define co_Y 8
    %define alpha 12
    %define speed 16
    %define destroyed 20

    i: dd 0


section .text
    align 16
    extern printf
    global func_printer
    extern TARGET
    extern DRONES
    extern SCHEDULER
    extern N
    extern x_target
    extern y_target
    extern resume

%macro print_float 2
    fld dword [%1+%2]
    sub esp,8
    fstp qword [esp]
%endmacro

func_printer:

print_target:


    fld dword[y_target]
    sub esp,8
    fstp qword[esp]
    fld dword[x_target]
    sub esp,8
    fstp qword[esp]
    push format_target
    call printf              ; print target's coordinates
    add esp,20


    mov dword[i],0
print_drone_i:
    mov ebx,dword[i]
    cmp ebx,dword[N]
    jge finish_print_drones

    mov ecx,dword[DRONES]
    mov eax,dword[ecx+4*ebx] ; eax = pointer to drone_i data

    cmp dword[eax],0
    jz inc_i

    push dword[eax+destroyed]
    print_float eax,speed
    print_float eax,alpha
    print_float eax,co_Y
    print_float eax,co_X
    push dword[eax+ID]
    push format_drone
    call printf              ; print drone_i id,x,y,alpha,speed,destroyed
    add esp,44

inc_i:
    inc dword[i]
    jmp print_drone_i


    

finish_print_drones:

    push new_line
    call printf
    add esp,4

    mov ebx,SCHEDULER
    call resume             ; switch back to a scheduler co-routine

    jmp func_printer

    ret
section	.rodata
    format_winner: db "The Winner is drone %d",10,0

section .data
    %define ID 0
    %define co_X 4
    %define co_Y 8
    %define alpha 12
    %define speed 16
    %define destroyed 20

    i_scheduler: dd 0
    i_active: dd 0
    i_winner: dd 0
    i_M: dd 0
    j: dd 0
    i_tf: dd 0
    i_free: dd 0
    remain: dd 0
    active: dd 0
    winner: dd 0
    M: dd 0



section .text
    align 16
    extern printf
    extern DRONES
    extern PRINTER
    extern SCHEDULER
    extern free
    extern N
    extern K
    extern R
    extern curr_i
    global func_scheduler
    extern func_drone
    extern func_printer
    extern resume
    extern CORS
    extern CURR
    extern ARR_FOR_FREE

%macro freeAll 0
    mov dword[i_free],0
%%begin:
    mov ebx,dword[i_free]
    cmp ebx,dword[N]
    jge %%finish
    mov ecx,dword[ARR_FOR_FREE]
    push dword[ecx+4*ebx]
    call free                    ; free drone_i stack
    add esp,4
    mov ecx,dword[DRONES]
    push dword[ecx+4*ebx]
    call free                    ; free drone_i stack
    add esp,4
    inc dword[i_free]
    jmp %%begin
%%finish:
    push dword[DRONES]
    call free                    ; free drones array
    add esp,4
    push dword[CORS]
    call free                    ; free CORS
    add esp,4
    push dword[ARR_FOR_FREE]
    call free                    ; free CORS
    add esp,4
%endmacro

func_scheduler:
    push ebp
    mov ebp, esp

    mov dword[i_scheduler],0     ; start from i=0

scheduler_loop:

    mov edx,0
    mov eax,dword[i_scheduler]
    div dword[N]                 ; now edx = i%N
    mov dword[curr_i],edx

    mov ecx,dword[DRONES]
    mov eax,dword[ecx+4*edx]     ; now eax = pointer to drone_i data
    cmp dword[eax+ID],0          ; if drone (i%N)+1 is active
    jz continue1


    mov ebx,dword[curr_i]
    mov ecx,dword[CORS]
    shl ebx,3
    add ebx,ecx
    call resume                  ; switch to the drone_i co-routine

    continue1:
        mov edx,0
        mov eax,dword[i_scheduler]
        div dword[K]             ; now edx = i%K
        cmp edx,0                ; if i%K == 0 time to print the game board
        jnz continue2

        mov ebx,PRINTER
        call resume        ; switch to the printer co-routine

        ;call func_printer


    continue2:
        mov edx,0
        mov eax,dword[i_scheduler]
        div dword[N]             ; now eax = i/N , edx = i%N
        cmp edx,0                ; if i%N ==0
        jnz continue3
        mov dword[remain],edx
        mov edx,0
        div dword[R]             ; now edx = (i/N)%R
        cmp edx,0


        jnz continue3            ; && if (i/N)%R == 0 R rounds have passed

        pushad
        call find_M              ; find M - the lowest number of targets destroyed, between all of the active drones
        popad

        pushad
        call turn_off            ; "turn off" one of the drones that destroyed only M targets.
        popad

    continue3:
    inc dword[i_scheduler]       ; i++

    pushad
    call check_active_drones
    popad


    cmp dword[active],1          ; if only one active drone is left
    jnz continue4


    pushad
    call get_winner
    popad

    push dword[winner]
    push format_winner
    call printf                  ; print The Winner is drone: <id of the drone>
    add esp,8


    call exit

    continue4:
    jmp scheduler_loop

    mov esp, ebp
    pop ebp
    ret




    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;CHECK_ACTIVE_DRONES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_active_drones:
    push ebp
    mov ebp, esp

    mov dword[i_active],0
    mov dword[active],0

active_loop:
    mov ebx,dword[i_active]
    cmp ebx,dword[N]
    jge finish_active_loop

    mov ecx,dword[DRONES]
    mov eax,dword[ecx+4*ebx]     ; now eax = pointer to drone_i data

    cmp dword[eax+ID],0
    jz inc_i_active              ; if i'th drone is
    inc dword[active]

inc_i_active:
    inc dword[i_active]
    jmp active_loop


finish_active_loop:


    mov esp, ebp
    pop ebp
    ret



    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GET_WINNER;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_winner:
    push ebp
    mov ebp, esp

    mov dword[i_winner],0
    mov dword[winner],0

winner_loop:
    mov ebx,dword[i_winner]
    cmp ebx,dword[N]
    jge finish_winner_loop

    mov ecx,dword[DRONES]
    mov eax,dword[ecx+4*ebx]     ; now eax = pointer to drone_i data

    cmp dword[eax+ID],0
    jnz found_winner             ; if i'th drone is active
    inc dword[i_winner]
    jmp winner_loop

found_winner:
    mov ebx,dword[eax+ID]
    mov dword[winner],ebx

finish_winner_loop:

    mov esp, ebp
    pop ebp
    ret


    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;FIND_M;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_M:
    push ebp
    mov ebp, esp

    mov dword[j],0

init_M:
    mov ebx,dword[j]
    cmp ebx,dword[N]
    jge start_M_loop

    mov ecx,dword[DRONES]
    mov eax,dword[ecx+4*ebx]     ; now eax = pointer to drone_i data

    cmp dword[eax+ID],0
    jz inc_j
    mov ecx,dword[eax+destroyed]
    mov dword[M],ecx
    jmp start_M_loop

inc_j:
    inc dword[j]
    jmp init_M





start_M_loop:
    mov dword[i_M],0
M_loop:
    mov ebx,dword[i_M]
    cmp ebx,dword[N]
    jge finish_M_loop

    mov ecx,dword[DRONES]
    mov eax,dword[ecx+4*ebx]     ; now eax = pointer to drone_i data
    cmp dword[eax+ID],0
    jz inc_i_M
    mov eax,dword[eax+destroyed] ; now eax = destroyed of drone_i
    cmp dword[M],eax
    jle inc_i_M
    mov dword[M],eax

inc_i_M:
    inc dword[i_M]
    jmp M_loop

finish_M_loop:


    mov esp, ebp
    pop ebp
    ret



    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;TURN_OFF;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

turn_off:
    push ebp
    mov ebp, esp

    mov dword[i_tf],0

turn_off_loop:
    mov ebx,dword[i_tf]
    cmp ebx,dword[N]
    jge finish_turn_off_loop

    mov ecx,dword[DRONES]
    mov eax,dword[ecx+4*ebx]     ; now eax = pointer to drone_i data

    cmp dword[eax],0             ; check if drone_i is active
    jz inc_i_turn_off

    mov ebx,dword[M]
    cmp ebx,dword[eax+destroyed]
    jnz inc_i_turn_off

    mov dword[eax+ID],0          ; turn off drone i
    jmp finish_turn_off_loop

inc_i_turn_off:
    inc dword[i_tf]
    jmp turn_off_loop



finish_turn_off_loop:


    mov esp, ebp
    pop ebp
    ret

    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;EXIT;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

exit:

    freeAll

    mov eax,1
    mov ebx,0
    int 80h                      ; stop the game



section	.rodata                         
    format_int: db "%d",0                ; format int
    format_float: db "%f",0              ; format float

section .data
    global TARGET
    global PRINTER
    global SCHEDULER
    global DRONES
    global random
    global SCALE
    global N
    global K
    global R
    global d
    global x_target
    global y_target
    global CORS
    global CURR
    global SPP
    global ARR_FOR_FREE

    %define ID 0
    %define co_X 4
    %define co_Y 8
    %define alpha 12
    %define speed 16
    %define destroyed 20

    N: dd 0
    R: dd 0
    K: dd 0
    d: dd 0.0
    seed: dd 0
    x_target: dd 0
    y_target: dd 0

    DRONES: dd 0
    TARGET: dd func_target
            dd stk_target+STKSIZE
    PRINTER: dd func_printer
            dd stk_printer+STKSIZE
    SCHEDULER: dd func_scheduler
            dd stk_scheduler+STKSIZE
    CORS: dd 0

    i: dd 0
    i_init: dd 0
    b16: db 0b00000001
    b14: db 0b00000100
    b13: db 0b00001000
    b11: db 0b00100000
    random: dd 0.0
    MAXINT: dd 65535
    SCALE: dd 0
    SPT: dd 0
    CURR: dd 0
    ARR_FOR_FREE: dd 0




section .bss                             ; we define (global) uninitialized variables in .bss section
    global stk_target
    global stk_printer
    global stk_scheduler
    global STKSIZE

    STKSIZE:  equ 16*1024
    stk_target: resb STKSIZE
    stk_printer: resb STKSIZE
    stk_scheduler: resb STKSIZE

    CODEP: equ 0                         ; offset of pointer to co-routine function in co-routine struct
    SPP: equ 4                           ; offset of pointer to co-routine stack in co-routine struct






section .text
  align 16
  global main
  global generate_random
  global resume
  extern printf
  extern fprintf
  extern malloc
  extern calloc
  extern free
  extern sscanf
  extern stderr
  extern func_target
  extern func_printer
  extern func_scheduler
  extern func_drone
  extern create_target



%macro convert_arg_i 3
    pushad
    push %1
    push %2
    push %3
    call sscanf
    add esp,12
    popad
%endmacro

%macro convert_args 0
    mov ecx,dword[ebp+12]

    convert_arg_i N,format_int,dword[ecx+4]
    convert_arg_i R,format_int,dword[ecx+8]
    convert_arg_i K,format_int,dword[ecx+12]
    convert_arg_i d,format_float,dword[ecx+16]
    convert_arg_i seed,format_int,dword[ecx+20]
%endmacro

%macro malloc_drones_array 0
    mov ecx,dword[N]
    shl ecx,2                            ; ecx = N*4
    push ecx
    call malloc                          ; allocate memory for drones data array - 4 bytes each:  for data pointer
    mov dword[DRONES],eax

    mov ecx,dword[N]
    shl ecx,2                            ; ecx = N*4
    push ecx
    call malloc                          
    mov dword[ARR_FOR_FREE],eax

    mov ecx,dword[N]
    shl ecx,3                            ; ecx = N*8
    push ecx
    call malloc                          ; allocate memory for CORS array - 8 bytes each: 4 for func pointer , 4 for stack pointer
    mov dword[CORS],eax


%endmacro

%macro malloc_droneI_data 0
    mov dword[i],0
%%begin:
    mov ebx,dword[i]
    cmp ebx,dword[N]
    jge %%finish

    mov ecx,dword[DRONES]
    push ecx
    push ebx
    push 24                              ; malloc 24 bytes for each drone data: 4 for ID , 4 for x , 4 for y , 4 for angle, 4 for speed , 4 for destroyed
    call malloc
    add esp,4
    pop ebx
    pop ecx

    mov dword[ecx+4*ebx],eax
    inc dword[i]
    jmp %%begin
%%finish:
%endmacro

%macro init_target_printer_scheduler 0
    mov dword[SPT],esp
    mov esp,dword[TARGET+4]              ; esp = stack of target
    push func_target
    pushfd
    pushad
    mov dword[TARGET+4],esp
    mov esp,dword[SPT]
    

    mov dword[SPT],esp
    mov esp,dword[SCHEDULER+4]           ; esp = stack of target
    push func_scheduler
    pushfd
    pushad
    mov dword[SCHEDULER+4],esp
    mov esp,dword[SPT]

    mov dword[SPT],esp
    mov esp,dword[PRINTER+4]             ; esp = stack of target
    push func_printer
    pushfd
    pushad
    mov dword[PRINTER+4],esp
    mov esp,dword[SPT]
    
%endmacro

%macro init_cors 0
    mov dword[i],0
%%begin:
    mov ebx,dword[i]
    cmp ebx,dword[N]
    jge %%finish

    mov ecx,dword[CORS]
    mov edx,func_drone
    mov dword[ecx+8*ebx],edx

    push ecx
    push ebx
    push STKSIZE                         ; malloc STKSIZE bytes for cor_i stack
    call malloc
    add esp,4
    pop ebx
    pop ecx

    mov edx,dword[ARR_FOR_FREE]
    mov dword[edx+4*ebx],eax

    add eax,STKSIZE

    mov dword[SPT],esp
    mov esp,eax                          ; esp = stack of cor_i
    push func_drone
    pushfd
    pushad
    mov dword[ecx+8*ebx+4],esp
    mov esp,dword[SPT]


    inc dword[i]
    jmp %%begin
%%finish:
%endmacro


%macro init_lfsr_bits 0
    mov byte[b16], 0b00000001
    mov byte[b14], 0b00000100
    mov byte[b13], 0b00001000
    mov byte[b11], 0b00100000
%endmacro

%macro getBit 2
    and byte[%1],bl
    shr byte[%1],%2
%endmacro







main:
    push ebp
    mov ebp, esp

    convert_args                         ; use sscanf to initialize the parameters from args

    malloc_drones_array                  ; allocate memory for drones data and cors
    malloc_droneI_data                   ; allocate memory for drone_i data
    init_cors                            ; init drones cors
    init_target_printer_scheduler        ; init target,scheduler,printer cors
    call init_game                       ; initialize all the needed information to start the game

    mov ebx,SCHEDULER
    call do_resume                       ; START GAME

    mov esp, ebp
    pop ebp
    ret





    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INIT_GAME:::::::::::::::::::::::::::::::::::::::::::::::::::::::
init_game:
    push ebp
    mov ebp, esp

    call create_target

    mov dword[i_init],0
init_drone_i:
    mov ebx,dword[i_init]
    cmp ebx,dword[N]
    jge finish_init_drones

    mov ecx,dword[DRONES]
    mov eax,dword[ecx+4*ebx]             ; eax = pointer to drone_i data

                                         ; init id
    inc ebx
    mov dword[eax+ID],ebx
    dec ebx

    ; init x,y,speed
    mov dword[SCALE],100

    call generate_random                 ; generate x
    mov ecx,dword[random]
    mov dword[eax+co_X],ecx
    call generate_random                 ; generate y
    mov ecx,dword[random]
    mov dword[eax+co_Y],ecx
    call generate_random                 ; generate speed
    mov ecx,dword[random]
    mov dword[eax+speed],ecx

    ; init angle
    mov dword[SCALE],360

    call generate_random                 ; generate alpha
    mov ecx,dword[random]
    mov dword[eax+alpha],ecx

    ; init number of destroyed targets to zero
    mov dword[eax+destroyed],0

    inc dword[i_init]
    jmp init_drone_i


finish_init_drones:

    mov esp, ebp
    pop ebp
    ret



    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GENERATOR_RANDOM:::::::::::::::::::::::::::::::::::::::::::::::::::::::
generate_random:
    push ebp
    mov ebp, esp

    mov ebx,dword[seed]
    mov dword[random],ebx                ; get the current 'random' number
    call lfsr_func                       ; update the next 'random' number


    fld dword[random]                    ; push random to the fstack
    fdiv dword[MAXINT]                   ; divide by maxint and store in fstack
    fimul dword[SCALE]                   ; multiply by scale and store in fstack
    fstp dword[random]                   ; pop and copy the result to random


    mov esp, ebp
    pop ebp
    ret



    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;LFSR::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
lfsr_func:
    push ebp
    mov ebp, esp

    mov dword[i],0
start_lfsr_for:
    cmp dword[i],16
    jge end_lfsr_for

    init_lfsr_bits

    mov bx,word[seed]
    getBit b16,0
    getBit b14,2
    getBit b13,3
    getBit b11,5

    mov cl,byte[b16]
    xor cl,byte[b14]
    xor cl,byte[b13]
    xor cl,byte[b11]
    shl cl,7

    shr bx,1
    or bh,cl

    mov word[seed],bx

    inc dword[i]
    jmp start_lfsr_for

end_lfsr_for:

    mov esp, ebp
    pop ebp
    ret



    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;RESUME;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
resume:                                  ; save state of current co-routine
    pushfd                               ; push registers
    pushad                               ; push eflags
    mov edx, [CURR]
    mov[edx+SPP], esp                    ; save current esp
do_resume:                               ; load ESP for resumed co-routine
    mov esp, [ebx+SPP]                   ; CURR = the co-routine we want to go
    mov [CURR], ebx
    popad                                ; restore resumed co-routine state
    popfd
    ret                                  ; "return" to resumed co-routine





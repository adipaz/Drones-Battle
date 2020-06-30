
section .data
    global curr_i

    %define ID 0
    %define co_X 4
    %define co_Y 8
    %define alpha 12
    %define speed 16
    %define destroyed 20

    delta_alpha: dd 0
    delta_speed: dd 0
    curr_i: dd 0
    one_eighty:	dd 	180.0
    three_sixty: dd 360
    hundred: dd 100
    zero: dd 0
    sixty: dd 60
    ten: dd 10
    can_destroy: dd 0         ; 0 = false , 1 = true
    x_power: dd 0
    y_power: dd 0
    dist: dd 0



section .text
    align 16
    extern printf
    extern random
    extern DRONES
    extern SCALE
    extern TARGET
    extern SCHEDULER
    extern d
    extern generate_random
    global func_drone
    extern func_target
    extern x_target
    extern y_target
    extern resume
    extern CURR
    extern CORS
    extern create_target

func_drone:

    mov dword[SCALE],120
    call generate_random      ; Generate random heading change angle  ∆α in range [-60,60]
    fld dword[random]
    fisub dword[sixty]
    fstp dword[delta_alpha]

    mov dword[SCALE],20
    call generate_random      ; Generate random speed change ∆a in range [-10,10]
    fld dword[random]
    fisub dword[ten]
    fstp dword[delta_speed]

    mov ecx,dword[DRONES]
    mov ebx,dword[curr_i]
    mov eax,dword[ecx+ebx*4]  ; now eax = pointer to curr_i drone data
    call compute_new_position ; first move speed units at the direction defined by the current angle, wrapping around the torus if needed
    call compute_new_angle    ; then change the current angle to be α + ∆α, keeping the angle between [0, 360] by wraparound if needed
    call compute_new_speed    ; then change the current speed to be speed + ∆a, keeping the speed between [0, 100] by cutoff if needed

do_forever:
    call may_destroy
    cmp dword[can_destroy],0
    jz continue_drone
    inc dword[eax+destroyed]

    mov ebx,TARGET
    call resume

continue_drone:
    mov dword[SCALE],120
    call generate_random      ; Generate random heading change angle  ∆α in range [-60,60]
    fld dword[random]
    fisub dword[sixty]
    fstp dword[delta_alpha]

    mov dword[SCALE],20
    call generate_random      ; Generate random speed change ∆a in range [-10,10]
    fld dword[random]
    fisub dword[ten]
    fstp dword[delta_speed]

    mov ecx,dword[DRONES]
    mov ebx,dword[curr_i]
    mov eax,dword[ecx+ebx*4]  ; now eax = pointer to curr_i drone data
    call compute_new_position ; first move speed units at the direction defined by the current angle, wrapping around the torus if needed
    call compute_new_angle    ; then change the current angle to be α + ∆α, keeping the angle between [0, 360] by wraparound if needed
    call compute_new_speed    ; then change the current speed to be speed + ∆a, keeping the speed between [0, 100] by cutoff if needed

    mov ebx,SCHEDULER
    call resume

    jmp do_forever





    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;COMPUTE_NEW_POSITION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

compute_new_position:
    finit
    fld	dword [eax+alpha]
    fldpi                     ; Convert alpha into radians
    fmulp                     ; multiply by pi
    fld	dword [one_eighty]
    fdivp                     ; and divide by 180.0
    fsincos                   ; Compute vectors in y and x
    fld	dword [eax+speed]
    fmulp                     ; Multiply by distance to get dy
    fld	dword [eax+co_Y]
    faddp
    fstp dword [eax+co_Y]
    fld	dword [eax+speed]
    fmulp                     ; Multiply by distance to get dx
    fld	dword [eax+co_X]
    faddp
    fstp dword [eax+co_X]
if_x_too_big:
    fld dword[eax+co_X]
    fild  dword[hundred]
    fcomip
    jae if_x_too_small
    fld dword[eax+co_X]
    fisub dword[hundred]
    fstp dword [eax+co_X]
if_x_too_small:
    fld dword[eax+co_X]
    fild  dword[zero]
    fcomip
    jbe if_y_too_big
    fld dword[eax+co_X]
    fiadd dword[hundred]
    fstp dword [eax+co_X]
if_y_too_big:
    fld dword[eax+co_Y]
    fild  dword[hundred]
    fcomip
    jae if_y_too_small
    fld dword[eax+co_Y]
    fisub dword[hundred]
    fstp dword [eax+co_Y]
if_y_too_small:
    fld dword[eax+co_Y]
    fild  dword[zero]
    fcomip
    jbe finish_new_position
    fld dword[eax+co_Y]
    fiadd dword[hundred]
    fstp dword [eax+co_Y]
finish_new_position:
    ret



    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;COMPUTE_NEW_ANGLE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

compute_new_angle:
    mov dword[zero],0
    finit

    fld dword[delta_alpha]
    fadd dword[eax+alpha]
    fstp dword[eax+alpha]
if_alpha_too_big:
    fld dword[eax+alpha]
    fild dword[three_sixty]
    fcomip
    jae if_alpha_too_small
    fld dword[eax+alpha]
    fisub dword[three_sixty]
    fstp dword[eax+alpha]
if_alpha_too_small:
    fld dword[eax+alpha]
    fild dword[zero]
    fcomip
    jbe finish_new_alpha
    fld dword[eax+alpha]
    fiadd dword[three_sixty]
    fstp dword[eax+alpha]
finish_new_alpha:
    ret



    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;COMPUTE_NEW_SPEED;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

compute_new_speed:
    mov dword[zero],0
    finit

    fld dword[delta_speed]
    fadd dword[eax+speed]
    fstp dword[eax+speed]
if_speed_too_big:
    fld dword[eax+speed]
    fild dword[hundred]
    fcomip
    jae if_speed_too_small
    fild dword[hundred]
    fstp dword[eax+speed]
if_speed_too_small:
    fld dword[eax+speed]
    fild dword[zero]
    fcomip
    jbe finish_new_speed
    fild dword[zero]
    fstp dword[eax+speed]
finish_new_speed:
    ret



    ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAY_DESTROY;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

may_destroy:

    push ecx
    mov dword[can_destroy],0



    fld dword[eax+co_X]       ; push x to fstack
    fsub dword[x_target]      ; calculate x-xt and put at st(0)
    fst st1
    fmulp                     ; st(0) *= st(1)
    fstp dword[x_power]       ; x_power = (x-xt)^2

    fld dword[eax+co_Y]       ; push y to fstack
    fsub dword[y_target]      ; calculate y-yt and put at st(0)
    fst st1
    fmulp                     ; st(0) *= st(1)
    fstp dword[y_power]       ; y_power = (y-yt)^2



    fld dword[x_power]
    fadd dword[y_power]
    fsqrt
    fstp dword[dist]          ; dist = sqrt of (x-xt)^2 + (y-yt)^2


    fld dword[d]
    fld dword[dist]
    fcomip st0,st1
    ja finish_may_destroy     ; if dist > d_power
    mov dword[can_destroy],1
finish_may_destroy:
    pop ecx
    ret


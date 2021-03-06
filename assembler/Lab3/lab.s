        .arch   armv8-a
        .data
mes_N:
        .string "Enter N: "
        .equ    len_N, .-mes_N
mes1:
        .string "Filename for result: "
        .equ    len1, .-mes1
mes2:
        .string "Enter string (Use Ctrl+D to exit) : "
        .equ    len2, .-mes2
mes3:
        .string "File exists. Rewrite (y/n)? "
        .equ    len3, .-mes3
errmes1:
        .string "Usage: "
        .equ    errlen1, .-errmes1
errmes2:
        .string " filename\n"
        .equ    errlen2, .-errmes2
newline:
        .string "\n"
        .equ    len_nl, .-newline
choice:
        .skip   3
N:
        .skip   3
str:
        .skip   1024
        .align  3
mes_res:
        .ascii  "'"
newstr:
        .skip   1024
        .align  3
fd:
        .skip   8
        .text
        .align 2
        .global _start
        .type   _start, %function
_start:
        ldr     x0, [sp]
        cmp     x0, #2
        beq     2f
        mov     x0, #2
        adr     x1, errmes1
        mov     x2, errlen1
        mov     x8, #64
        svc     #0
        mov     x0, #2
        ldr     x1, [sp, #8]
        mov     x2, #0
0:
        ldrb    w3, [x1, x2]
        cbz     w3, 1f
        add     x2, x2, #1
        b       0b
1:
        mov     x8, #64
        svc     #0
        mov     x0, #2
        adr     x1, errmes2
        mov     x2, errlen2
        mov     x8, #64
        svc     #0
        mov     x0, #-1
        b       bad_exit
2:
        mov     x0, #1
        adr     x1, mes_N
        mov     x2, len_N
        mov     x8, #64
        svc     #0

        mov     x0, #0
        adr     x1, N
        mov     x2, #1023
        mov     x8, #63
        svc     #0
        cmp     x0, #1
        ble     E1
        b       E2
E1:
        bl      writeerr
        b       bad_exit
E2:
        adr     x1, N
        sub     x0, x0, #1
        strb    wzr, [x1, x0]
        ldrb    w20, [x1]
        mov     w10, '0'
        sub     w20, w20, w10
        cmp     w20, #0 // N < 0 ->in err
        ble     bad_exit

        mov     x0, #-100
        ldr     x1, [sp, #16]
        strb    wzr, [x1, x2]
        mov     x2, #0xc1
        mov     x3, #0600
        mov     x8, #56
        svc     #0

        cmp     x0, #0
        bge     save_fd
        cmp     x0, #-17
        bne     E3
        b       E4
E3:
        bl      writeerr
        b       bad_exit
E4:
        mov     x0, #1
        adr     x1, mes3
        mov     x2, len3
        mov     x8, #64
        svc     #0

        mov     x0, #0
        adr     x1, choice
        mov     x2, #3
        mov     x8, #63
        svc     #0

        cmp     x0, #2
        beq     read_answer
        b       bad_exit
read_answer:
        adr     x1, choice
        ldrb    w0, [x1]
        cmp     w0, 'Y'
        beq     answer_yes
        cmp     w0, 'y'
        beq     answer_yes
        mov     x0, #-17
        b       exit
answer_yes:
        mov     x0, #-100
        ldr     x1, [sp, #16]
        mov     x2, #0x201
        mov     x8, #56
        svc     #0
        cmp     x0, #0
        blt     bad_exit
save_fd:
        adr     x1, fd
        str     x0, [x1]
work:
        mov     x0, #1
        adr     x1, mes2
        mov     x2, len2
        mov     x8, #64
        svc     #0

        mov     x0, #0
        adr     x1, str
        mov     x2, #1023
        mov     x8, #63
        svc     #0

        cmp     x0, #0
        ble     L11
        adr     x1, str
        sub     x0, x0, #1
        strb    wzr, [x1, x0]
        adr     x3, newstr
        mov     x4, x3
L0:
        ldrb    w0, [x1], #1
        cbz     w0, L9
        cmp     w0, ' '
        beq     L0
        cmp     w0, '\t'
        beq     L0
        cmp     x4, x3
        beq     L1
        mov     w0, ' '
        strb    w0, [x3], #1
        b       L1
L1:
        sub     x2, x1, #1
        mov     x12, #0
L2:
        ldrb    w0, [x1], #1
        add     x12, x12, #1
        cbz     w0, L3
        cmp     w0, ' '
        beq     L3
        cmp     w0, '\t'
        bne     L2
L3:
        //sub     x5, x1, #1
        sub     x12, x12, #1
        mov     w21, #0
L4:
        cmp     w21, w20
        bge     L7
        add     w21, w21, #1
        //mov     x6, x5
        mov     x6, x2
        ldrb    w7, [x6, #0]! //-1
        mov     x10, #0 //x12
L5:
        cmp     x10, x12 // index < len
        bgt     L6
        ldrb    w0, [x6, #1]!
        strb    w0, [x2, x10, lsl #0]
        add     x10, x10, #1
        cmp     x10, x12
        bgt     L6
        b       L5
L6:
        strb    w7, [x2, x12, lsl #0]
        b L4
L7:
        add     x12, x12, #1
        sub     x1, x1, #1
        mov     x10, #0
L8:
        cmp     x10, x12
        bge     L0
        ldrb    w0, [x2, x10, lsl #0]
        strb    w0, [x3], #1
        add     x10, x10, #1
        b       L8
L9:
        mov     w0, '\''
        strb    w0, [x3], #1
        mov     w0, '\n'
        strb    w0, [x3], #1
output:
        adr     x0, fd
        ldr     x0, [x0]
        adr     x1, newstr
        adr     x1, mes_res
        sub     x2, x3, x1
        mov     x8, #64
        svc     #0
        b       work
L11:
        adr     x0, fd
        ldr     x0, [x0]
        mov     x8, #57
        svc     #0
        b       exit
bad_exit:
        mov     x0, #-1
exit:
        mov     x0, #1
        adr     x1, newline
        mov     x2, len_nl
        mov     x8, #64
        svc     #0

        mov     x0, #0
        mov     x8, #93
        svc     #0
        .size   _start, .-_start

        .type   writeerr, %function
        .data
permission:
        .string "Permission denied\n"
        .equ    permissionlen, .-permission
unknown:
        .string "Just error....\n"
        .equ    unknownlen, .-unknown
        .text
        .align  2
writeerr:
        cmp     x0, #-13
        bne     1f
        adr     x1, permission
        mov     x2, permissionlen
        b       2f
1:
        adr     x1, unknown
        mov     x2, unknownlen
2:
        mov     x0, #2
        mov     x8, #64
        svc     #0
        ret
        .size   writeerr, .-writeerr

.equ SYS_read,   63
.equ SYS_write,  64
.equ SYS_exit,   93
.equ STDIN_FD,    0
.equ STDOUT_FD,   1

.section .bss
    .align 4
buffer:         .skip 4096
num_buf:        .skip 32
frecuencias:    .skip 8000     // 1000 códigos * 8 bytes

.section .data
msg_titulo:     .asciz "=== Mini Cloud Log Analyzer ===\n"
msg_freq:       .asciz "Código más frecuente: "
msg_fin:        .asciz "\n"

.section .text
.global _start

_start:
    // Inicializar arreglo en 0
    adrp x1, frecuencias
    add x1, x1, :lo12:frecuencias
    mov x2, #0
    mov x3, #1000

init_loop:
    cmp x2, x3
    b.ge init_done
    str xzr, [x1, x2, lsl #3]
    add x2, x2, #1
    b init_loop

init_done:

    mov x22, #0   // numero_actual
    mov x23, #0   // flag digitos

leer_bloque:
    mov x0, #STDIN_FD
    adrp x1, buffer
    add x1, x1, :lo12:buffer
    mov x2, #4096
    mov x8, #SYS_read
    svc #0

    cmp x0, #0
    beq fin_lectura

    mov x24, #0
    mov x25, x0

procesar:
    cmp x24, x25
    b.ge leer_bloque

    adrp x1, buffer
    add x1, x1, :lo12:buffer
    ldrb w26, [x1, x24]
    add x24, x24, #1

    cmp w26, #10
    b.eq fin_numero

    cmp w26, #'0'
    b.lt procesar
    cmp w26, #'9'
    b.gt procesar

    mov x27, #10
    mul x22, x22, x27
    sub w26, w26, #'0'
    uxtw x26, w26
    add x22, x22, x26
    mov x23, #1
    b procesar

fin_numero:
    cbz x23, reset

    // incrementar frecuencia
    adrp x1, frecuencias
    add x1, x1, :lo12:frecuencias
    ldr x2, [x1, x22, lsl #3]
    add x2, x2, #1
    str x2, [x1, x22, lsl #3]

reset:
    mov x22, #0
    mov x23, #0
    b procesar

fin_lectura:
    cbz x23, buscar_max

    adrp x1, frecuencias
    add x1, x1, :lo12:frecuencias
    ldr x2, [x1, x22, lsl #3]
    add x2, x2, #1
    str x2, [x1, x22, lsl #3]

buscar_max:
    mov x3, #0    // max frecuencia
    mov x4, #0    // codigo
    mov x5, #0    // i

    adrp x1, frecuencias
    add x1, x1, :lo12:frecuencias

loop_max:
    cmp x5, #1000
    b.ge imprimir

    ldr x6, [x1, x5, lsl #3]
    cmp x6, x3
    b.le next

    mov x3, x6
    mov x4, x5

next:
    add x5, x5, #1
    b loop_max

imprimir:
    adrp x0, msg_titulo
    add x0, x0, :lo12:msg_titulo
    bl write_cstr

    adrp x0, msg_freq
    add x0, x0, :lo12:msg_freq
    bl write_cstr

    mov x0, x4
    bl print_uint

    adrp x0, msg_fin
    add x0, x0, :lo12:msg_fin
    bl write_cstr

    mov x0, #0
    mov x8, #SYS_exit
    svc #0

// ================= FUNCIONES =================

write_cstr:
    mov x9, x0
    mov x10, #0

len:
    ldrb w11, [x9, x10]
    cbz w11, done_len
    add x10, x10, #1
    b len

done_len:
    mov x1, x9
    mov x2, x10
    mov x0, #STDOUT_FD
    mov x8, #SYS_write
    svc #0
    ret

print_uint:
    cbnz x0, convert

    adrp x1, num_buf
    add x1, x1, :lo12:num_buf
    mov w2, #'0'
    strb w2, [x1]

    mov x0, #STDOUT_FD
    mov x2, #1
    mov x8, #SYS_write
    svc #0
    ret

convert:
    adrp x12, num_buf
    add x12, x12, :lo12:num_buf
    add x12, x12, #31

    mov x14, #10
    mov x15, #0

loop:
    udiv x16, x0, x14
    msub x17, x16, x14, x0
    add x17, x17, #'0'

    sub x12, x12, #1
    strb w17, [x12]
    add x15, x15, #1

    mov x0, x16
    cbnz x0, loop

    mov x1, x12
    mov x2, x15
    mov x0, #STDOUT_FD
    mov x8, #SYS_write
    svc #0
    ret

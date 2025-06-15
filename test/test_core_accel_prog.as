main:
        addi    sp,sp,1024
addi    sp,sp,1024
addi    sp,sp,1024
        sw      ra,28(sp)
        sw      s0,24(sp)
.word 0x0000203b
        addi    s0,sp,32
.word 0x0000103b
        sw      zero,-20(s0)
        li      a1,5
        li      a0,12
        call    abs_diff
        mv      a4,a0
        li      a5,7
        bne     a4,a5,.L69
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L69:
        li      a1,11
.word 0x0000103b
.word 0x0000203b
        li      a0,13
        call    logical_ops
        mv      a4,a0
        li      a5,15
        bne     a4,a5,.L70
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L70:
        li      a1,5
        li      a0,3
.word 0x0000203b
        call    compare
        mv      a4,a0
.word 0x0000003b
        li      a5,3
        bne     a4,a5,.L71
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L71:
        li      a1,4
        li      a0,10
        call    add_loop
        mv      a4,a0
        li      a5,34
        bne     a4,a5,.L72
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L72:
        li      a0,2
        call    control_flow
        mv      a4,a0
        li      a5,333
        bne     a4,a5,.L73
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.word 0x0000103b
.L73:
        li      a1,7
.word 0x0000103b
        li      a0,-3
        call    mul_emulated
        mv      a4,a0
        li      a5,-21
        bne     a4,a5,.L74
        lw      a5,-20(s0)
.word 0x0000203b
        addi    a5,a5,1
        sw      a5,-20(s0)
.L74:
        li      a5,324509696
        addi    a0,a5,-1057
        call    shift_torture
        mv      a4,a0
        li      a5,767258624
        addi    a5,a5,309
        bne     a4,a5,.L75
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L75:
        li      a5,-38178816
        addi    a0,a5,1330
        call    shift_torture
        mv      a4,a0
        li      a5,535883776
        addi    a5,a5,-1868
        bne     a4,a5,.L76
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L76:
        li      a5,8192
        addi    a1,a5,-1403
        li      a5,-12288
        addi    a0,a5,-57
        call    mul_shift_add
        mv      a4,a0
        li      a5,-83808256
.word 0x0000003b
        addi    a5,a5,-1949
        bne     a4,a5,.L77
        lw      a5,-20(s0)
.word 0x0000203b
        addi    a5,a5,1
        sw      a5,-20(s0)
.L77:
        li      a0,10
        call    factorial_rec
.word 0x0000003b
        mv      a4,a0
        li      a5,3629056
        addi    a5,a5,-256
        bne     a4,a5,.L78
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L78:
        call    char_sign_ext_test
        mv      a4,a0
        li      a5,-50
        bne     a4,a5,.L79
.word 0x0000203b
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L79:
        call    carry_stress
        mv      a4,a0
        li      a5,80871424
        addi    a5,a5,-1234
        bne     a4,a5,.L80
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L80:
.word 0x0000003b
        call    accel_test
        mv      a4,a0
        lw      a5,-20(s0)
        add     a5,a5,a4
        sw      a5,-20(s0)
.L81:
        j       .L81
mul_shift_add:
        addi    sp,sp,-48
.word 0x0000103b
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        sw      a1,-40(s0)
        sw      zero,-20(s0)
        lw      a5,-36(s0)
        bge     a5,zero,.L2
        lw      a5,-36(s0)
        neg     a5,a5
        sw      a5,-36(s0)
        lw      a5,-20(s0)
.word 0x0000203b
        xori    a5,a5,1
        sw      a5,-20(s0)
.L2:
        lw      a5,-40(s0)
        bge     a5,zero,.L3
        lw      a5,-40(s0)
.word 0x0000003b
        neg     a5,a5
        sw      a5,-40(s0)
        lw      a5,-20(s0)
        xori    a5,a5,1
.word 0x0000203b
        sw      a5,-20(s0)
.L3:
        sw      zero,-24(s0)
.word 0x0000203b
        j       .L4
.L6:
        lw      a5,-40(s0)
        andi    a5,a5,1
        beq     a5,zero,.L5
        lw      a4,-24(s0)
        lw      a5,-36(s0)
        add     a5,a4,a5
        sw      a5,-24(s0)
.L5:
        lw      a5,-36(s0)
        slli    a5,a5,1
        sw      a5,-36(s0)
        lw      a5,-40(s0)
        srai    a5,a5,1
        sw      a5,-40(s0)
.L4:
        lw      a5,-40(s0)
.word 0x0000203b
.word 0x0000203b
        bne     a5,zero,.L6
        lw      a5,-20(s0)
        beq     a5,zero,.L7
        lw      a5,-24(s0)
        neg     a5,a5
        j       .L9
.word 0x0000003b
.L7:
        lw      a5,-24(s0)
.word 0x0000103b
.L9:
        mv      a0,a5
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra
factorial_rec:
        addi    sp,sp,-32
        sw      ra,28(sp)
.word 0x0000203b
        sw      s0,24(sp)
        addi    s0,sp,32
.word 0x0000003b
        sw      a0,-20(s0)
        lw      a4,-20(s0)
        li      a5,1
        bgt     a4,a5,.L11
        li      a5,1
        j       .L12
.L11:
        lw      a5,-20(s0)
.word 0x0000103b
        addi    a5,a5,-1
        mv      a0,a5
.word 0x0000103b
        call    factorial_rec
        mv      a5,a0
        mv      a1,a5
        lw      a0,-20(s0)
        call    mul_shift_add
        mv      a5,a0
.L12:
.word 0x0000103b
        mv      a0,a5
        lw      ra,28(sp)
        lw      s0,24(sp)
        addi    sp,sp,32
        jr      ra
.word 0x0000003b
shift_torture:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        lw      a5,-36(s0)
        sw      a5,-28(s0)
        sw      zero,-20(s0)
.word 0x0000003b
        sw      zero,-24(s0)
        j       .L14
.L15:
        lw      a5,-24(s0)
        lw      a4,-28(s0)
        sll     a5,a4,a5
        mv      a4,a5
.word 0x0000003b
.word 0x0000103b
        lw      a5,-20(s0)
        xor     a5,a5,a4
.word 0x0000203b
        sw      a5,-20(s0)
        lw      a5,-24(s0)
        lw      a4,-28(s0)
        srl     a5,a4,a5
        mv      a4,a5
.word 0x0000003b
.word 0x0000003b
        lw      a5,-20(s0)
        add     a5,a5,a4
        sw      a5,-20(s0)
        lw      a5,-24(s0)
        lw      a4,-36(s0)
        sra     a5,a4,a5
        lw      a4,-20(s0)
        xor     a5,a4,a5
        sw      a5,-20(s0)
        lw      a5,-24(s0)
        addi    a5,a5,1
        sw      a5,-24(s0)
.L14:
.word 0x0000203b
        lw      a4,-24(s0)
        li      a5,31
        ble     a4,a5,.L15
.word 0x0000003b
        lw      a5,-20(s0)
        mv      a0,a5
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra
char_sign_ext_test:
        addi    sp,sp,-128
        sw      ra,124(sp)
        sw      s0,120(sp)
        addi    s0,sp,128
        sw      zero,-20(s0)
        j       .L18
.L19:
        lw      a5,-20(s0)
        andi    a5,a5,0xff
        addi    a5,a5,-50
        andi    a5,a5,0xff
        slli    a4,a5,24
        srai    a4,a4,24
        lw      a5,-20(s0)
        addi    a5,a5,-16
        add     a5,a5,s0
        sb      a4,-112(a5)
        lw      a5,-20(s0)
        addi    a5,a5,1
.word 0x0000203b
        sw      a5,-20(s0)
.word 0x0000003b
.L18:
        lw      a4,-20(s0)
        li      a5,99
        ble     a4,a5,.L19
        sw      zero,-24(s0)
        sw      zero,-28(s0)
        j       .L20
.L21:
        lw      a5,-28(s0)
        addi    a5,a5,-16
.word 0x0000203b
        add     a5,a5,s0
        lb      a5,-112(a5)
        mv      a4,a5
        lw      a5,-24(s0)
        add     a5,a5,a4
        sw      a5,-24(s0)
.word 0x0000203b
        lw      a5,-28(s0)
.word 0x0000003b
        addi    a5,a5,1
        sw      a5,-28(s0)
.L20:
        lw      a4,-28(s0)
        li      a5,99
        ble     a4,a5,.L21
        lw      a5,-24(s0)
        mv      a0,a5
        lw      ra,124(sp)
        lw      s0,120(sp)
        addi    sp,sp,128
.word 0x0000203b
        jr      ra
carry_stress:
        addi    sp,sp,-32
        sw      ra,28(sp)
.word 0x0000003b
.word 0x0000003b
        sw      s0,24(sp)
        addi    s0,sp,32
        sw      zero,-20(s0)
        sw      zero,-24(s0)
        j       .L24
.L25:
        lw      a4,-20(s0)
        li      a5,65536
        addi    a5,a5,-1
.word 0x0000003b
        add     a5,a4,a5
        sw      a5,-20(s0)
        lw      a5,-24(s0)
        addi    a5,a5,1
        sw      a5,-24(s0)
.L24:
.word 0x0000103b
        lw      a4,-24(s0)
        li      a5,1233
        ble     a4,a5,.L25
        lw      a5,-20(s0)
        mv      a0,a5
        lw      ra,28(sp)
        lw      s0,24(sp)
        addi    sp,sp,32
        jr      ra
abs_diff:
        addi    sp,sp,-32
        sw      ra,28(sp)
        sw      s0,24(sp)
        addi    s0,sp,32
        sw      a0,-20(s0)
        sw      a1,-24(s0)
        lw      a4,-20(s0)
.word 0x0000003b
        lw      a5,-24(s0)
.word 0x0000103b
        ble     a4,a5,.L28
.word 0x0000103b
        lw      a4,-20(s0)
        lw      a5,-24(s0)
        sub     a5,a4,a5
.word 0x0000103b
        j       .L30
.L28:
.word 0x0000203b
        lw      a4,-24(s0)
        lw      a5,-20(s0)
        sub     a5,a4,a5
.L30:
        mv      a0,a5
        lw      ra,28(sp)
        lw      s0,24(sp)
        addi    sp,sp,32
.word 0x0000003b
.word 0x0000203b
.word 0x0000103b
        jr      ra
logical_ops:
        addi    sp,sp,-32
        sw      ra,28(sp)
        sw      s0,24(sp)
        addi    s0,sp,32
        sw      a0,-20(s0)
        sw      a1,-24(s0)
        lw      a4,-20(s0)
        lw      a5,-24(s0)
        or      a5,a4,a5
        mv      a0,a5
        lw      ra,28(sp)
        lw      s0,24(sp)
        addi    sp,sp,32
        jr      ra
shift_ops:
.word 0x0000003b
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        lw      a5,-36(s0)
        slli    a5,a5,2
        sw      a5,-20(s0)
        lw      a5,-36(s0)
        srli    a5,a5,2
.word 0x0000103b
        sw      a5,-24(s0)
        lw      a5,-36(s0)
        srai    a5,a5,2
        sw      a5,-28(s0)
        lw      a4,-20(s0)
.word 0x0000203b
        lw      a5,-24(s0)
        add     a4,a4,a5
        lw      a5,-28(s0)
        add     a5,a4,a5
        mv      a0,a5
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra
compare:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        sw      a1,-40(s0)
        lw      a4,-36(s0)
.word 0x0000203b
        lw      a5,-40(s0)
        slt     a5,a4,a5
        andi    a5,a5,0xff
        sw      a5,-20(s0)
        lw      a4,-36(s0)
        lw      a5,-40(s0)
        sltu    a5,a4,a5
.word 0x0000203b
        andi    a5,a5,0xff
        sw      a5,-24(s0)
        lw      a5,-20(s0)
.word 0x0000203b
        slli    a4,a5,1
        lw      a5,-24(s0)
        or      a5,a4,a5
        mv      a0,a5
        lw      ra,44(sp)
        lw      s0,40(sp)
.word 0x0000203b
        addi    sp,sp,48
        jr      ra
add_loop:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        sw      a1,-40(s0)
        sw      zero,-20(s0)
        sw      zero,-24(s0)
        j       .L38
.L39:
        lw      a4,-20(s0)
        lw      a5,-36(s0)
        add     a5,a4,a5
.word 0x0000003b
        sw      a5,-20(s0)
.word 0x0000203b
        lw      a5,-36(s0)
        addi    a5,a5,-1
        sw      a5,-36(s0)
        lw      a5,-24(s0)
        addi    a5,a5,1
        sw      a5,-24(s0)
.L38:
.word 0x0000103b
        lw      a4,-24(s0)
        lw      a5,-40(s0)
.word 0x0000003b
        blt     a4,a5,.L39
        lw      a5,-20(s0)
        mv      a0,a5
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra
nested_logic:
        addi    sp,sp,-48
        sw      ra,44(sp)
.word 0x0000103b
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        li      a5,1
        sw      a5,-20(s0)
.word 0x0000203b
        sw      zero,-24(s0)
        j       .L42
.L45:
        lw      a4,-36(s0)
        lw      a5,-24(s0)
        xor     a5,a4,a5
        andi    a5,a5,1
        beq     a5,zero,.L43
.word 0x0000203b
        lw      a5,-20(s0)
        slli    a5,a5,1
.word 0x0000203b
        sw      a5,-20(s0)
        j       .L44
.word 0x0000103b
.L43:
        lw      a5,-24(s0)
        lw      a4,-36(s0)
        sra     a5,a4,a5
        lw      a4,-20(s0)
        xor     a5,a4,a5
        sw      a5,-20(s0)
.L44:
.word 0x0000103b
        lw      a5,-24(s0)
        addi    a5,a5,1
.word 0x0000003b
        sw      a5,-24(s0)
.L42:
        lw      a4,-24(s0)
.word 0x0000003b
        li      a5,7
        ble     a4,a5,.L45
        lw      a5,-20(s0)
        mv      a0,a5
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra
control_flow:
        addi    sp,sp,-32
        sw      ra,28(sp)
        sw      s0,24(sp)
        addi    s0,sp,32
        sw      a0,-20(s0)
        lw      a4,-20(s0)
        li      a5,2
        beq     a4,a5,.L48
        lw      a4,-20(s0)
        li      a5,2
        bgt     a4,a5,.L49
        lw      a5,-20(s0)
        beq     a5,zero,.L50
.word 0x0000203b
        lw      a4,-20(s0)
        li      a5,1
.word 0x0000003b
        beq     a4,a5,.L51
        j       .L49
.L50:
        li      a5,111
        j       .L52
.L51:
        li      a5,222
        j       .L52
.word 0x0000003b
.L48:
.word 0x0000003b
        li      a5,333
        j       .L52
.L49:
        li      a5,444
.L52:
.word 0x0000003b
        mv      a0,a5
.word 0x0000003b
        lw      ra,28(sp)
        lw      s0,24(sp)
.word 0x0000103b
        addi    sp,sp,32
        jr      ra
sign_test:
        addi    sp,sp,-48
        sw      ra,44(sp)
.word 0x0000003b
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
.word 0x0000003b
        sw      a1,-40(s0)
        lw      a4,-36(s0)
        lw      a5,-40(s0)
        sub     a5,a4,a5
        sw      a5,-20(s0)
        lw      a5,-20(s0)
        srai    a5,a5,3
        sw      a5,-24(s0)
        lw      a4,-36(s0)
        lw      a5,-40(s0)
        add     a4,a4,a5
        lw      a5,-24(s0)
        xor     a5,a4,a5
        mv      a0,a5
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
.word 0x0000203b
        jr      ra
mul_emulated:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        sw      a1,-40(s0)
        sw      zero,-20(s0)
        sw      zero,-24(s0)
        lw      a5,-36(s0)
        bge     a5,zero,.L56
        lw      a5,-36(s0)
        neg     a5,a5
        sw      a5,-36(s0)
        lw      a5,-24(s0)
.word 0x0000203b
        xori    a5,a5,1
        sw      a5,-24(s0)
.L56:
        lw      a5,-40(s0)
        bge     a5,zero,.L58
        lw      a5,-40(s0)
        neg     a5,a5
        sw      a5,-40(s0)
        lw      a5,-24(s0)
        xori    a5,a5,1
        sw      a5,-24(s0)
.word 0x0000103b
        j       .L58
.L59:
        lw      a4,-20(s0)
        lw      a5,-36(s0)
        add     a5,a4,a5
        sw      a5,-20(s0)
        lw      a5,-40(s0)
        addi    a5,a5,-1
        sw      a5,-40(s0)
.L58:
        lw      a5,-40(s0)
        bgt     a5,zero,.L59
.word 0x0000003b
        lw      a5,-24(s0)
        beq     a5,zero,.L60
        lw      a5,-20(s0)
        neg     a5,a5
        j       .L62
.word 0x0000103b
.L60:
.word 0x0000203b
        lw      a5,-20(s0)
.L62:
        mv      a0,a5
        lw      ra,44(sp)
.word 0x0000103b
        lw      s0,40(sp)
.word 0x0000003b
        addi    sp,sp,48
        jr      ra
LOAD_KEY0:
        addi    sp,sp,-16
        sw      ra,12(sp)
        sw      s0,8(sp)
        addi    s0,sp,16
        li x28, 0
li x29, 0
li x30, 0
li x31, 0
.word 0x0000003b
        mv      a0,a5
        lw      ra,12(sp)
        lw      s0,8(sp)
        addi    sp,sp,16
        jr      ra
accel_test:
        addi    sp,sp,-32
        sw      ra,28(sp)
.word 0x0000203b
.word 0x0000103b
        sw      s0,24(sp)
        addi    s0,sp,32
        call    LOAD_KEY0
        li      a5,11
        sw      a5,-32(s0)
.word 0x0000103b
        li      a5,11
        sw      a5,-28(s0)
        li      a5,11
        sw      a5,-24(s0)
        li      a5,11
        sw      a5,-20(s0)
.word 0x0000103b
        lw x28, 0-32(s0)
lw x29, 4-32(s0)
lw x30, 8-32(s0)
lw x31, 12-32(s0)
.word 0x0000103b
sw x28, 0-32(s0)
sw x29, 4-32(s0)
sw x30, 8-32(s0)
sw x31, 12-32(s0)
.word 0x0000103b

        lw      a4,-20(s0)
        li      a5,977686528
        addi    a5,a5,-1968
        bne     a4,a5,.L65
.word 0x0000203b
        lw      a4,-24(s0)
.word 0x0000103b
.word 0x0000203b
        li      a5,1777897472
.word 0x0000203b
        addi    a5,a5,-1179
        bne     a4,a5,.L65
        lw      a4,-28(s0)
        li      a5,1841602560
        addi    a5,a5,-2044
        bne     a4,a5,.L65
        lw      a4,-32(s0)
        li      a5,1437786112
        addi    a5,a5,980
        bne     a4,a5,.L65
        li      a5,1
        j       .L67
.L65:
.word 0x0000203b
        li      a5,0
.L67:
        mv      a0,a5
        lw      ra,28(sp)
.word 0x0000003b
        lw      s0,24(sp)
        addi    sp,sp,32
        jr      ra


/* ----------------  RV32‑I   torture test  ---------------- */

int mul_shift_add(int a, int b)          /* software MUL */
{
    int neg = 0;
    if (a < 0) { a = -a; neg ^= 1; }
    if (b < 0) { b = -b; neg ^= 1; }

    int prod = 0;
    while (b) {
        if (b & 1) prod += a;
        a <<= 1;
        b >>= 1;
    }
    return neg ? -prod : prod;
}

int factorial_rec(int n)                /* deep call / stack use */
{
    if (n <= 1) return 1;
    return mul_shift_add(n, factorial_rec(n - 1));
}

/* drives every shift‑amount 0‑31 (left, LSR, ASR) */
int shift_torture(int x)
{
    unsigned int ux = (unsigned int)x;  /* well‑defined shifts */
    int acc = 0;
    for (int i = 0; i < 32; i++) {
        acc ^= (int)(ux << i);          /* SLL  */
        acc += (int)(ux >> i);          /* SRL  */
        acc ^= (x >> i);                /* SRA  */
    }
    return acc;
}

int char_sign_ext_test(void)            /* LB / sign‑extend */
{
    signed char buf[100];
    for (int i = 0; i < 100; i++)
        buf[i] = (signed char)(i - 50); /* −50 … +49 */

    int s = 0;
    for (int i = 0; i < 100; i++)
        s += buf[i];
    return s;                           /* = −50 */
}

int carry_stress(void)                  /* 16‑bit carry propagation */
{
    int sum = 0;
    for (int i = 0; i < 1234; i++)
        sum += 0xFFFF;                  /* many low‑half carries */
    return sum;                         /* = 80 870 190 */
}
int abs_diff(int a, int b) {
    return (a > b) ? (a - b) : (b - a);
}

int logical_ops(int a, int b) {
    return (a & b) | (a ^ b);
}

int shift_ops(int a) {
    int sll = a << 2;
    int srl = ((unsigned int)a) >> 2;
    int sra = a >> 2;
    return sll + srl + sra;
}

int compare(int a, int b) {
    int slt = (a < b);
    int sltu = ((unsigned int)a < (unsigned int)b);
    return (slt << 1) | sltu;
}

int add_loop(int base, int count) {
    int sum = 0;
    for (int i = 0; i < count; i++) {
        sum += base;
        base -= 1;
    }
    return sum;
}

int nested_logic(int x) {
    int val = 1;
    for (int i = 0; i < 8; i++) {
        if ((x ^ i) & 1)
            val <<= 1;
        else
            val ^= (x >> i);
    }
    return val;
}

int control_flow(int x) {
    switch (x) {
        case 0: return 111;
        case 1: return 222;
        case 2: return 333;
        default: return 444;
    }
}

int sign_test(int a, int b) {
    int diff = a - b;
    int shifted = diff >> 3;
    return shifted ^ (a + b);
}

int mul_emulated(int a, int b) {
    int prod = 0;
    int neg = 0;
    if (a < 0) { a = -a; neg ^= 1; }
    if (b < 0) { b = -b; neg ^= 1; }
    while (b > 0) {
        prod += a;
        b--;
    }
    return neg ? -prod : prod;
}

static inline int LOAD_KEY0() {
    asm volatile (
        "li x28, 0\n"
        "li x29, 0\n"
        "li x30, 0\n"
        "li x31, 0\n"
        ".word 0x0000003b\n"
        : 
        :
        : "x28", "x29", "x30", "x31"
    );
}

int accel_test() {
    int block[4];
    LOAD_KEY0();
    block[0]= 0x0000000b;
    block[1]= 0x0000000b;
    block[2]= 0x0000000b;
    block[3]= 0x0000000b;
    asm volatile (
        "lw x28, 0%0\n"
        "lw x29, 4%0\n"
        "lw x30, 8%0\n"
        "lw x31, 12%0\n"
        ".word 0x0000103b\n"
        "sw x28, 0%0\n"
        "sw x29, 4%0\n"
        "sw x30, 8%0\n"
        "sw x31, 12%0\n"
        : 
        : "m" (block)
        : "x28", "x29", "x30", "x31", "memory"
    );
    return (
        (block[3] == 0x3a464850) &&
        (block[2] == 0x69f88b65) &&
        (block[1] == 0x6dc49804) &&
        (block[0] == 0x55b2e3d4)
    );

}

/* ---------------------------------------------------------- */

int main(void)
{
    int pass = 0;                       
    if (abs_diff(12, 5) == 7) pass += 1;
    if (logical_ops(13, 11) == ((13 & 11) | (13 ^ 11))) pass +=1;
    if (compare(3, 5) == 3) pass += 1;
    if (add_loop(10, 4) == (10 + 9 + 8 + 7)) pass += 1;
    if (control_flow(2) == 333) pass += 1;
    if (mul_emulated(-3, 7) == -21) pass += 1;
    
    if (shift_torture(0x13579BDF) ==  767258933) pass += 1;
    if (shift_torture(-0x02468ACE) == 535881908) pass += 1;

    if (mul_shift_add(-12345, 6789) ==  -83810205) pass += 1;
    if (factorial_rec(10)           ==    3628800) pass += 1;

    if (char_sign_ext_test()        ==        -50) pass += 1;
    if (carry_stress()              ==   80870190) pass += 1;
    pass += accel_test();

       while (1);
}


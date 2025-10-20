
#define _ACCEL_LOAD_KEY() __asm__(".word 0x0000003b")
#define _ACCEL_ST_ENC()   __asm__(".word 0x0000103b")
#define _ACCEL_ST_DEC()   __asm__(".word 0x0000203b")
#define _ACCEL_SYNC()     __asm__(".word 0x0000403b")

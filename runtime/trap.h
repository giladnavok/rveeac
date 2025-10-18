
#define _DISABLE_INTERRUPTS() __asm__("csrci mstatus, 8")
#define _ENABLE_INTERRUPTS() __asm__("csrsi mstatus, 8")
#define _CLEAR_MIP_MEI() __asm__("li t0, 1<<11\ncsrc mip, t0")
#define _WAIT_FOR_INTERRUPT() __asm__("wfi")




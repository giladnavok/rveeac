
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <reent.h>

volatile char* SIM_UART_TX = (char*)0x10000000;

int _write(int fd, const void* buf, unsigned len) {
	const char* p = (const char*)buf;
	(void)fd;
	for (unsigned i = 0;i < len; i++) {
		*SIM_UART_TX = p[i];
	}
	return (int)len;
}

_ssize_t _write_r(struct _reent *r, int fd, const void* buf, size_t len) {
	(void)r;
	return _write(fd, buf, len);
}
int _close_r(struct _reent *r, int fd)            { (void)r; (void)fd; return 0; }
_off_t _lseek_r(struct _reent *r, int fd, _off_t o, int w){ (void)r;(void)fd;(void)w; return o; }
int _read_r(struct _reent *r, int fd, void *p, size_t l){ (void)r;(void)fd;(void)p;(void)l; return 0; }
int _fstat_r(struct _reent *r, int fd, struct stat *st) {
    (void)r; (void)fd;
    st->st_mode = S_IFCHR;   // treat as character device
    return 0;
}

int _isatty_r(struct _reent *r, int fd) { (void)r; (void)fd; return 1; }

caddr_t _sbrk(int incr) {
	extern char __heap_start__, __heap_end__;
	static char* brk = &__heap_start__;
	char* prev = brk;
	if (brk + incr <= &__heap_end__) {
		brk += incr;
		return (caddr_t)prev;
	}
	errno = ENOMEM; return (caddr_t)-1;
}

int _close(int) {return -1;}
int _fstat(int fd, struct stat* st) {(void)fd; st->st_mode = S_IFCHR; return 0;}
int _isatty(int fd) {(void)fd; return 1;}
int _lseek(int, int, int) {return -1;}
int _read(int, void*, unsigned) {return 0;}
void _exit(int) {for(;;){}}


#include <libs/vsprintf.h>
#include <driver/vgatext.h>

static void console_write(const char *cstr)
{
    while (*cstr) {
          ConsolePutChar(*cstr++);
    }
}

void printk(const char *format, ...)
{
	// 避免频繁创建临时变量，内核的栈很宝贵
	static char buff[10240];
	va_list args;
	int i;

	va_start(args, format);
	i = vsprintf(buff, format, args);
	va_end(args);

	buff[i] = '\0';

	console_write(buff);
}

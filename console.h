#ifndef _CONSOLE_H_
#define _CONSOLE_H_

#include "types.h"

typedef __builtin_va_list va_list;

#define va_start(ap, last)         (__builtin_va_start(ap, last))
#define va_arg(ap, type)           (__builtin_va_arg(ap, type))
#define va_end(ap) 

typedef enum real_color_t {
    rc_black = 0,
    rc_blue = 1,
    rc_green = 2,
    rc_cyan = 3,
    rc_red = 4,
    rc_magenta = 5,
    rc_brown = 6,
    rc_light_grey = 7,
    rc_dark_grey = 8,
    rc_light_blue = 9,
    rc_light_green = 10,
    rc_light_cyan = 11,
    rc_light_red = 12,
    rc_light_magenta = 13,
    rc_light_brown  = 14,   // yellow
    rc_white = 15
} real_color_t;

void printk(const char *, ...);
void cprintk(real_color_t, real_color_t, const char *, ...);

// 清屏操作
void console_clear();

// 屏幕输出一个字符  带颜色
void console_putc_color(char c, real_color_t back, real_color_t fore);

// 屏幕打印一个以 \0 结尾的字符串  默认黑底白字
void console_write(const char *);

// 屏幕打印一个以 \0 结尾的字符串  带颜色
void console_write_color(const char *, real_color_t, real_color_t);

// 屏幕输出一个十六进制的整型数
void console_write_hex(uint32_t, real_color_t, real_color_t);

// 屏幕输出一个十进制的整型数
void console_write_dec(uint32_t, real_color_t, real_color_t);

#endif

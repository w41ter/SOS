#include <x86.h>
#include <mm/mm.h>
#include <driver/vgatext.h>

// VGA 的显示缓冲的起点是 0xB8000
static uint16_t *VideoMemory = (uint16_t *)(KERNEL_BASE + 0xB8000);

// 屏幕"光标"的坐标
static uint8_t CursorX = 0;
static uint8_t CursorY = 0;

static void MoveCursor(void)
{
    // 屏幕是 80 字节宽
    uint16_t cursorLocation = CursorY * 80 + CursorX;
    
    // 在这里用到的两个内部寄存器的编号为14与15，分别表示光标位置
    // 的高8位与低8位。

    outb(0x3D4, 14);                    // 告诉 VGA 我们要设置光标的高字节
    outb(0x3D5, cursorLocation >> 8);   // 发送高 8 位
    outb(0x3D4, 15);                    // 告诉 VGA 我们要设置光标的低字节
    outb(0x3D5, cursorLocation);        // 发送低 8 位
}

static void Scroll()
{
    // attribute_byte 被构造出一个黑底白字的描述格式
    uint8_t attribute_byte = (0 << 4) | (15 & 0x0F);
    uint16_t blank = 0x20 | (attribute_byte << 8);  // space 是 0x20

    // CursorY 到 25 的时候，就该换行了
    if (CursorY >= 25) {
        // 将所有行的显示数据复制到上一行，第一行永远消失了...
        for (int i = 0 * 80; i < 24 * 80; i++) 
              VideoMemory[i] = VideoMemory[i+80];

        // 最后的一行数据现在填充空格，不显示任何字符
        for (int i = 24 * 80; i < 25 * 80; i++) 
              VideoMemory[i] = blank;
        
        // 向上移动了一行，所以 CursorY 现在是 24
        CursorY = 24;
    }
}

void ConsolePutCharWithColor(char c, 
	ConsoleColor back, ConsoleColor fore)
{
    uint8_t back_color = (uint8_t)back;
    uint8_t fore_color = (uint8_t)fore;

    uint8_t attribute_byte = (back_color << 4) | (fore_color & 0x0F);
    uint16_t attribute = attribute_byte << 8;

    // 0x08 是退格键的 ASCII 码
    // 0x09 是tab 键的 ASCII 码
    if (c == 0x08 && CursorX) {
          CursorX--;
    } else if (c == 0x09) {
          CursorX = (CursorX+8) & ~(8-1);
    } else if (c == '\r') {
          CursorX = 0;
    } else if (c == '\n') {
        CursorX = 0;
        CursorY++;
    } else if (c >= ' ') {
        VideoMemory[CursorY*80 + CursorX] = c | attribute;
        CursorX++;
    }

    // 每 80 个字符一行，满80就必须换行了
    if (CursorX >= 80) {
        CursorX = 0;
        CursorY ++;
    }

    // 如果需要的话滚动屏幕显示
    Scroll();

    // 移动硬件的输入光标
    MoveCursor();
}

void ConsolePutChar(char c)
{
    ConsolePutCharWithColor(c, CC_Black, CC_White);
}

void ConsoleClear(void)
{
    uint8_t attribute_byte = (0 << 4) | (15 & 0x0F);
    uint16_t blank = 0x20 | (attribute_byte << 8);

    for (int i = 0; i < 80 * 25; i++) 
          VideoMemory[i] = blank;

    CursorX = 0;
    CursorY = 0;
    MoveCursor();
}

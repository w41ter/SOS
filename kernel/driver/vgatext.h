#pragma once

typedef enum ConsoleColor {
    CC_Black = 0,
    CC_Blue = 1,
    CC_Green = 2,
    CC_Cyan = 3,
    CC_Red = 4,
    CC_Magenta = 5,
    CC_Brown = 6,
    CC_LightGray = 7,
    CC_DarkGrey = 8,
    CC_LightBlue = 9,
    CC_LightGreen = 10,
    CC_LightCyan = 11,
    CC_LightRed = 12,
    CC_LightMagenta = 13,
    CC_LightBrown = 14, // yellow
    CC_White = 15,
} ConsoleColor;

void ConsoleClear(void);
void ConsolePutChar(char);
void ConsolePutCharWithColor(char, ConsoleColor, ConsoleColor);
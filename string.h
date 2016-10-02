#ifndef _STRING_H_
#define _STRING_H_

#include "types.h"

int memcmp(const void * buf1, const void * buf2, uint32_t count);
void *memcpy(void *dest, const void *src, uint32_t count);
void *memmove(void *dest, const void *src, uint32_t count);
void memset(void *dest, uint8_t val, uint32_t len);
void bzero(void *dest, uint32_t len);
int strcmp(const char *str1, const char *str2);
char *strcpy(char *dest, const char *src);
char *strcat(char *dest, const char *src);
int strlen(const char *src);

#endif  // _STRING_H_
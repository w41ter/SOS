#include "types.h"

int memcmp(const void * buf1, const void * buf2, uint32_t count) 
{ 
    if (!count) 
        return(0); 
 
    while (--count && *(char *)buf1 == *(char *)buf2) { 
        buf1 = (char *)buf1 + 1; 
        buf2 = (char *)buf2 + 1; 
    } 
 
    return(*((unsigned char *)buf1) - *((unsigned char *)buf2));
} 

void *memcpy(void *dest, const void *src, uint32_t count)
{
    char *tmp = dest;
    const char *s = src;
    while (count--)
        *tmp++ = *s++;
    return dest;
}

void *memmove(void *dest, const void *src, uint32_t count)
{
    char *tmp;
    const char *s;

    if (dest <= src) {
        tmp = dest;
        s = src;
        while (count--)
        *tmp++ = *s++;
    } 
    else {
        tmp = dest;
        tmp += count;
        s = src;
        s += count;
        while (count--)
        *--tmp = *--s;
    }
    return dest;
}

void memset(void *dest, uint8_t val, uint32_t len)
{
    uint8_t *dst = (uint8_t *)dest;
    for (; len != 0; len--) {
        *dst++ = val;
    }
}

void bzero(void *dest, uint32_t len)
{
    memset(dest, 0, len);
}

int strcmp(const char *dest, const char *src)
{
    int ret = 0 ;
    while(!(ret = *(unsigned char *)src - *(unsigned char *)dest) && *dest) {
        ++src;
        ++dest;
    }

    if (ret < 0) {
        ret = -1;
    }
    else if (ret > 0) {
        ret = 1;
    }

    return ret;
}

char *strcpy(char *dest, const char *src)
{
    char *tmp = dest;
    while (*src) {
        *dest++ = *src++;
    }

    *dest = '\0';
    return tmp;
}

char *strncpy(char *dest, const char *src, uint32_t len)
{
    char *dst = dest;
    while (len > 0) {
        while (*src) {
            *dest++ = *src++;
        }
        len--;
    }

    *dest = '\0';
    return dst;
}

char *strcat(char *dest, const char *src)
{
    char *cp = dest;
    while (*cp) {
        cp++;
    }

    while ((*cp++ = *src++))
        ;

    return dest;
}

int strlen(const char *src)
{
    const char *eos = src;
    while (*eos++)
        ;

    return (eos - src - 1);
}

// Like strncpy but guaranteed to NUL-terminate.
char* safestrcpy(char *s, const char *t, int n)
{
  char *os;

  os = s;
  if(n <= 0)
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    ;
  *s = 0;
  return os;
}
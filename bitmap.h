#ifndef _BITMAP_H_
#define _BITMAP_H_

#include "types.h"

#define BITMAP_MASK 1

typedef struct bitmap {
    uint32_t btmp_bytes_len;
    uint8_t *bits;
} bitmap;

void bitmap_init(bitmap *btmp);
uint32_t bitmap_scan(bitmap *btmp, uint32_t cnt);
void bitmap_set(bitmap *btmp, uint32_t bit_idx, int8_t value);

#endif
#include "bitmap.h"
#include "console.h"
#include "debug.h"
#include "string.h"
#include "types.h"

static uint32_t bitmap_find_first_empty_byte(bitmap *btmp)
{
    assert(btmp);

    uint32_t byte_idx = 0;
    while ((byte_idx < btmp->btmp_bytes_len)
        && (0xff == btmp->bits[byte_idx]))
        ++byte_idx;
    return byte_idx;
}

static uint32_t bitmap_find_first_empty_bit(
    bitmap *btmp, uint32_t byte_idx)
{
    assert(btmp);

    uint32_t bit_idx = 0;
    while ((uint8_t)(BITMAP_MASK << bit_idx) & btmp->bits[byte_idx])
        ++bit_idx;
    return bit_idx;
}

static int bitmap_is_bit_used(bitmap *btmp, uint32_t bit_idx)
{
    assert(btmp);

    uint32_t byte_idx = bit_idx / 8;
    uint32_t bit_odd = bit_idx % 8;
    return btmp->bits[byte_idx] & (BITMAP_MASK << bit_odd);
}

static uint32_t bitmap_allocate_begin(
    bitmap *btmp, uint32_t bit_idx, uint32_t cnt)
{
    assert(btmp);

    uint32_t available = (btmp->btmp_bytes_len << 3) - bit_idx;
    uint32_t next_bit = bit_idx + 1;
    uint32_t count = 1;
    uint32_t empty_bit_start = -1;
    while (available-- > 0) {
        if (!bitmap_is_bit_used(btmp, next_bit)) 
            ++count;
        else 
            count = 0;
        if (count == cnt) {
            empty_bit_start = next_bit - cnt + 1;
            break;
        }
        ++next_bit;
    }
    return empty_bit_start;
}

void bitmap_init(bitmap *btmp)
{
    assert(btmp);

    memset(btmp->bits, 0, btmp->btmp_bytes_len);
}

uint32_t bitmap_scan(bitmap *btmp, uint32_t cnt)
{
    assert(btmp);

    uint32_t byte_idx = bitmap_find_first_empty_byte(btmp);
    uint32_t bit_idx = 0, empty_bit_start = 0;
    // printk("bitmap_scan: find byte %d\n", byte_idx);
    if (byte_idx == btmp->btmp_bytes_len)
        return -1;

    bit_idx = bitmap_find_first_empty_bit(btmp, byte_idx);
    empty_bit_start = (byte_idx << 3) + bit_idx;
    // printk("bitmap_scan: find bit %d\n", bit_idx);
    if (cnt == 1)
        return empty_bit_start;
    
    return bitmap_allocate_begin(btmp, empty_bit_start, cnt);
}

void bitmap_set(bitmap *btmp, uint32_t bit_idx, int8_t value)
{
    assert(value == 0 || value == 1);
    assert(btmp);

    uint32_t byte_idx = bit_idx / 8;
    uint32_t bit_odd = bit_idx % 8;
    if (value)
        btmp->bits[byte_idx] |= BITMAP_MASK << bit_odd;
    else 
        btmp->bits[byte_idx] &= ~(BITMAP_MASK << bit_odd);
}

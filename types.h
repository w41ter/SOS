#ifndef _TYPE_H_
#define _TYPE_H_

typedef char int8_t;
typedef short int16_t;
typedef int int32_t;
typedef long long int int64_t;
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long int uint64_t;

/**
 * Pointers and addresses are 32 bits long.
 * We use pointer types to represent addresses,
 * uintptr_t to represent the numerical values of addresses.
 */
typedef int32_t intptr_t;
typedef uint32_t uintptr_t;

/* size_t is used for memory object sizes */
typedef uintptr_t size_t;

#define NULL ((void*)0)

#define true 1
#define false 0
#define bool int

#endif // !_TYPE_H_
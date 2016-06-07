
#ifndef _MD5_H_
#define _MD5_H_

#include <stdint.h>

__declspec(dllexport) void md5_hash(uint8_t *message, uint32_t len, uint32_t hash[4]);

#endif
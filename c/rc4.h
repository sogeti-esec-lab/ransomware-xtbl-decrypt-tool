
#ifndef _RC4_H_
#define _RC4_H_

typedef struct rc4_key_t
{
    unsigned char state[256];
    unsigned char x;
    unsigned char y;
} rc4_key_t;

__declspec(dllexport) void rc4_init(const unsigned char *buf, unsigned int len, rc4_key_t * key);
__declspec(dllexport) void rc4_encrypt(unsigned char *buf, unsigned int len, rc4_key_t * key);
__declspec(dllexport) void rc4_decrypt(unsigned char *buf, unsigned int len, rc4_key_t * key);

#endif
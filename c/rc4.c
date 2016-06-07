#include "rc4.h"

void rc4_init(const unsigned char *buf, unsigned int len, rc4_key_t * key)
{
    unsigned char j = 0, o;
    unsigned char *state = key->state;
    int i;

    for (i = 0;  i < 256; ++i)
        state[i] = i;

    key->x = 0;
    key->y = 0;

    for (i = 0; i < 256; ++i)
    {
        j = j + state[i] + buf[i % len];
        o = state[i];
        state[i] = state[j];
        state[j] = o;
    }
}

void rc4_encrypt(unsigned char *buf, unsigned int len, rc4_key_t * key)
{
    unsigned char x;
    unsigned char y, o;
    unsigned char *state = key->state;
    unsigned int  i;

    x = key->x;
    y = key->y;

    for (i = 0; i < len; i++)
    {
        y = y + state[++x];
        o = state[x];
        state[x] = state[y];
        state[y] = o;
        buf[i] ^= state[(state[x] + state[y]) & 0xff];
    }

    key->x = x;
    key->y = y;
}

void rc4_decrypt(unsigned char *buf, unsigned int len, rc4_key_t * key)
{
    rc4_encrypt(buf, len, key);
}

#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <time.h>

#include "md5.h"
#include "rc4.h"
#include "aes.h"

#define SWAP4(val) \
 ( (((val) >> 24) & 0x000000FF) | (((val) >>  8) & 0x0000FF00) | \
   (((val) <<  8) & 0x00FF0000) | (((val) << 24) & 0xFF000000) )
#define HOUR 3600
#define DAY 86400
#define BS 0x1FFFF0

struct Info
{
    uint8_t magic[6];
    uint8_t IV[16];
    uint8_t padding;
    uint8_t rsa[128];
};

inline void compute_key(int ms, int ts, uint8_t* KEY)
{
    uint32_t k[8];
    uint32_t hash[4];
    rc4_key_t rc4state;

    k[0] = ms * 1000;
    k[1] = ts;
    k[2] = 0x29;
    k[3] = 0;
    k[4] = 0;
    k[5] = 0;
    k[6] = 0;
    k[7] = 0;

    md5_hash((uint8_t*)k, 32, hash);
    rc4_init((unsigned char *)hash, 16, &rc4state);
    rc4_encrypt((uint8_t*)k, 32, &rc4state);
    memcpy(KEY, k, 32);
}

__declspec(dllexport) int bf_range(time_t* start, uint32_t range, uint8_t* encHeader, uint8_t* IV, uint32_t origHeader, uint8_t* KEY)
{
    unsigned long ms;
    AesCtx ctx;
    time_t end;
    unsigned long clear[4];

    end = *start - range;
    while (*start > end)
    {
        for(ms=0; ms<1000; ms++)
        {
            compute_key(ms, *start, KEY);
            aes_init(&ctx, IV, KEY, KEY256, CBC);
            aes_decrypt(&ctx, encHeader, (uint8_t*)clear, 16);
            if (clear[0] == origHeader)
            {
                return 0;
            }
        }
        (*start)--;
    }
    return 1;
}

__declspec(dllexport) uint32_t bf_benchmark(uint32_t range)
{
    uint32_t t1;
    time_t t;
    uint8_t testKey[32];
    uint8_t testEnc[16] =
    {
        0xde, 0xad, 0xbe, 0xef,
        0xde, 0xad, 0xbe, 0xef,
        0xde, 0xad, 0xbe, 0xef,
        0xde, 0xad, 0xbe, 0xef
    };
    uint8_t testIV[16] =
    {
        0xba, 0xad, 0xf0, 0x0d,
        0xba, 0xad, 0xf0, 0x0d,
        0xba, 0xad, 0xf0, 0x0d,
        0xba, 0xad, 0xf0, 0x0d
    };

    t = (int)time(NULL);
    t1 = GetTickCount();
    bf_range(&t, range, testEnc, testIV, 0xB16B00B5, testKey);
    return GetTickCount()-t1;
}

__declspec(dllexport) int decrypt_file(wchar_t* encfilename, uint8_t* KEY, uint8_t* RSACheck)
{
    int error = 0, r, size, pos;
    uint8_t* encbuf = (uint8_t*)malloc(BS);
    uint8_t* decbuf = (uint8_t*)malloc(BS);
    wchar_t decfilename[256];
    struct Info info_block;
    AesCtx ctx;
    FILE* dec;
    FILE* enc = _wfopen(encfilename, L"rb");
    if (enc != 0)
    {

        fseek(enc, -151, SEEK_END);
        size = ftell(enc);
        fread(&info_block, sizeof(struct Info), 1, enc);
        fseek(enc, 0, SEEK_SET);

        if (memcmp(info_block.rsa, RSACheck, 128) == 0)
        {
            wcscpy(decfilename, encfilename);
            decfilename[wcslen(encfilename)-23] = '\0';
            dec = _wfopen(decfilename, L"wb");

            aes_init(&ctx, info_block.IV, KEY, KEY256, CBC);
            pos = 0;
            while(pos < size - BS)
            {
                r = fread(encbuf, 1, BS, enc);
                aes_decrypt(&ctx, encbuf, decbuf, r);
                fwrite(decbuf, BS, 1, dec);
                pos += r;
            }
            r = fread(encbuf, 1, size-pos, enc);
            aes_decrypt(&ctx, encbuf, decbuf, r);
            fwrite(decbuf, r - info_block.padding, 1, dec);

            fclose(dec);
        }
        else error = 1;

        fclose(enc);
    }
    else error = 2;

    free(encbuf);
    free(decbuf);
    return error;
}


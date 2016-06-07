
#ifndef _AES_H_
#define _AES_H_

typedef struct
{
    unsigned int Ek[60];
    unsigned int Dk[60];
    unsigned int Iv[4];
    unsigned char Nr;
    unsigned char Mode;
} AesCtx;

#define KEY128 16
#define KEY192 24
#define KEY256 32

#define BLOCKSZ 16

#define EBC 0
#define CBC 1

__declspec(dllexport) int aes_init(AesCtx *pCtx, unsigned char *pIV, unsigned char *pKey, unsigned int KeyLen, unsigned char Mode);
__declspec(dllexport) int aes_encrypt(AesCtx *pCtx, unsigned char *pData, unsigned char *pCipher, unsigned int DataLen);
__declspec(dllexport) int aes_decrypt(AesCtx *pCtx, unsigned char *pCipher, unsigned char *pData, unsigned int CipherLen);

#endif
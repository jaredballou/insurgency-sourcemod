// This file implements the Secure Hashing Standard as defined in FIPS PUB 180-1 published April 17, 1995.
// Ported to SourcePawn by Peace-Maker
// Version 1.1: Fixed SHA1File compile error
#if defined _SHA1_included
    #endinput
#endif

#define _SHA1_included

enum SHA1Context {
    Message_Digest[5],
    Length_Low,
    Length_High,
    Message_Block[64],
    Message_Block_Index,
    Computed,
    Corrupted
}

new const  ___const_SHA1K[] = {0x5a827999, 0x6ed9eba1, 0x8f1bbcdc, 0xca62c1d6};

/**
 * @brief			Produces a 160-bit message digest for a given data stream
 *
 * @param str		Input string to calculate the hash from.
 * @param output	Output buffer. If bHex is true, output must be at least 40+1 of length, if not it has to be 20+1.
 * @param bHex		If true, return the hash as hexadecimal number, else return a raw binary format.
 * @return          True, if hash was calculated, false otherwise
 */
stock bool:SHA1String(const String:str[], String:output[], bool:bHex=true)
{
    output[0] = '\0';
    
    new Context[SHA1Context];
    SHA1Reset(Context);
    
    new len = strlen(str);
    new msg[len];
    for(new i=0;i<len;i++)
    {
        msg[i] = str[i];
    }
    
    SHA1Input(Context, msg, len);

    if(!SHA1Result(Context))
    {
        //LogError("SHA1ERROR-- could not compute message digest");
        return false;
    }
    else
    {
        SHA1Finalize(Context, output, bHex);
    }
    return true;
}

/**
 * @brief			Produces a 160-bit message digest for a given file
 *
 * @param hFile		File handle returned by OpenFile(path, "r"); 
 * @param output	Output buffer. If bHex is true, output must be at least 40+1 of length, if not it has to be 20+1.
 * @param bHex		If true, return the hash as hexadecimal number, else return a raw binary format.
 * @return          True, if hash was calculated, false otherwise
 */
stock bool:SHA1File(Handle:hFile, String:output[], bool:bHex=true)
{
    output[0] = '\0';
    
    new Context[SHA1Context];
    SHA1Reset(Context);

    new input[1];
    while(!IsEndOfFile(hFile))
    {
        if(ReadFileCell(hFile, input[0], 1) != 1)
					continue;
        SHA1Input(Context, input, 1);
    }

    if(!SHA1Result(Context))
    {
        //LogError("SHA1ERROR-- could not compute message digest");
        return false;
    }
    else
    {
        SHA1Finalize(Context, output, bHex);
    }
    return true;
}

SHA1Reset(Context[SHA1Context])
{
    Context[Length_Low] = 0;
    Context[Length_High] = 0;
    
    Context[Message_Digest][0] = 0x67452301;
    Context[Message_Digest][1] = 0xEFCDAB89;
    Context[Message_Digest][2] = 0x98BADCFE;
    Context[Message_Digest][3] = 0x10325476;
    Context[Message_Digest][4] = 0xC3D2E1F0;
    
    Context[Message_Block_Index] = 0;
}

// if bHex is true, output must be at least 40+1 of length, if not it has to be 20+1.
SHA1Finalize(Context[SHA1Context], String:output[], bool:bHex)
{
    if(bHex)
    {
        for(new i=0;i<5;i++)
            Format(output, 41, "%s%x", output, Context[Message_Digest][i]);
    }
    else
    {
        for(new i=0,j=0;j<20;i++,j+=4)
        {
            output[j] = (Context[Message_Digest][i] >> 24) & 0xff;
            output[j+1] = (Context[Message_Digest][i] >> 16) & 0xff;
            output[j+2] = (Context[Message_Digest][i] >> 8) & 0xff;
            output[j+3] = Context[Message_Digest][i] & 0xff;
        }
    }
}

SHA1Input(Context[SHA1Context], const message_array[], length)
{
    if(!length)
        return;
    
    if(Context[Computed] || Context[Corrupted])
    {
        Context[Corrupted] = 1;
        return;
    }
    
    new i = 0;
    while(length-- && !Context[Corrupted])
    {
        Context[Message_Block][Context[Message_Block_Index]++] = (message_array[i] & 0xFF);
        
        Context[Length_Low] += 8;
        /* Force it to 32 bits */
        Context[Length_Low] &= 0xFFFFFFFF;
        if(Context[Length_Low] == 0)
        {
            Context[Length_High]++;
            /* Force it to 32 bits */
            Context[Length_High] &= 0xFFFFFFFF;
            if(Context[Length_High] == 0)
            {
                /* Message is too long */
                Context[Corrupted] = 1;
            }
        }
        
        if(Context[Message_Block_Index] == 64)
        {
            SHA1ProcessMessageBlock(Context);
        }
        
        i++;
    }
}

SHA1Result(Context[SHA1Context])
{
    if(Context[Corrupted])
        return 0;
    
    if(!Context[Computed])
    {
        SHA1PadMessage(Context);
        Context[Computed] = 1;
    }
    
    return 1;
}

SHA1ProcessMessageBlock(Context[SHA1Context])
{
    new t;
    new temp;
    new W[80];
    new A, B, C, D, E;
    
    for(t=0;t<16;t++)
    {
        W[t] = (Context[Message_Block][t*4]) << 24;
        W[t] |= (Context[Message_Block][t*4+1]) << 16;
        W[t] |= (Context[Message_Block][t*4+2]) << 8;
        W[t] |= (Context[Message_Block][t*4+3]);
    }
    
    for(t=16;t<80;t++)
    {
        W[t] = SHA1CircularShift(1,W[t-3]^W[t-8]^W[t-14]^W[t-16]);
    }
    
    A = Context[Message_Digest][0];
    B = Context[Message_Digest][1];
    C = Context[Message_Digest][2];
    D = Context[Message_Digest][3];
    E = Context[Message_Digest][4];
    for(t=0;t<20;t++)
    {
        temp = SHA1CircularShift(5,A) + ((B&C)|((~B)&D)) + E + W[t] + ___const_SHA1K[0];
        temp &= 0xFFFFFFFF;
        E = D;
        D = C;
        C = SHA1CircularShift(30,B);
        B = A;
        A = temp;
    }
    
    for(t=20;t<40;t++)
    {
        temp = SHA1CircularShift(5,A) + (B^C^D) + E + W[t] + ___const_SHA1K[1];
        temp &= 0xFFFFFFFF;
        E = D;
        D = C;
        C = SHA1CircularShift(30,B);
        B = A;
        A = temp;
    }
    
    for(t=40;t<60;t++)
    {
        temp = SHA1CircularShift(5,A) + ((B&C)|(B&D)|(C&D)) + E + W[t] + ___const_SHA1K[2];
        temp &= 0xFFFFFFFF;
        E = D;
        D = C;
        C = SHA1CircularShift(30,B);
        B = A;
        A = temp;
    }
    
    for(t=60;t<80;t++)
    {
        temp = SHA1CircularShift(5,A) + (B^C^D) + E + W[t] + ___const_SHA1K[3];
        temp &= 0xFFFFFFFF;
        E = D;
        D = C;
        C = SHA1CircularShift(30,B);
        B = A;
        A = temp;
    }
    
    Context[Message_Digest][0] = (Context[Message_Digest][0]+A) & 0xFFFFFFFF;
    Context[Message_Digest][1] = (Context[Message_Digest][1]+B) & 0xFFFFFFFF;
    Context[Message_Digest][2] = (Context[Message_Digest][2]+C) & 0xFFFFFFFF;
    Context[Message_Digest][3] = (Context[Message_Digest][3]+D) & 0xFFFFFFFF;
    Context[Message_Digest][4] = (Context[Message_Digest][4]+E) & 0xFFFFFFFF;
    
    Context[Message_Block_Index] = 0;
}

stock SHA1PadMessage(Context[SHA1Context])
{
    /*
     *  Check to see if the current message block is too small to hold
     *  the initial padding bits and length.  If so, we will pad the
     *  block, process it, and then continue padding into a second
     *  block.
     */
    if(Context[Message_Block_Index] > 55)
    {
        Context[Message_Block][Context[Message_Block_Index]++] = 0x80;
        while(Context[Message_Block_Index] < 64)
        {
            Context[Message_Block][Context[Message_Block_Index]++] = 0;
        }
        
        SHA1ProcessMessageBlock(Context);
        
        while(Context[Message_Block_Index] < 56)
        {
            Context[Message_Block][Context[Message_Block_Index]++] = 0;
        }
    }
    else
    {
        Context[Message_Block][Context[Message_Block_Index]++] = 0x80;
        while(Context[Message_Block_Index] < 56)
        {
            Context[Message_Block][Context[Message_Block_Index]++] = 0;
        }
    }
    
    Context[Message_Block][56] = (Context[Length_High]>>24)&0xFF;
    Context[Message_Block][57] = (Context[Length_High]>>16)&0xFF;
    Context[Message_Block][58] = (Context[Length_High]>>8)&0xFF;
    Context[Message_Block][59] = (Context[Length_High])&0xFF;
    Context[Message_Block][60] = (Context[Length_Low]>>24)&0xFF;
    Context[Message_Block][61] = (Context[Length_Low]>>16)&0xFF;
    Context[Message_Block][62] = (Context[Length_Low]>>8)&0xFF;
    Context[Message_Block][63] = (Context[Length_Low])&0xFF;
    
    SHA1ProcessMessageBlock(Context);
}

stock SHA1CircularShift(bits,word)
{
    return (word<<bits) | (word>>>(32-bits));
}
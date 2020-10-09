#include "hash-functions.hlsl"

cbuffer ParamConstants : register(b0)
{
    float Amount;
    float Color;
    float Exponent;
    float Brightness;
    float Speed;
}

cbuffer TimeConstants : register(b1)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

Texture2D<float4> ImageA : register(t0);
sampler texSampler : register(s0);

#define mod(x, y) (x - y * floor(x / y))
float IsBetween( float value, float low, float high) {
    return (value >= low && value <= high) ? 1:0;
}

float4 psMain(vsOutput psInput) : SV_TARGET
{   
    float pxHash = hash12( psInput.texCoord * 431 + 111);
    float t = beatTime * Speed + pxHash;
    float4 hash1 = hash42(( psInput.texCoord * 431 + (int)t));
    float4 hash2 = hash42(( psInput.texCoord * 431 + (int)t+1));
    float4 hash = lerp(hash1,hash2, t % 1);

    float4 grayScale = (hash.r+hash.g+hash.b)/3;
    float4 noise = lerp(grayScale, hash, Color);
    //noise = noise ;
    noise = saturate(pow(noise, Exponent)+ Brightness);

    float4 orgColor = ImageA.Sample(texSampler, psInput.texCoord);
    float4 color = float4( lerp( orgColor.rgb, noise.rgb, Amount), 1);
    return color;
}
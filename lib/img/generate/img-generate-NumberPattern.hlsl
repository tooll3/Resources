#include "hash-functions.hlsl"

cbuffer ParamConstants : register(b0)
{
    float4 Background;
    float4 Foreground;
    float4 Highlight;
    float BrightnessOffset;

    // float2 SplitA;
    // float2 SplitB;
    // float2 SplitC;
    // float2 SplitProbability;
    // float2 ScrollSpeed;
    // float2 ScrollProbability;
    // float2 Padding;
    // float Contrast;
    // //float Iterations;
    // float Seed; 
    // float ForegroundRatio;
    // float HighlightProbability;
    // float MixOriginal;
    // float ScrollOffset;
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
Texture2D<float4> ImageB : register(t1);
sampler texSampler : register(s0);

#define mod(x, y) (x - y * floor(x / y))



static float2 P;
static const float2 DigitSize = float2(4,6);
static float2 NumberCelSize = float2(5,1) * DigitSize;
static float2 ImageSize; 
static float2 NumberImageSize; 




bool IsPointInsideCel(float2 p, float4 cel) {
     return 
        p.x >= cel.x
     && p.x <= cel.x+ cel.z 
     && p.y >= cel.y
     && p.y <= cel.y+cel.w;
}


float4 DrawNumber(float4 cel, float number, float scale) 
{
    float2 posInCel = P - cel.xy;
    if(posInCel.x > cel.z || posInCel.x < 0 || posInCel.y> cel.w || posInCel.y<0)
        return float4(0,0,0,0);

    float celHash = hash12(cel.xy);
    float2 digitSlot = floor(posInCel / DigitSize);
    float2 pixelInDigit = floor(posInCel % DigitSize)+ 0.5;
    float4 imgColor = ImageA.Sample(texSampler, cel.xy/ImageSize);

    float value = number;

    float digit = floor(value * pow(10+sin(beatTime+celHash) *0.0001,digitSlot.x))%10;
    float2 numberUv = (float2( digit * DigitSize.x,0) + pixelInDigit) / NumberImageSize;
    float4 numberColor= ImageB.Sample(texSampler, numberUv);
    
    return (1-numberColor) * Foreground;
    return float4(digitSlot.xy/10,0,1);
}


//static float BrightnessOffset= 100;



float4 DrawCel(float4 cel) 
{
    if(!IsPointInsideCel(P, cel))
        return float4(0,1,0,1);


    float2 pInside = P - cel.xy;

    // Center line
    if(IsPointInsideCel( P, float4(cel.xy+ cel.zw/2 - float2(0,2), 1,5)))
        return float4(1,1,1,1);


    if(IsPointInsideCel( P, float4(cel.xy+ cel.zw/2 - float2(0,2), 1,5)))
        return float4(1,1,1,1);


    float2 center = cel.xy+cel.zw/2;
    float4 celColor = ImageA.Sample(texSampler, center/ImageSize);
    float4 color = 0;


    // Draw Brighness on right
    float brightness = celColor.r;
    float width = brightness * BrightnessOffset;


    if(IsPointInsideCel( P, float4(center, width-2,1)))
        return float4(1,1,1,1);


    color+= DrawNumber(
        float4(
            center + float2(width,0) - float2(0,2), 
            NumberCelSize
        ), brightness * 10, 1);

    // Draw hue
    float hue = atan2(celColor.r, celColor.g);
    hue=2342342.2342;
    color+= DrawNumber(
        float4(
            center - float2(40,2), 
            NumberCelSize
        ), hue, 1);

    return color;
    
}



float4 psMain(vsOutput psInput) : SV_TARGET
{   
    uint width, height;

    ImageA.GetDimensions(width, height);
    ImageSize = float2(width,height);

    ImageB.GetDimensions(width, height);
    NumberImageSize = float2(width,height);

    P = psInput.texCoord * ImageSize;

    float2 offset = float2(0, floor(runTime*30));
    float2 celSize = float2(300,8);
    float2 celPos = floor((P+offset) /celSize) * celSize-offset;
    
    return DrawCel(float4(celPos, celSize))
            +ImageA.Sample(texSampler, psInput.texCoord) * Background;
}
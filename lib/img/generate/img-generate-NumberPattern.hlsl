#include "hash-functions.hlsl"

cbuffer ParamConstants : register(b0)
{
    float4 Background;
    float4 Foreground;
    float4 Highlight;

    float2 SplitA;
    float2 SplitB;
    float2 SplitC;
    float2 SplitProbability;
    float2 ScrollSpeed;
    float2 ScrollProbability;
    float2 Padding;
    float Contrast;
    //float Iterations;
    float Seed; 
    float ForegroundRatio;
    float HighlightProbability;
    float MixOriginal;
    float ScrollOffset;
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
static float2 NumberSize = float2(4,6);
static float2 ImageSize; 
static float2 NumberImageSize; 


float4 DrawNumber(float4 cel, float number, float scale) 
{
    float2 posInCel = P - cel.xy;
    if(posInCel.x > cel.z || posInCel.x < 0 || posInCel.y> cel.w || posInCel.y<0)
        return float4(0,0,0,0);

    float celHash = hash12(cel.xy);
    //return float4(posInCel/10, 0,1);
    float2 digitSlot = floor(posInCel / NumberSize);
    float2 pixelInDigit = floor(posInCel % NumberSize)+ 0.5;
    //return float4(pixelInDigit.xy/4,0,1);
 //   return float4( (posInCel % NumberSize) / NumberSize, 0,1);
    
 //   float2 posInNumberCel = posInCel - digitSlot * NumberSize;

    float4 imgColor = ImageA.Sample(texSampler, cel.xy/ImageSize);


    // float2 hash = hash22(digitSlot + beatTime*0.1);
    // //float2 value = float2(sin((digitSlot.x + beatTime)*0.1)+ cos(digitSlot.y+beatTime*0.3),1) ;
    // float value = hash.x*1;
    // value += digitSlot/10;
    // value %= 1;
    
    float value = number;
    //float digitIndex = digitSlot.x%12;
    float digit = floor(value * pow(10+sin(beatTime+celHash) *0.0001,digitSlot.x))%10;
    //value = pow(10,value* digitSlot6);
    //float2 digit = float2(digit1, 0);


    //float digit = floor(value.x*10%10);
    //return float4(digit/10,0,0,1);

    float2 numberUv = (float2( digit * NumberSize.x,0) + pixelInDigit) / NumberImageSize;
    //return float4(numberUv,0,1);
    float4 numberColor= ImageB.Sample(texSampler, numberUv);
    
    return numberColor * Foreground;
    return float4(digitSlot.xy/10,0,1);
}





float4 psMain(vsOutput psInput) : SV_TARGET
{   
    uint width, height;
    ImageA.GetDimensions(width, height);
    ImageSize = float2(width,height);

    ImageB.GetDimensions(width, height);
    NumberImageSize = float2(width,height);

    P = psInput.texCoord * ImageSize;
    P.y+= beatTime * 100;

    float4 col = ImageA.Sample(texSampler, psInput.texCoord);

    float2 celSize = float2(30,2) * NumberSize;
    float2 celPos = floor(P/celSize)*celSize;
    float4 celCol = ImageA.Sample(texSampler, celPos/ImageSize);
    P +=  float2(sin(beatTime) * 0,0) - float2(celCol.r,0)*100;

    float number = celCol.r*10;

    float2 numberCelSize = float2(10,1) * NumberSize;
    //float4 cel = float4(floor(P/celSize)*celSize, numberCelSize);
    float4 cel  = float4(floor(celPos/celSize)*celSize, numberCelSize);

    
    float4 numberColor = DrawNumber(cel, number, 2);
    //return float4(cel.xy/10,0,1);

    return numberColor + col;

}
cbuffer ParamConstants : register(b0)
{
    float4 Fill;
    float4 Background;    
    float2 Offset;
    float2 FontCharSize;
    float ScaleFactor;
    float Bias;
}

cbuffer TimeConstants : register(b1)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

cbuffer Resolution : register(b2)
{
    float TargetWidth;
    float TargetHeight;
}

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

Texture2D<float4> ImageA : register(t0);
Texture2D<float4> ImageB : register(t1);
Texture2D<float> ImageC : register(t2);

sampler texSampler : register(s0);
sampler texSamplerPoint : register(s1);

//static float2 Divisions = float2(100,100);
#define mod(x,y) (x-y*floor(x/y))

float4 psMain(vsOutput psInput) : SV_TARGET
{    
    //return float4(1,1,0,1);
    float aspectRatio = TargetWidth/TargetHeight;
    float2 p = psInput.texCoord;
    p-= 0.5;
    float2 fontCharWidth = FontCharSize; 
    p+= Offset / fontCharWidth;
    //return float4(TargetWidth/ 6 / 1000,0,0,1);
    float2 divisions = float2(TargetWidth / fontCharWidth.x, TargetHeight / fontCharWidth.y) / ScaleFactor;
    //divisions = float2(20,20);
    //p -= float2(0.5 / aspectRatio, 0.5);
    //return float4(1,1,0,1);

    float2 p1 = p;//- float2(0.5/TargetWidth, 0.5/TargetHeight);
    float2 gridSize = float2( 1/divisions.x, 1/divisions.y);
    float2 pInCell = mod(p1, gridSize);
    float2 cellTiles = (p1 - pInCell + 0.5) - Offset / fontCharWidth;

    pInCell *= divisions;

    float4 colFromImageA = ImageA.Sample(texSampler, cellTiles); 
    
    float grayScale = (colFromImageA.r + colFromImageA.g + colFromImageA.b)/3;
    //float grayScale = colFromImageA.r;

    float dBiased = Bias>= 0 
        ? pow( grayScale, Bias+1)
        : 1-pow( clamp(1-grayScale,0,10), -Bias+1);    

    float letter = ImageC.Sample(texSamplerPoint, float2( dBiased ,0));
    //return float4(1,1,1,letter);

    float letterIndex = letter * 256;
    float rowIndex = floor(letterIndex / 16);
    float columnIndex = floor(letterIndex % 16);

    float2 letterPos = float2( columnIndex , rowIndex) / 16;
    float4 colorFromFont = ImageB.Sample(texSamplerPoint, pInCell / 16 + letterPos);    
    return lerp(Background, Fill, colorFromFont.r);
}
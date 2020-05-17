cbuffer ParamConstants : register(b0)
{
    float Steps;
    float Bias;
    float Offset;
    float SmoothRadius;
    
    float2 OffsetImage;
    float __dummy__;
    float ShadeAmount;
    float4 ShadeColor;
    float2 Center;
}

cbuffer TimeConstants : register(b1)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

cbuffer TimeConstants : register(b2)
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
sampler texSampler : register(s0);

float mod(float x, float y) {
    return (x - y * floor(x / y));
} 


float calcStep(float4 orgColor) {
    float cOrg = (orgColor.r + orgColor.g + orgColor.b)/3;
    float cBiased = Bias>= 0 
        ? pow( cOrg, Bias+1)
        : 1-pow( clamp(1-cOrg,0,10), -Bias+1);  

    float s = mod( cBiased + Offset/Steps, 1/Steps);
    float c = cBiased-s;
    c-= pow(s*Steps,6)*0.1;

    if(cOrg > 1 - 1/Steps)
        c = 1;
    return c;
} 

float4 psMain(vsOutput psInput) : SV_TARGET
{   
    float2 p = psInput.texCoord;
    //float4 orgColor= ImageA.Sample(texSampler, p);

    float2 res= float2(0.5/TargetWidth, 0.5/TargetHeight) * SmoothRadius;

    float c=(
        calcStep(ImageA.Sample(texSampler, p+res * float2(0,0)))*2
        + calcStep(ImageA.Sample(texSampler, p+res * float2(1,1)))
        +calcStep(ImageA.Sample(texSampler, p +res * float2(1,-1)))
        +calcStep(ImageA.Sample(texSampler, p +res * float2(-1,1)))
        +calcStep(ImageA.Sample(texSampler, p +res * float2(-1,-1)))
    )/6;


    return float4(c,c,c,1);


}
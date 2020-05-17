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
Texture2D<float4> RampImageA : register(t1);
sampler texSampler : register(s0);

float mod(float x, float y) {
    return (x - y * floor(x / y));
} 


float2 calcStepAndOffset(float4 orgColor) {
    float cOrg = (orgColor.r + orgColor.g + orgColor.b)/3;
    float cBiased = Bias>= 0 
        ? pow( cOrg, Bias+1)
        : 1-pow( clamp(1-cOrg,0,10), -Bias+1);  

    float rest = mod( cBiased + Offset/Steps, 1/Steps);
    float step = cBiased-rest;
   // step-= pow(rest*Steps,6)*0.1;

    // if(cOrg > 1 - 1/Steps)
    //     step = 1;
        
    return float2(step, rest*Steps);
} 

float4 psMain(vsOutput psInput) : SV_TARGET
{   
    float2 p = psInput.texCoord;
    
    //float4 orgColor= ImageA.Sample(texSampler, p);

    float2 res= float2(0.5/TargetWidth, 0.5/TargetHeight) * SmoothRadius;

    float2 sAndC=(
        calcStepAndOffset(ImageA.Sample(texSampler, p+res * float2(0,0)))*1
        +calcStepAndOffset(ImageA.Sample(texSampler, p+res * float2(1,1)))
        +calcStepAndOffset(ImageA.Sample(texSampler, p +res * float2(1,-1)))
        +calcStepAndOffset(ImageA.Sample(texSampler, p +res * float2(-1,1)))
        +calcStepAndOffset(ImageA.Sample(texSampler, p +res * float2(-1,-1)))
    )/5;


    //
    //float c = sAndC.y *(1- sAndC.x);  
    
    //return float4(sAndC,0,1);

    float rampColor = mod( 1  - sAndC.x - Offset/Steps,1);


    float4 colorFromRamp= RampImageA.Sample(texSampler, float2(rampColor,0.5/2));


    float4 colorFromEdge= RampImageA.Sample(texSampler, float2(sAndC.y -0 / 255 , 1.5/2));
    //return float4( sAndC, 0,1);

    float a = clamp(colorFromRamp.a + colorFromEdge.a - colorFromRamp.a*colorFromEdge.a, 0,1);
    float3 rgb = (1.0 - colorFromEdge.a)*colorFromRamp.rgb + colorFromEdge.a*colorFromEdge.rgb;   
    return float4(rgb,a);

    // return colorFromRamp + colorFromEdge;

    // return float4(c,c,c,1);


}
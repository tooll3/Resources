#include "point.hlsl"
// struct Point
// {
//     float3 position;
//     float size;
// };

static const float3 Corners[] = 
{
  float3(0, -1, 0),
  float3(1, -1, 0), 
  float3(1,  1, 0), 
  float3(1,  1, 0), 
  float3(0,  1, 0), 
  float3(0, -1, 0),  
};

cbuffer Transforms : register(b0)
{
    float4x4 CameraToClipSpace;
    float4x4 ClipSpaceToCamera;
    float4x4 WorldToCamera;
    float4x4 CameraToWorld;
    float4x4 WorldToClipSpace;
    float4x4 ClipSpaceToWorld;
    float4x4 ObjectToWorld;
    float4x4 WorldToObject;
    float4x4 ObjectToCamera;
    float4x4 ObjectToClipSpace;
};

cbuffer TimeConstants : register(b1)
{
    float GlobalTime;
    float Time;
    float RunTime;
    float BeatTime;    
}

cbuffer Params : register(b2)
{
    float4 Color;
    float Size;
    float SegmentCount;

    float FogRate;
    float FogBias;
    float4 FogColor;

    float ShrinkWithDistance;
};

struct psInput
{
    float4 position : SV_POSITION;
    float4 color : COLOR;
    float2 texCoord : TEXCOORD;
};

sampler texSampler : register(s0);

StructuredBuffer<Point> Points : t0;
Texture2D<float4> texture2 : register(t1);

psInput vsMain(uint id: SV_VertexID)
{
    psInput output;
    float discardFactor = 1;

    float4 aspect = float4(CameraToClipSpace[1][1] / CameraToClipSpace[0][0],1,1,1);
    int quadIndex = id % 6;
    int particleId = id / 6;
    float3 cornerFactors = Corners[quadIndex];
    
    Point pointAA = Points[ particleId<1 ? 0: particleId-1];
    Point pointA = Points[particleId];
    Point pointB = Points[particleId+1];
    Point pointBB = Points[particleId > SegmentCount-2 ? SegmentCount-2: particleId+2];

    float3 posInWorld = cornerFactors.x < 0.5
        ? pointA.position
        : pointB.position;


    float4 aaInScreen  = mul(float4(pointAA.position,1), ObjectToClipSpace);
    aaInScreen /= aaInScreen.w;
    float4 aInScreen  = mul(float4(pointA.position,1), ObjectToClipSpace);
    if(aInScreen.z < -0)
        discardFactor = 0;
    aInScreen /= aInScreen.w;

    
    float4 bInScreen  = mul(float4(pointB.position,1), ObjectToClipSpace);
    if(bInScreen.z < -0)
        discardFactor = 0;

    bInScreen /= bInScreen.w;
    float4 bbInScreen  = mul(float4(pointBB.position,1), ObjectToClipSpace);
    bbInScreen /= bbInScreen.w;

    float3 direction = (aInScreen - bInScreen).xyz;
    float3 directionA = particleId > 0 
                            ? (aaInScreen - aInScreen).xyz
                            : direction;
    float3 directionB = particleId < SegmentCount- 1
                            ? (bInScreen - bbInScreen).xyz
                            : direction;

    float3 normal =  normalize( cross(direction * aspect.xyz, float3(0,0,1)))/aspect.xyz; 
    float3 normalA =  normalize( cross(directionA * aspect.xyz, float3(0,0,1)))/aspect.xyz; 
    float3 normalB =  normalize( cross(directionB * aspect.xyz, float3(0,0,1)))/aspect.xyz; 

    float3 neighboarNormal = lerp(normalA, normalB, cornerFactors.x);
    float3 meterNormal = (normal + neighboarNormal) / 2;
    float4 pos = lerp(aInScreen, bInScreen, cornerFactors.x);
    
    float thickness = lerp( pointA.w , pointB.w, cornerFactors.x) * Size * discardFactor;

    float3 posInCamSpace = mul(float4(posInWorld,1), WorldToCamera);

    thickness *= lerp(1, 1/(posInCamSpace.z), ShrinkWithDistance);
    pos+= cornerFactors.y * 0.1f * thickness * float4(meterNormal,0);   

    output.position = pos;
    

    float strokeFactor = (particleId+ cornerFactors.x) / SegmentCount;
    output.texCoord = float2(strokeFactor, cornerFactors.y /2 +0.5);
    //output.texCoord = float2(cornerFactors.x , cornerFactors.y /2 +0.5);

    float3 n = cornerFactors.x < 0.5 
        ? cross(pointA.position - pointAA.position, pointA.position - pointB.position)
        : cross(pointB.position - pointA.position, pointB.position - pointBB.position);
    n =normalize(n);

    //float3 posInClipSpace = mul(posInWorld, WorldToClipSpace);

    float4 posInClipSpace4 = mul(float4(posInWorld,1), WorldToClipSpace);

    //float fog =  posInClipSpace4.w;// pow(saturate(-(posInClipSpace.z + FogBias) *FogRate), 1.2);
    //output.color.rgb = posInClipSpace4.xyz/posInClipSpace4.w /2 + 0.5;// (posInClipSpace4.x+3)/10;// / posInClipSpace4.w;
    float fog =  saturate(pow( 1 / posInClipSpace4.w, FogBias));
    //float fog = abs(1 / posInClipSpace4.w)/1;
    output.color.rgb = lerp(FogColor,Color, fog);
    //output.color.rgb = float3(0,1,0);
    output.color.a = Color.a;

    return output;    
}

float4 psMain(psInput input) : SV_TARGET
{
    float4 imgColor = texture2.Sample(texSampler, input.texCoord);
    //return clamp(input.color * imgColor, float4(0,0,0,0), float4(1,1000,1000,1000));// * float4(input.texCoord,1,1);    

    float dFromLineCenter= abs(input.texCoord.y -0.5)*2;
    float a= smoothstep(1,0.95,dFromLineCenter) ;
    float4 color = input.color * imgColor;// * input.color;

    return clamp(float4(color.rgb, color.a * a), 0, float4(1,100,100,100));
}

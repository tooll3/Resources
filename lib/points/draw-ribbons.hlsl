#include "point.hlsl"

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
    int quadIndex = id % 6;
    int particleId = id / 6;
    float3 cornerFactors = Corners[quadIndex];

    int offset = cornerFactors.x < 0.5 ? 0 : 1; 
    Point p = Points[particleId+offset];

    float side = cornerFactors.y;

    float3 widthV = rotate_vector(float3(side,0,0), p.rotation) * Size * p.w;;
    float3 pInObject = p.position + widthV;

    float3 normal = normalize(rotate_vector(float3(0,1,0), p.rotation));
    float4 normalInScreen = mul(float4(normal,1), ObjectToClipSpace);
    //normalInScreen /= normalInScreen.w;

    float4 pInScreen  = mul(float4(pInObject,1), ObjectToClipSpace);

    if(pInScreen.z < -0)
        discardFactor = 0;

    float3 lightDirection = float3(1.2, 1, -0.1);
    float phong = pow(  dot(normal,lightDirection ),1);

    pInScreen /= pInScreen.w;
    
    output.position = pInScreen;

    output.texCoord = float2(cornerFactors.x , cornerFactors.y /2 +0.5);
    output.color = Color;
    if(normalInScreen.z < 1) {
        output.color.rgb = float3(1,1,0);
    }
    //if(phong >0) {
        output.color.rgb *= phong;
    //}
    //else {
    //    output.color.rgb = float3(0.02,0.06, 0.1) * 0.2;
    //}
    
    //output.color.rgb = abs(normal);
    output.color.a = discardFactor;
    return output;    
}

float4 psMain(psInput input) : SV_TARGET
{
    float4 imgColor = texture2.Sample(texSampler, input.texCoord);
 
    float dFromLineCenter= abs(input.texCoord.y -0.5)*2;
    float a= smoothstep(1,0.95,dFromLineCenter) ;
    float4 color = input.color * imgColor;// * input.color;

    return clamp(float4(color.rgb, color.a * a), 0, float4(1,100,100,100));
}

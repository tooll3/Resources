#include "point.hlsl"


static const float3 Corners[] = 
{
  float3(-1, -1, 0),
  float3( 1, -1, 0), 
  float3( 1,  1, 0), 
  float3( 1,  1, 0), 
  float3(-1,  1, 0), 
  float3(-1, -1, 0), 
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

// cbuffer TimeConstants : register(b1)
// {
//     float GlobalTime;
//     float Time;
//     float RunTime;
//     float BeatTime;
// }

cbuffer Params : register(b2)
{
    float4 Color;
    
    float Size;
    float SegmentCount;
};

cbuffer FogParams : register(b3)
{
    float4 FogColor;
    float FogDistance;
    float FogBias;   
}

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

    int quadIndex = id % 6;
    int particleId = id / 6;
    Point pointDef = Points[particleId];

    float4 aspect = float4(CameraToClipSpace[1][1] / CameraToClipSpace[0][0],1,1,1);
    float3 quadPos = Corners[quadIndex];
    float3 rotated = rotate_vector(quadPos, pointDef.rotation); 
    float3 quadPos2 = rotated;

    float4 posInObject = float4(pointDef.position,1);
    float4 quadPosInCamera = mul(posInObject, ObjectToCamera);
    output.color = Color;
    quadPosInCamera.xy += quadPos2.xy*0.050  * pointDef.w * Size;
    output.position = mul(quadPosInCamera, CameraToClipSpace);

    output.texCoord = (quadPos.xy * 0.5 + 0.5);

    // Fog
    float4 posInCamera = mul(posInObject, ObjectToCamera);
    float fog = pow(saturate(-posInCamera.z/FogDistance), FogBias);
    output.color.rgb = lerp(Color.rgb, FogColor.rgb,fog);

    return output;
}

float4 psMain(psInput input) : SV_TARGET
{
    float4 xxx = texture2.Sample(texSampler, input.texCoord);
    return clamp(input.color * xxx, float4(0,0,0,0), float4(1,1000,1000,1000));// * float4(input.texCoord,1,1);    
}

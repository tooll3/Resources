#include "hash-functions.hlsl"
//#include "cbuffer-structs.hlsl"

cbuffer TimeConstants : register(b0)
{
    float GlobalTime;
    float Time;
    float RunTime;
    float BeatTime;
    float LastFrameDuration;
}; 
 
//ConstantBuffer<TimeConstants> myTimeConstants : register(b0);

// cbuffer Transforms : register(b1)
// {
//     float4x4 CameraToClipSpace;
//     float4x4 ClipSpaceToCamera;
//     float4x4 WorldToCamera;
//     float4x4 CameraToWorld;
//     float4x4 WorldToClipSpace;
//     float4x4 ClipSpaceToWorld;
//     float4x4 ObjectToWorld;
//     float4x4 WorldToObject;
//     float4x4 ObjectToCamera;
//     float4x4 ObjectToClipSpace;
// };

// cbuffer CountConstants : register(b2)
// {
//     int4 BufferCount;
// }

cbuffer Params : register(b2)
{
    float Count;
    float Radius;
    float RadiusOffset;
    float __padding1;

    float3 Center;
    float __padding2;

    float3 CenterOffset;
    float __padding3;

    float StartAngle;
    float Cycles;
    float2 __padding4;
    
    float3 Axis;
    float W;
    float WOffset;
}

struct Point {
    float3 Position;
    float W;
};

//StructuredBuffer<Point> Points1 : t0;         // input
//StructuredBuffer<Point> Points2 : t1;         // input
RWStructuredBuffer<Point> ResultPoints : u0;    // output

//const float ToRad = 3.141578 / 180;

[numthreads(256,4,1)]
void main(uint3 i : SV_DispatchThreadID)
//void main(uint i : SV_GroupIndex)
{
    uint index = i.x; 
    float f = (float)(index)/Count;
    float l = Radius + RadiusOffset * f;
    float angle = (StartAngle * 3.141578/180 + Cycles * 2 *3.141578 * f);
    float3 v = float3(sin(angle), cos(angle),0) * l + Center + CenterOffset * f;

    ResultPoints[index].Position = v;
    ResultPoints[index].W = W + WOffset * f;
}


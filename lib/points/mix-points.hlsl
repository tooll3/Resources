#include "hash-functions.hlsl"

cbuffer TimeConstants : register(b0)
{
    float GlobalTime;
    float Time;
    float RunTime;
    float BeatTime;
    float LastFrameDuration;
}; 
 
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


cbuffer Params : register(b2)
{
    float BlendFactor;
    float CountA;
    float CountB;
    float CombineMode;
}

struct Point {
    float3 Position;
    float W;
};

StructuredBuffer<Point> Points1 : t0;         // input
StructuredBuffer<Point> Points2 : t1;         // input
RWStructuredBuffer<Point> ResultPoints : u0;    // output

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    Point A = Points1[i.x];
    Point B = Points2[i.x];
    ResultPoints[i.x].Position =  lerp(A.Position, B.Position, BlendFactor);  // Points2[i.x].Position;//  (Points[i.x].Position + Points2[i.x].Position)*0.5;
    ResultPoints[i.x].W = lerp(A.W, B.W, BlendFactor);
}


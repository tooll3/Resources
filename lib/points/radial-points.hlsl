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

float3 RotatePointAroundAxis(float3 In, float3 Axis, float Rotation)
{
    float s = sin(Rotation);
    float c = cos(Rotation);
    float one_minus_c = 1.0 - c;

    Axis = normalize(Axis);
    float3x3 rot_mat = 
    {   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
        one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
        one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
    };
    return mul(rot_mat,  In);
}

[numthreads(256,4,1)]
void main(uint3 i : SV_DispatchThreadID)
//void main(uint i : SV_GroupIndex)
{
    uint index = i.x; 
    float f = (float)(index)/Count;
    float l = Radius + RadiusOffset * f;
    float angle = (StartAngle * 3.141578/180 + Cycles * 2 *3.141578 * f);
    float3 direction = normalize(cross(Axis, Axis.y > 0.7 ? float3(0,0,1) :  float3(0,1,0)));

    float3 v = RotatePointAroundAxis(direction * l , Axis, angle) + Center + CenterOffset * f;

    ResultPoints[index].Position = v;
    ResultPoints[index].W = W + WOffset * f;
}


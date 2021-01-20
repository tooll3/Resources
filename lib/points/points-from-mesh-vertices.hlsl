#include "hash-functions.hlsl"
#include "point.hlsl"


cbuffer Params : register(b0)
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
    float CloseCircle;
}


// cbuffer TimeConstants : register(b1)
// {
//     float GlobalTime;
//     float Time;
//     float RunTime;
//     float BeatTime;
//     float LastFrameDuration;
// }; 
 
struct PbrVertex
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
    float3 Bitangent;
    float2 TexCoord;
    float2 __padding;
};


// struct Point {
//     float3 Position;
//     float W;
// };

StructuredBuffer<PbrVertex> Vertices : t0;         // input
//StructuredBuffer<Point> Points2 : t1;         // input
RWStructuredBuffer<Point> ResultPoints : u0;    // output

// float3 RotatePointAroundAxis(float3 In, float3 Axis, float Rotation)
// {
//     float s = sin(Rotation);
//     float c = cos(Rotation);
//     float one_minus_c = 1.0 - c;

//     Axis = normalize(Axis);
//     float3x3 rot_mat = 
//     {   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
//         one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
//         one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
//     };
//     return mul(rot_mat,  In);
// }

float4 quad_from_Mat3(float3 col0, float3 col1, float3 col2)
{
    /* warning - this only works when the matrix is orthogonal and special orthogonal */

    float w = sqrt(1.0f + col0.x + col1.y + col2.z) / 2.0f;

    return float4(
        (col1.z - col2.y) / (4.0f * w),
        (col2.x - col0.z) / (4.0f * w),
        (col0.y - col1.x) / (4.0f * w),
        w);
}



[numthreads(256,4,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint index = i.x; 

    PbrVertex v = Vertices[index];

    ResultPoints[index].position = v.Position;
    ResultPoints[index].w = 1;
    //float4 quat = rotate_angle_axis(angle, normalize(Axis));
    float3x3 m = float3x3(v.Tangent, v.Bitangent, v.Normal);
    float4 rot = quad_from_Mat3(m[0], m[1], m[2]);
    //rot = qmul(rot, rotate_angle_axis(1*PI , float3(0,1,0)));
    ResultPoints[index].rotation = normalize(rot);
    //ResultPoints[index].rotation = quad_from_Mat3(v.Tangent, v.Bitangent, v.Normal);
    
    //ResultPoints[index].rotation = q_look_at(-v.Normal, float3(0,1,0));
    //ResultPoints[index].w = quat.w+ 0.5;
}



#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "particle.hlsl"

// cbuffer CountConstants : register(b0)
// {
//     int4 bufferCount;
// };

cbuffer EmitParameter : register(b0)
{
    float4 Plane;
};

cbuffer TimeConstants : register(b1)
{
    float GlobalTime;
    float Time;
    float RunTime;
    float BeatTime;
    float LastFrameDuration;
}


cbuffer Transforms : register(b2)
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

struct Face
{
    float3 positions[3];
    float2 texCoords[3];
    float3 normals[3];
    int id;
    float normalizedFaceArea;
    float cdf;
};


StructuredBuffer<Face> PointCloud : t0;
RWStructuredBuffer<Face> SlicedData : u0;

[numthreads(160,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;
    PointCloud.GetDimensions(numStructs, stride);
    if (i.x >= (uint)numStructs)
        return; 

    uint index = i.x;

    Face f = PointCloud[index];

    // if (i.x % 2 == 1)
    //     return;
    if (f.positions[0].z < Plane.w && f.positions[1].z < Plane.w && f.positions[2].z < Plane.w)
        return;

    for (uint j = 0; j < 3; j++)
    {
        if (f.positions[j].z < Plane.w)
            f.positions[j].z = Plane.w;
    }


    // float dist = dot(f.positions[0] - float3(0,0,Plane.w), Plane.xyz);
    // if (dist < 0)
        // return;

    uint targetIndex = SlicedData.IncrementCounter();
    SlicedData[targetIndex] = f;
}


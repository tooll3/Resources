#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "point.hlsl"

cbuffer Params : register(b0)
{
    float3 Center;
    float UseCamera;
    float3 Size;
}

cbuffer Transforms : register(b1)
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

// struct Point {
//     float3 Position;
//     float W;
// };

RWStructuredBuffer<Point> ResultPoints : u0; 

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;

    float3 center = Center;
    if(UseCamera > 0.5) {
        center = float3(CameraToWorld._m30, CameraToWorld._m31, CameraToWorld._m32);
    }

    ResultPoints.GetDimensions(numStructs, stride);
    if(i.x >= numStructs) {
        ResultPoints[i.x].w = sqrt(-1) ;
        return;
    }

    float3 p= mod(ResultPoints[i.x].position - center + Size/2, Size);

    if(isnan( p.x + p.y + p.x)) {
        p = Size/2;
    }


    if( abs(p.x) < 0.001) {  p.x = Size.x/2; }
    if( abs(p.y) < 0.001) {  p.y = Size.y/2; }
    if( abs(p.z) < 0.001) {  p.z = Size.z/2; }




    ResultPoints[i.x].position = p + center - Size/2;
}


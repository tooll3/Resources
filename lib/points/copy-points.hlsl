#include "hash-functions.hlsl"
#include "point.hlsl"

StructuredBuffer<Point> PointsB : t0;         // input
RWStructuredBuffer<Point> ResultPoints : u0; 



cbuffer Params : register(b0)
{
    float MixOriginal;
};


[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    ResultPoints[i.x].position = lerp(ResultPoints[i.x].position,  PointsB[i.x].position, MixOriginal);
    ResultPoints[i.x].w = lerp(ResultPoints[i.x].w,  PointsB[i.x].w, MixOriginal);
    ResultPoints[i.x].rotation = normalize(lerp(ResultPoints[i.x].rotation,  PointsB[i.x].rotation, MixOriginal));
}
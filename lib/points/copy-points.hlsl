#include "hash-functions.hlsl"
#include "point.hlsl"

StructuredBuffer<Point> PointsB : t0;         // input
RWStructuredBuffer<Point> ResultPoints : u0; 

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    ResultPoints[i.x] = PointsB[i.x];
}
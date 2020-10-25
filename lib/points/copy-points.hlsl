#include "hash-functions.hlsl"


struct Point {
    float3 Position;
    float W;
};

StructuredBuffer<Point> PointsB : t0;         // input
RWStructuredBuffer<Point> ResultPoints : u0; 

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    ResultPoints[i.x] = PointsB[i.x];
}


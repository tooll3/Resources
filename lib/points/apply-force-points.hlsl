#include "hash-functions.hlsl"
#include "noise-functions.hlsl"

cbuffer Params : register(b0)
{
    float Amount;
    float Frequency;
    float Phase;
    float Variation;
    float3 AmountDistribution;
}

struct Point {
    float3 Position;
    float W;
};

RWStructuredBuffer<Point> ResultPoints : u0; 

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    float3 variationOffset = hash31((float)(i.x%1234)/0.123 ) * Variation;

    float3 pos = ResultPoints[i.x].Position;
    //float3 noise = snoiseVec3((pos + variationOffset + Phase ) * Frequency)* (Amount/100) * AmountDistribution;


    float3 d =float3(0,1,1) - pos;
    float3 f = normalize(d) * 0.005 * length(d);

    ResultPoints[i.x].Position += float3(0,0.0,  -0.02) +f;
    ResultPoints[i.x].W += 0 ;
}


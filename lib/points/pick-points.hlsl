#include "hash-functions.hlsl"
#include "point.hlsl"

// cbuffer TimeConstants : register(b0)
// {
//     float GlobalTime;
//     float Time;
//     float RunTime;
//     float BeatTime;
//     float LastFrameDuration;
// }; 
 

cbuffer Params : register(b0)
{
    float StartIndex;
    float Scatter;
    float Seed;
}

StructuredBuffer<Point> SourcePoints : t0;        
RWStructuredBuffer<Point> ResultPoints : u0;   

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint sourceCount, stride;
    SourcePoints.GetDimensions(sourceCount, stride);

    uint resultCount, stride2;
    ResultPoints.GetDimensions(resultCount, stride2);

    if(i.x >= resultCount) {
        ResultPoints[i.x].w = sqrt(-1);
        return;
    }

    uint scatterOffset = Scatter > 0.001 
                ? (float)sourceCount * Scatter * hash11((float)i.x * 123.456 + Seed + StartIndex)
                : 0;
    

    uint index = ((uint)StartIndex + i.x + scatterOffset) % sourceCount;
    ResultPoints[i.x] = SourcePoints[index];
}


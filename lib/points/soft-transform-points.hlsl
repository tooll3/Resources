#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "point.hlsl"

cbuffer Params : register(b0)
{
    float3 Translate;
    float ScatterTranslate;

    float3 Scale;
    float ScatterRotate;

    float3 Rotate;
    float VolumeType;
    
    float3 VolumePosition;
    float SoftRadius;

    float3 VolumeSize;
    float Bias;
}

StructuredBuffer<Point> SourcePoints : t0;        
RWStructuredBuffer<Point> ResultPoints : u0;   



[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;
    SourcePoints.GetDimensions(numStructs, stride);
    if(i.x >= numStructs) {
        ResultPoints[i.x].w = 0 ;
        return;
    }

    //float3 variationOffset = hash31((float)(i.x%1234)/0.123 ) * Variation;

    Point p = SourcePoints[i.x];

    ResultPoints[i.x] = p;
}


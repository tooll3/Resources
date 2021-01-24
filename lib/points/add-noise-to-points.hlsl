#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "point.hlsl"

cbuffer TimeConstants : register(b0)
{
    float GlobalTime;
    float Time;
    float RunTime;
    float BeatTime;
    float LastFrameDuration;
}; 
 

cbuffer Params : register(b1)
{
    float Amount;
    float Frequency;
    float Phase;
    float Variation;
    float3 AmountDistribution;
    float RotationLookupDistance;

}

// struct Point {
//     float3 Position;
//     float W;
// };

StructuredBuffer<Point> Points1 : t0;         // input
RWStructuredBuffer<Point> ResultPoints : u0;    // output

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;
    Points1.GetDimensions(numStructs, stride);
    if(i.x >= numStructs) {
        ResultPoints[i.x].w = 0 ;
        return;
    }

    float3 variationOffset = hash31((float)(i.x%1234)/0.123 ) * Variation;

    Point p = Points1[i.x];
    //float3 pos = Points1[i.x].position*0.9; // avoid simplex noice glitch at -1,0,0 
    float3 lookupPos = p.position * 0.9;
    float3 noiseLookup = (lookupPos + variationOffset + Phase ) * Frequency;

    float3 noise = snoiseVec3(noiseLookup) * Amount/100 * AmountDistribution;

    float3 n = float3(1, 0.0, 0) * RotationLookupDistance;

    float3 posNormal = Points1[i.x].position*0.9; // avoid simplex noice glitch at -1,0,0 
    float3 noiseLookupNormal = (posNormal + variationOffset + Phase  ) * Frequency + n/Frequency;
    float3 noiseNormal = snoiseVec3(noiseLookup) * Amount/100 * AmountDistribution;
    float4 rotationFromDisplace = normalize(from_to_rotation(normalize(n), normalize(n+ noiseNormal) ) );

    ResultPoints[i.x].position = p.position + noise ;
    ResultPoints[i.x].rotation = qmul(rotationFromDisplace , Points1[i.x].rotation);
    ResultPoints[i.x].w = Points1[i.x].w;
    // Point A = Points1[i.x];
    // float3 variationOffset = float3(0,0,0);

    // float3 noise = snoiseVec3((A.position + variationOffset + Phase ) * Frequency)* Amount * AmountDistribution;

    // ResultPoints[i.x].position =  A.position + noise;
    // ResultPoints[i.x].w = A.w;
    // ResultPoints[i.x].rotation = A.rotation;
}


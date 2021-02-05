#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "point.hlsl"

cbuffer Params : register(b0)
{
    float Amount;
    float Subdivisions;
}

StructuredBuffer<Point> SourcePoints : t0;         // input
RWStructuredBuffer<Point> ResultPoints : u0;    // output

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint pointCount, stride;
    ResultPoints.GetDimensions(pointCount, stride);
    if(i.x >= pointCount) {
        //ResultPoints[i.x].w = 0 ;
        return;
    }

    uint sourceCount, stride2;
    SourcePoints.GetDimensions(sourceCount, stride);

    // float3 variationOffset = hash31((float)(i.x%1234)/0.123 ) * Variation;

    //Point p = SourcePoints[i.x];
    // float3 lookupPos = p.position * 0.9;
    // float3 noiseLookup = (lookupPos + variationOffset + Phase ) * Frequency;

    // float3 noise = snoiseVec3(noiseLookup) * Amount/100 * AmountDistribution;

    // float3 n = float3(1, 0.0, 0) * RotationLookupDistance;

    // float3 posNormal = SourcePoints[i.x].position*0.9; // avoid simplex noice glitch at -1,0,0 
    // float3 noiseLookupNormal = (posNormal + variationOffset + Phase  ) * Frequency + n/Frequency;
    // float3 noiseNormal = snoiseVec3(noiseLookup) * Amount/100 * AmountDistribution;
    // float4 rotationFromDisplace = normalize(from_to_rotation(normalize(n), normalize(n+ noiseNormal) ) );

    int sampleIndex = i.x / Subdivisions;
    float f = (i.x % Subdivisions) * Subdivisions;
    float offset = (int)clamp(Amount, 0, 100) * f;
    float prevIndexA = max(0, sampleIndex - offset - 1);
    float prevIndexB = max(0, sampleIndex - offset);

    float nextIndexA = min(sourceCount-1, sampleIndex + offset);
    float nextIndexB = min(sourceCount-1, sampleIndex + offset + 1);

    ResultPoints[i.x].position =   (
        lerp(SourcePoints[prevIndexA].position, SourcePoints[prevIndexB].position, (prevIndexA % 1)/f )+
        lerp(SourcePoints[nextIndexA].position, SourcePoints[prevIndexB].position, (nextIndexB % 1)/f))/2;

    ResultPoints[i.x].rotation = float4(0,0,0,1);//  p.rotation; //qmul(rotationFromDisplace , SourcePoints[i.x].rotation);
    ResultPoints[i.x].w = 1;//SourcePoints[i.x].w;
}


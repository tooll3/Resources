#include "hash-functions.hlsl"
#include "noise-functions.hlsl"

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

}

struct Point {
    float3 Position;
    float W;
};

StructuredBuffer<Point> Points1 : t0;         // input
RWStructuredBuffer<Point> ResultPoints : u0;    // output

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    Point A = Points1[i.x];
    //Point B = Points2[i.x];

    //float3 hash = hash31(index);
    // float Variation = 1;
    // float Frequency = 1;
    // float Phase = 0;
    // float Amount = 1;

    // 2 lines below only relevant for sorting
    // float3 posInCamera = mul(Particles[i.x].position, ObjectToCamera).xyz; // todo: optimize
    // AliveParticles[index].squaredDistToCamera = posInCamera.z;//dot(-WorldToCamera[2].xyz, posInCamera);

    //float3 v =  p.velocity; //float3(0,0,0)
    //float3 hash = hash31(index);
    //float3 variationOffset = (hash - 0.5)*2 * Variation;
    float3 variationOffset = float3(0,0,0);

    //float3 noise = curlNoise((A.Position + variationOffset + Phase ) * Frequency)* Amount * AmountDistribution;
    float3 noise = snoiseVec3((A.Position + variationOffset + Phase ) * Frequency)* Amount * AmountDistribution;

    ResultPoints[i.x].Position =  A.Position + noise;
    ResultPoints[i.x].W = A.W ;
}


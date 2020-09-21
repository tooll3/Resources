
#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "particle.hlsl"

cbuffer CountConstants : register(b0)
{
    int4 bufferCount;
};

cbuffer EmitParameter : register(b1)
{
    float EmitterId;
    float MaxEmitCount;
    float LifeTime;
    float EmitSize;
    float4 Color;
    float Seed;
};

cbuffer TimeConstants : register(b2)
{
    float GlobalTime;
    float Time;
    float RunTime;
    float BeatTime;
    float LastFrameDuration;
}


cbuffer Transforms : register(b3)
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

struct Vertex
{
    float3 position;
    int id;
    float3 normal;
    float normalizedFaceArea;
    float2 texCoord;
    float cdf;
    float dummy;
};

uint wang_hash(in out uint seed)
{
    seed = (seed ^ 61) ^ (seed >> 16);
    seed *= 9;
    seed = seed ^ (seed >> 4);
    seed *= 0x27d4eb2d;
    seed = seed ^ (seed >> 15);
    return seed;
}


StructuredBuffer<Vertex> PointCloud : t0;
Texture2D<float4> inputTexture : register(t1);

RWStructuredBuffer<Particle> Particles : u0;
ConsumeStructuredBuffer<ParticleIndex> DeadParticles : u1;

SamplerState linearSampler : register(s0);

[numthreads(160,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;
    PointCloud.GetDimensions(numStructs, stride);
    if (i.x >= (uint)bufferCount.x)// || i.x >= numStructs)
        return; // no particles available

    if (i.x >= MaxEmitCount)
        return;

    uint rng_state = Seed < 0 ? (i.x*3*(BeatTime + 10)) 
                              : (i.x*3*(Seed)); // todo hash12 with time as 2nd param
    float xi = (float(wang_hash(rng_state)) * (1.0 / 4294967296.0));

    // float3 hash = hash42(float2(BeatTime*1000, i.x*3*1000));
    // float xi = hash.x;

    uint cdfIndex = 0;
    while (cdfIndex < numStructs && xi > PointCloud[cdfIndex].cdf) // todo: make binary search
        cdfIndex += 3;

    uint index = cdfIndex;

    float xi1 = (float(wang_hash(rng_state)) * (1.0 / 4294967296.0));
    float xi2 = float(wang_hash(rng_state)) * (1.0 / 4294967296.0);
    Vertex v0 = PointCloud[index];
    Vertex v1 = PointCloud[index + 1];
    Vertex v2 = PointCloud[index + 2];
    // float xi1 = hash.y;
    // float xi2 = hash.z;
    float xi1Sqrt = sqrt(xi1);
    float u = 1.0 - xi1Sqrt;
    float v = xi2 * xi1Sqrt; 
    float w = 1.0 - u - v;
    float3 pos = v0.position * u + v1.position * v + v2.position * w;

    ParticleIndex pi = DeadParticles.Consume();
    Particle particle = Particles[pi.index];

    //float scale = 2;
    particle.position = mul(float4(pos.xyz,1), ObjectToWorld);
    particle.emitterId = EmitterId;
    particle.lifetime = LifeTime;
    particle.emitTime = BeatTime;
    float size = EmitSize * Seed;
    particle.size = float2(size, size);
    particle.velocity = 0;//v0.normal*10;
    float2 texCoord = v0.texCoord * u + v1.texCoord * v + v2.texCoord * w;
    texCoord.y = 1.0 - texCoord.y;
    float4 color = inputTexture.SampleLevel(linearSampler, texCoord, 0) * Color;
    particle.color = color;

    Particles[pi.index] = particle;
}


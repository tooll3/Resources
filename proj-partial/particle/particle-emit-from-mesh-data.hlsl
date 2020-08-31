
#include "particle.hlsl"

cbuffer CountConstants : register(b0)
{
    int4 bufferCount;
}

cbuffer Transforms : register(b1)
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
    float dummy;
    float2 texCoord;
    float2 dummy2;
};

StructuredBuffer<Vertex> PointCloud : s0;

RWStructuredBuffer<Particle> Particles : u0;
ConsumeStructuredBuffer<ParticleIndex> DeadParticles : u1;

[numthreads(160,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;
    PointCloud.GetDimensions(numStructs, stride);
    if (i.x >= (uint)bufferCount.x || i.x >= numStructs)
        return; // no particles available

    Vertex v = PointCloud[i.x];
    ParticleIndex pi = DeadParticles.Consume();

    Particle particle = Particles[pi.index];

    particle.position = v.position*50.0;
    particle.emitterId = 2;//p.id;
    particle.lifetime = 100.0;
    particle.size = float2(5, 5);
    particle.velocity = v.normal;
    particle.color = float4(v.texCoord, 0, 1);

    Particles[pi.index] = particle;
}


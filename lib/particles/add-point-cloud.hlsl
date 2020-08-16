
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

struct Point
{
    float3 position;
    int id;
    float4 color;
};

StructuredBuffer<Point> PointCloud : s0;

RWStructuredBuffer<Particle> Particles : u0;
ConsumeStructuredBuffer<ParticleIndex> DeadParticles : u1;

[numthreads(160,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    if (i.x >= bufferCount.x)
        return; // no particles available

    float3 direction = float3(1, 0, 0);
    ParticleIndex pi = DeadParticles.Consume();
        
    Particle particle = Particles[pi.index];
    Point p = PointCloud[i.x];

    particle.position = p.position;
    particle.emitterId = p.id;
    particle.lifetime = 10000.0;
    particle.velocity = float3(0,0,0);
    particle.color = p.color;

    Particles[pi.index] = particle;
}


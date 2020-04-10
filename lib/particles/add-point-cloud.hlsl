
#include "particle.hlsl"

cbuffer TimeConstants : register(b0)
{
    float globalTime;
    float time;
    float runTime;
    float dummy;
}

cbuffer CountConstants : register(b1)
{
    int4 bufferCount;
}

struct Point
{
    float4 position;
    float4 color;
};

StructuredBuffer<Point> PointCloud : s0;

RWStructuredBuffer<Particle> Particles : u0;
ConsumeStructuredBuffer<int> DeadParticles : u1;

[numthreads(160,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    if (i.x >= bufferCount.x)
        return; // no particles available

    float3 direction = float3(1, 0, 0);
    int index = DeadParticles.Consume();
        
    Particle particle = Particles[index];
    Point p = PointCloud[i.x];

    particle.position = p.position*10.0;
    particle.lifetime = 10000.0;
    particle.velocity = float3(0,0,0);
    particle.color = p.color;

    Particles[index] = particle;
}


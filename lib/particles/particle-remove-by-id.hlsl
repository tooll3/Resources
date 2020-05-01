#include "particle.hlsl"

cbuffer CountConstants : register(b0)
{
    int4 bufferCount;
}

cbuffer RemoveConstants : register(b1)
{
    float idToRemove;
}

RWStructuredBuffer<Particle> Particles : u0;
RWStructuredBuffer<int> AliveParticles : u1;
AppendStructuredBuffer<int> DeadParticles : u2;

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    if (i.x >= bufferCount.x)
        return; // only check alive particles

    int index = AliveParticles[i.x];
    Particle particle = Particles[index];
    if (particle.lifetime >= 0.0 && particle.id == (int)(idToRemove + 0.5))
    {
        particle.lifetime = -1.0;
        particle.id = -1;
        DeadParticles.Append(index);
        // AliveParticles.Consume(i.x);
        Particles[index] = particle;
    }
}


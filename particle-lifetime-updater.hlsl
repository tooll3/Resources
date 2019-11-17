

cbuffer TimeConstants : register(b0)
{
    float globalTime;
    float time;
    float2 dummy;
}

cbuffer CountConstants : register(b1)
{
    int4 bufferCount;
}

struct Particle
{
    float3 position;
    float lifetime;
    float3 velocity;
    float dummy;
    float4 color;
};

RWStructuredBuffer<Particle> Particles : u0;
RWStructuredBuffer<int> AliveParticles : u1;
AppendStructuredBuffer<int> DeadParticles : u2;

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    float oldLifetime = Particles[i.x].lifetime;
    float newLifetime = oldLifetime - (1.0/60.0);

    if (newLifetime < 0.0)
    {
        if (oldLifetime >= 0.0)
            DeadParticles.Append(i.x);
    }
    else
    {
        uint index = AliveParticles.IncrementCounter();
        AliveParticles[index] = i.x;
        Particles[i.x].position += (1.0/60.)*Particles[i.x].velocity;
    }

    Particles[i.x].lifetime = newLifetime;
}


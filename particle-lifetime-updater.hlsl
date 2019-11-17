

cbuffer TimeConstants : register(b0)
{
    float globalTime;
    float time;
    float2 dummy;
}

cbuffer ParamConstants : register(b1)
{
    float param1;
    float param2;
    float param3;
    float param4;
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
    float lifetime = Particles[i.x].lifetime;
    lifetime -= (1.0/60.0);

    if (lifetime < 0.0)
    {
        DeadParticles.Append(i.x);
    }
    else
    {
        uint index = AliveParticles.IncrementCounter();
        AliveParticles[index] = i.x;
    }

    Particles[i.x].lifetime = lifetime;
}


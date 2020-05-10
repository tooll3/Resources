#include "particle.hlsl"

cbuffer TimeConstants : register(b0)
{
    float GlobalTime;
    float Time;
    float RunTime;
    float BeatTime;
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

cbuffer CountConstants : register(b2)
{
    int4 BufferCount;
}

// cbuffer Params : register(b3)
// {
//     float4 Color;
//     float EmitPosY;
//     float EmitPosYScatter;
//     float Size;
//     float Mass;
//     float LifeTime;    
// }


Texture2D<float4> inputTexture : register(t0);
SamplerState linearSampler : register(s0);
RWStructuredBuffer<Particle> Particles : u0;
ConsumeStructuredBuffer<int> DeadParticles : u1;

uint wang_hash(in out uint seed)
{
    seed = (seed ^ 61) ^ (seed >> 16);
    seed *= 9;
    seed = seed ^ (seed >> 4);
    seed *= 0x27d4eb2d;
    seed = seed ^ (seed >> 15);
    return seed;
}

[numthreads(9,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    if (i.x >= BufferCount.x)
       return; // no particles available

    int index = DeadParticles.Consume();
        
    Particle particle = Particles[index];
    uint rng_state = uint(RunTime*1000.0)*10 + i.x;

    float u = float(wang_hash(rng_state)) * (1.0 / 4294967296.0);
    float v = float(wang_hash(rng_state)) * (1.0 / 4294967296.0);
    float4 color = inputTexture.SampleLevel(linearSampler, float2(u, v), 0);

    float2 size = float2(1.0, 1.0);
    float4 posInObject = float4((u - 0.5)*size.x, (v - 0.5)*size.y, 0, 1);
    particle.position = mul(posInObject, ObjectToWorld);
    particle.lifetime = 5.0;//LifeTime;
    particle.velocity = float3(0,0,0);
    particle.color = color;//float4(1,0,0,1);

    Particles[index] = particle;    
}


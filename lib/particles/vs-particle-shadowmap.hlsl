#include "particle.hlsl"

static const float3 Quad[] = 
{
  float3(-1, -1, 0),
  float3( 1, -1, 0), 
  float3( 1,  1, 0), 
  float3( 1,  1, 0), 
  float3(-1,  1, 0), 
  float3(-1, -1, 0), 
};

cbuffer Transforms : register(b0)
{
    float4x4 clipSpaceTcamera;
    float4x4 cameraTclipSpace;
    float4x4 cameraTworld;
    float4x4 worldTcamera;
    float4x4 clipSpaceTworld;
    float4x4 worldTclipSpace;
    float4x4 worldTobject;
    float4x4 objectTworld;
    float4x4 cameraTobject;
    float4x4 clipSpaceTobject;
};

cbuffer Params : register(b1)
{
    float size;
}

struct Output
{
    float4 position : SV_POSITION;
    float4 mask : MASK;
};

StructuredBuffer<Particle> Particles : t0;
StructuredBuffer<int> AliveParticles : t1;

Output vsMain(uint id: SV_VertexID)
{
    Output output;

    int quadIndex = id % 6;
    int particleId = id / 6;
    float3 quadPos = Quad[quadIndex];
    Particle particle = Particles[AliveParticles[particleId]];
    float4 cameraPparticleQuadPos = mul(cameraTobject, float4(particle.position,1));
    cameraPparticleQuadPos.xy += quadPos.xy*0.0250;//*6.0;// * size;
    output.position = mul(clipSpaceTcamera, cameraPparticleQuadPos);
    float z = output.position.z;
    output.mask = clamp(floor(fmod(float4(z, z, z, z) + float4(1.0, 0.75, 0.50, 0.25), float4(1.25, 1.25, 1.25, 1.25))), float4(0, 0, 0, 0), float4(1, 1, 1, 1));

    return output;
}


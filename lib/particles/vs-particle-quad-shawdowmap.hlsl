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

cbuffer ShadowTransforms : register(b1)
{
    float4x4 shadow_clipSpaceTcamera;
    float4x4 shadow_cameraTclipSpace;
    float4x4 shadow_cameraTworld;
    float4x4 shadow_worldTcamera;
    float4x4 shadow_clipSpaceTworld;
    float4x4 shadow_worldTclipSpace;
    float4x4 shadow_worldTobject;
    float4x4 shadow_objectTworld;
    float4x4 shadow_ameraTobject;
    float4x4 shadow_clipSpaceTobject;
};

struct Output
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
    float4 color : COLOR;
    float4 world_P : POSITION;
};

StructuredBuffer<Particle> Particles : t0;
StructuredBuffer<int> AliveParticles : t1;

Texture2D<float4> inputTexture : register(t2);
sampler texSampler : register(s0);

Output vsMain(uint id: SV_VertexID)
{
    Output output;

    int quadIndex = id % 6;
    int particleId = id / 6;
    float3 quadPos = Quad[quadIndex];
    Particle particle = Particles[AliveParticles[particleId]];
    float4 cameraPparticleQuadPos = mul(cameraTobject, float4(particle.position,1));
    cameraPparticleQuadPos.xy += quadPos.xy*0.250;//*6.0;// * size;
    output.position = mul(clipSpaceTcamera, cameraPparticleQuadPos);
    output.world_P = mul(worldTobject, float4(particle.position, 1));

    output.color = float4(1,1,1,1);//particle.color;
    output.texCoord = (quadPos.xy * 0.5 + 0.5);

    return output;
}


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

struct Output
{
    float4 position : SV_POSITION;
    float4 color : COLOR;
    float2 texCoord : TEXCOORD;
};

StructuredBuffer<Particle> Particles : t0;
StructuredBuffer<ParticleIndex> AliveParticles : t1;

Texture2D<float4> inputTexture : register(t2);
sampler texSampler : register(s0);

Output vsMain(uint id: SV_VertexID)
{
    Output output;

    int quadIndex = id % 6;
    int particleId = id / 6;
    float3 quadPos = Quad[quadIndex];
    Particle particle = Particles[AliveParticles[particleId].index];
    float4 quadPosInCamera = mul(float4(particle.position,1), ObjectToCamera);
    quadPosInCamera.xy += quadPos.xy*0.250 * (sin(particle.lifetime) + 1)/20;//*6.0;// * size;
    output.position = mul(quadPosInCamera, CameraToClipSpace);

    output.color = particle.color;
    output.texCoord = (quadPos.xy * 0.5 + 0.5);

    return output;
}


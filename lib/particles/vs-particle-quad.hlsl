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
    output.world_P = mul(worldTcamera, cameraPparticleQuadPos);
    output.world_P = mul(worldTobject, float4(particle.position, 1));

    // float4x4 shadowClipSpaceTobject = mul(shadow_clipSpaceTworld, worldTobject);
    // float4 scsPparticlePos = mul(shadowClipSpaceTobject, float4(particle.position, 1));
    // scsPparticlePos.xyz /= scsPparticlePos.w;
    // scsPparticlePos.xy = scsPparticlePos.xy*0.5 + 0.5;
    // scsPparticlePos.y = 1.0-scsPparticlePos.y;
    // float sz = scsPparticlePos.z;
    output.color = float4(1,1,1,1);//particle.color;
    // float4 om = inputTexture.SampleLevel(texSampler, scsPparticlePos.xy, 0);
    // float4 mask0 = saturate((float4(sz,sz,sz,sz) - float4(0.00, 0.25, 0.50, 0.75)) * 4.0);
    // om *= mask0;
    // // om *= 0.25;
    // float occlusion = 1.0 - saturate(om.x + om.y + om.z + om.w);
    // output.color.rgba *= occlusion;
    // // output.color.a = 0.5;
    float lifetime = 0.0;//1.0 - occlusion;//1.0 - saturate(particle.lifetime/14.0);
    float particleType = 7.0/8.0;//float(AliveParticles[particleId] % 8)/8.0;
    output.texCoord = (quadPos.xy * 0.5 + 0.5)/float2(16.0, 8.0) + float2(floor(lifetime*16.0)/16.0, particleType); 
    // output.texCoord = (quadPos.xy * 0.5 + 0.5);

    return output;
}


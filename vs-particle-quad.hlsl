
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
};

struct Particle
{
    float3 position;
    float lifetime;
    float3 velocity;
    float dummy;
    float4 color;
};

struct Output
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
    float4 color : COLOR;
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
    float4 cameraPparticleQuadPos = mul(cameraTworld, float4(particle.position,1));
    cameraPparticleQuadPos.xy += quadPos.xy*10.0;
    output.position = mul(clipSpaceTcamera, cameraPparticleQuadPos);
    output.color = particle.color;
    float lifetime = 1.0 - saturate(particle.lifetime);
    float particleType = float(AliveParticles[particleId] % 8)/8.0;
    output.texCoord = (quadPos.xy * 0.5 + 0.5)/float2(16.0, 8.0) + float2(floor(lifetime*16.0)/16.0, particleType); 

    return output;
}


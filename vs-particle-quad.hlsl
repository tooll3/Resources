
static const float3 Quad[] = 
{
  float3(-1, -1, 0),
  float3(1, -1, 0), 
  float3(-1, 1, 0), 
  float3(-1, 1, 0), 
  float3(1, -1, 0), 
  float3(1, 1, 0), 
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
};

StructuredBuffer<Particle> Particles : u0;
StructuredBuffer<int> AliveParticles : u1;

Output main(uint id: SV_VertexID)
{
    Output output;

    int quadIndex = id % 6;
    int particleId = id / 6;
    float3 quadPos = Quad[quadIndex];
    Particle particle = Particles[AliveParticles[particleId]];
    output.position = float4(particle.position + quadPos, 1.0);
 //   output.texCoord = float2((id << 1) & 2, id & 2);

    return output;
}


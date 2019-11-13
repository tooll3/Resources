
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
    // float2 texCoord : TEXCOORD;
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
    // Particle particle = Particles[particleId];
    output.position = float4(particle.position*0.01 + quadPos*0.1/abs(particle.position.z), 1.0);
    output.position.x *= 9.0/16.0;
    output.color = particle.color;
    output.color.a = saturate(particle.lifetime);
 //   output.texCoord = float2((id << 1) & 2, id & 2);

    return output;
}


float4 psMain(Output input) : SV_TARGET
{
    return input.color;
    // return float4(1,0,1,1);
}

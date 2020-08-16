
struct Particle
{
    float3 position;
    float lifetime;
    float3 velocity;
    float mass;
    float4 color;
    int emitterId;
    float3 normal;
};

struct ParticleIndex
{
    int index;
    float squaredDistToCamera;
};

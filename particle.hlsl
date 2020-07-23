
struct Particle
{
    float3 position;
    float lifetime;
    float3 velocity;
    float mass;
    float4 color;
    int id;
    float3 dummy;
};

struct IndexEntry
{
    int index;
    float squaredDistInCameraSpace; // for sorting
};

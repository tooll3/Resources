
#include "particle.hlsl"

cbuffer CountConstants : register(b0)
{
    int4 bufferCount;
}

cbuffer Transforms : register(b1)
{
    float4x4 clipSpace_T_camera;
    float4x4 camera_T_clipSpace;
    float4x4 camera_T_world;
    float4x4 world_T_camera;
    float4x4 clipSpace_T_world;
    float4x4 world_T_clipSpace;
    float4x4 world_T_object;
    float4x4 object_T_world;
    float4x4 camera_T_object;
    float4x4 clipSpace_T_object;
};

struct Point
{
    float3 position;
    int id;
    float4 color;
};

StructuredBuffer<Point> PointCloud : s0;

RWStructuredBuffer<Particle> Particles : u0;
ConsumeStructuredBuffer<int> DeadParticles : u1;

[numthreads(160,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    if (i.x >= bufferCount.x)
        return; // no particles available

    float3 direction = float3(1, 0, 0);
    int index = DeadParticles.Consume();
        
    Particle particle = Particles[index];
    Point p = PointCloud[i.x];

    particle.position = p.position;
    particle.id = p.id;
    particle.lifetime = 10000.0;
    particle.velocity = float3(0,0,0);
    particle.color = p.color;

    Particles[index] = particle;
}


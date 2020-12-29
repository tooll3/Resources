#include "hash-functions.hlsl"
#include "point.hlsl"

cbuffer ParamConstants : register(b0)
{
    float AgentCount;
    float2 BlockCount;
}

cbuffer ResolutionBuffer : register(b1)
{
    float TargetWidth;
    float TargetHeight;
};

struct Boid
{
    float CohesionRadius;
    float CohesionDrive;
    float AlignmentRadius;
    float AlignmentDrive;
    float SeparationRadius;
    float SeparationDrive;
    float _padding1;
    float _padding2;
};

struct Agent {
    float3 Position;
    float BoidType;
    //float Rotation;
    float4 SpriteOrientation;
};

#define mod(x,y) ((x)-(y)*floor((x)/(y)))

sampler texSampler : register(s0);
Texture2D<float4> InputTexture : register(t0);

RWStructuredBuffer<Boid> BoidsTypes : register(u0); 
RWStructuredBuffer<Agent> Agents : register(u1); 

static int2 block;

static const float ToRad = 3.141592/180;

#define CB BoidsTypes[breedIndex]

[numthreads(256,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{   
    if(i.x >= (uint)AgentCount)
        return;

    block = int2(i.x % BlockCount.x,  i.x / BlockCount.x % BlockCount.y);

    // int texWidth;
    // int texHeight;
    // WriteOutput.GetDimensions(texWidth, texHeight);

    float angle = i.x / 1000;
    float3 pos = Agents[i.x].Position;
    //float angle = Agents[i.x].w;

    float hash =hash11(i.x * 123.1);

    // float dir = -SoftLimit(( min(leftComfort.r, frontComfort.r ) -  min(rightComfort.r, frontComfort.r)), 1);
    
    //float3 aspectRatio = float3(TargetWidth / BlockCount.x /((float)TargetHeight / BlockCount.y),1,1);
    //pos = (mod((pos  / aspectRatio + 1),2) - 1) * aspectRatio; 
    //Agents[i.x].Position = float3(0,0,0);
    Agents[i.x].Position = pos;
    Agents[i.x].SpriteOrientation = rotate_angle_axis(-angle, float3(0,0,1));

}
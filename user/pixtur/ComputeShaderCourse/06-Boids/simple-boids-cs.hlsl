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
    float MaxSpeed;
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

//groupshared Agent SharedAgents[4096];

static const float3 FORWARD = float3(0,1,0);
static const float3 UP = float3(0,0,1);

[numthreads(1024,1,1)]
//void main(uint3 i : SV_DispatchThreadID)
void main(uint3 Gid : SV_GroupID, uint3 i : SV_DispatchThreadID, uint3 GTid : SV_GroupThreadID, uint GI : SV_GroupIndex)
{
    if(i.x >= (uint)AgentCount)
        return;

    //SharedAgents[GI] = Agents[i.x];

    //GroupMemoryBarrierWithGroupSync();    // Doesn't work

    Agent agent = Agents[i.x];
    //GroupMemoryBarrier();

    block = int2(i.x % BlockCount.x,  i.x / BlockCount.x % BlockCount.y);

    // Rotate back
    float3 velocity = rotate_vector(FORWARD, Agents[i.x].SpriteOrientation) * BoidsTypes[0].MaxSpeed; 
    // float3 anchorPosition = 0;
    // float anchorRadius = 1.2;
    // float3 distanceToAnchor = anchorPosition - agent.Position;
    // float r = length(distanceToAnchor) / anchorRadius;
    // float rotateBack = saturate(r - 1);
    // if (rotateBack > 0.01f)
    // {
    //     if(dot( normalize(-distanceToAnchor), normalize(-velocity)) < -.5) 
    //     {
    //         float3 crossVector = cross(normalize(velocity), normalize(distanceToAnchor));
    //         float4 rotBack = rotate_angle_axis( i.x % 2== 0 ? 0.02 : -0.02, UP);
    //         //velocity +=  rotate_vector(velocity, rotateBack);
    //         //velocity = 0;

    //         agent.SpriteOrientation = qmul(agent.SpriteOrientation, rotateBack);
    //         //agent.Position.z = -4;
    //     }
    //     velocity +=  distanceToAnchor* smoothstep(0,1, rotateBack) * 0.1;
    //     agent.Position +=distanceToAnchor* smoothstep(0,1, rotateBack) * 0.01;
    // }
    agent.Position.z =0;


    float3 centerForCohesion;
    int countForCohesion =0;

    float3 centerForSeparation;
    int countForSeparation =0;

    float3 averageVelocity;
    int countForAlignment =0;

    for(int index =0; index < AgentCount; index++)
    {
        float3 otherPos = Agents[index].Position;
        float distance =  length(otherPos - agent.Position);

        if(distance < BoidsTypes[0].AlignmentRadius)
        {
            averageVelocity += rotate_vector(FORWARD, Agents[index].SpriteOrientation);
            countForAlignment++;
        }

        if(distance < BoidsTypes[0].CohesionRadius)
        {
            centerForCohesion += Agents[index].Position;
            countForCohesion++;
        }

        if(distance < BoidsTypes[0].SeparationRadius)
        {
            centerForSeparation += Agents[index].Position;
            countForSeparation++;
        }
    }

    centerForCohesion /= countForCohesion;
    centerForSeparation /= countForSeparation;
    averageVelocity /= countForAlignment;
    //averageVelocity.z =0;
    //averageVelocity = normalize(averageVelocity);

    // Effect Texture
    float4 c = InputTexture.SampleLevel(texSampler, float2((agent.Position.xy+0.5) * 1), 0);

    // Aligment
    //float3 toAverage = centerForCohesion - agent.Position + (c.r-0.5) * 0.5;

    //agent.Position += toAverage * BoidsTypes[0].CohesionDrive;

    float4 averageRotation = rotate_angle_axis(atan2(averageVelocity.y, averageVelocity.x) - 3.141592/2, UP);//  q_look_at(averageVelocity, UP);
    agent.SpriteOrientation = q_slerp(agent.SpriteOrientation, averageRotation, BoidsTypes[0].AlignmentDrive);

    

    // Cohesion
    velocity += -(agent.Position - centerForCohesion) * BoidsTypes[0].CohesionDrive;
    
    // Separation
    velocity += (agent.Position - centerForSeparation) * BoidsTypes[0].SeparationDrive;





    agent.Position += normalize(velocity) * BoidsTypes[0].MaxSpeed;
    //velocity.z =0;


    agent.Position = mod(agent.Position + 1, 2) - 1;

    

    //GroupMemoryBarrierWithGroupSync();


    //float3 pos = Agents[i.x].Position + forward * BoidsTypes[0].CohesionRadius;

    Agents[i.x].Position = agent.Position;
    Agents[i.x].SpriteOrientation = normalize(agent.SpriteOrientation);
}
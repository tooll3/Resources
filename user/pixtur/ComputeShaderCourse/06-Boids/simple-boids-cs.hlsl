#include "hash-functions.hlsl"
#include "point.hlsl"

cbuffer ParamConstants : register(b0)
{
    float AgentCount;
    float2 BlockCount;
    float FrameCount;
    float EffectLayer;
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
    float _padding;
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


static const float3 FORWARD = float3(0,1,0);
static const float3 UP = float3(0,0,1);

//groupshared Agent SharedAgents[1024];

static const int SLICE = 1024;

[numthreads(1024,1,1)]
void main(uint3 Gid : SV_GroupID, uint3 i : SV_DispatchThreadID, uint3 GTid : SV_GroupThreadID, uint GI : SV_GroupIndex)
{
    if(i.x >= (uint)AgentCount)
        return;

    //uint otherIndex = ((uint)FrameCount * SLICE + i.x) % (uint) AgentCount;
    //SharedAgents[GI] = Agents[otherIndex];

    GroupMemoryBarrier();
    Agent agent = Agents[i.x];

    block = int2(i.x % BlockCount.x,  i.x / BlockCount.x % BlockCount.y);

    // Rotate back
    float3 direction = rotate_vector(FORWARD, Agents[i.x].SpriteOrientation); 
    direction.z=0;

    float3 pos = Agents[i.x].Position;
    pos.z = 0;

    float3 centerForCohesion;
    int countForCohesion =0;

    float3 centerForSeparation;
    int countForSeparation =0;

    float3 averageDirection;
    int countForAlignment =0;

    for(int index =0; index < AgentCount; index++)
    {
        if(index == i.x)
            continue;

        float3 otherPos = Agents[index].Position;
        float distance =  length(otherPos - pos);

        if(distance < BoidsTypes[0].AlignmentRadius)
        {
            averageDirection += rotate_vector(FORWARD, Agents[index].SpriteOrientation);
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

    ;
    centerForCohesion /= countForCohesion;




    // Aligment
    if(countForAlignment > 0) 
    {
        averageDirection /= countForAlignment;
        float l = length(averageDirection);
        if(l > 0.01) {
            //float3 steerAlignment =   averageDirection/l - direction;
            direction = lerp(direction, averageDirection/l, BoidsTypes[0].AlignmentDrive);
        }
    }

    // Cohesion
    //velocity += -(pos - centerForCohesion) * BoidsTypes[0].CohesionDrive;
    //direction = lerp(direction,-(pos - centerForCohesion), BoidsTypes[0].CohesionDrive );
    
    // Separation
    if(countForSeparation > 0) 
    {
        centerForSeparation /= countForSeparation;        
        float3 toSeparation = pos - centerForSeparation;
        float lenToSeparation = length(pos - centerForSeparation);
        if(lenToSeparation > 0.01) {
            direction = lerp(direction, toSeparation / lenToSeparation, BoidsTypes[0].SeparationDrive );
        }
    }

    // Cohesion
    if(countForCohesion > 0) 
    {
        centerForCohesion /= countForCohesion;        
        float3 toCohesion = -(pos - centerForCohesion);
        float lenToCohesion = length(pos - centerForCohesion);
        if(lenToCohesion > 0.01) {
            direction = lerp(direction, toCohesion / lenToCohesion, BoidsTypes[0].CohesionDrive );
        }
    }



    // Effect Texture
    float2 uv= (pos.xy * 0.5) +0.5;
    uv = float2(uv.x, 1- uv.y);
    float4 c = InputTexture.SampleLevel(texSampler, uv, 0);
    direction.xy -= c.xy * EffectLayer;


    float len = length(direction);
    if(isnan(len) || len == 0) 
    {
         direction = float3(-1,-1,0);
    }
    else 
    {
        direction /= len;
    }
    

    pos += direction * BoidsTypes[0].MaxSpeed;
    pos = mod(pos + 1, 2) - 1;
    
    float4 rot = Agents[i.x].SpriteOrientation;
    
    // Use look at velocity rotation and rotate back into xy plane
    rot = normalize(q_look_at(direction, float3(0,0,1)));
    rot = qmul(rot, rotate_angle_axis(0.5*PI , float3(1,0,0)));

    // 2d-rotation around z
    //rot = rotate_angle_axis( atan2(velocity.x, velocity.y), float3(0,0,-1));

    Agents[i.x].SpriteOrientation = rot;
    Agents[i.x].Position = pos;
}
#include "hash-functions.hlsl"
#include "point.hlsl"

cbuffer ParamConstants : register(b0)
{
    float DecayRate;
}

cbuffer TimeConstants : register(b1)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

struct Cell {
    int State;
};

#define mod(x,y) ((x)-(y)*floor((x)/(y)))

//Texture2D<float4> GradientTexture : register(t0);
sampler texSampler : register(s0);

RWTexture2D<float4> WriteOutput  : register(u0); 
RWStructuredBuffer<Point> Points : register(u1); 

// Using a threadcount matching 1920 and 1080
[numthreads(30,30,1)]
void main(uint3 i : SV_DispatchThreadID)
{   
    int texWidth;
    int texHeight;
    WriteOutput.GetDimensions(texWidth, texHeight);

    float d = 0.998;
    WriteOutput[i.xy] *= float4(DecayRate.xxx, 1);

    // Blur grid
    // Nine neighbours doesn't give a noticable quality benefit
    // float4 sumNeighbours = 
    //             (0
    //             +WriteOutput[i.xy + int2(0, 1)]
    //             +WriteOutput[i.xy + int2(0, -1)]
    //             +WriteOutput[i.xy + int2(-1, 0)]
    //             +WriteOutput[i.xy + int2(+1, 0)]

    //             +WriteOutput[i.xy + int2(0, 2)] /2
    //             +WriteOutput[i.xy + int2(0, -2)]/2
    //             +WriteOutput[i.xy + int2(-2, 0)]/2
    //             +WriteOutput[i.xy + int2(+2, 0)]/2              

    //             +WriteOutput[i.xy]                
    //             )/7;

    int2 res= int2(texWidth, texHeight);

    float4 sumNeighbours = 
                (0
                +WriteOutput[(i.xy + int2(0, 1)) % res]
                +WriteOutput[(i.xy + int2(0, -1)) % res]
                +WriteOutput[(i.xy + int2(-1, 0)) % res]
                +WriteOutput[(i.xy + int2(+1, 0)) % res]
                +WriteOutput[i.xy]                
                )/5;

    
    WriteOutput[i.xy] = sumNeighbours * DecayRate;
}

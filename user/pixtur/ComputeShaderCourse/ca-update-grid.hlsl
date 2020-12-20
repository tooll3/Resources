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

[numthreads(16,16,1)]
void main(uint3 i : SV_DispatchThreadID)
{   
    int texWidth;
    int texHeight;
    WriteOutput.GetDimensions(texWidth, texHeight);

    float d = 0.998;
    WriteOutput[i.xy] *= float4(DecayRate.xxx, 1);


    // Blur grid
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


    float4 sumNeighbours = 
                (0
                +WriteOutput[i.xy + int2(0, 1)]
                +WriteOutput[i.xy + int2(0, -1)]
                +WriteOutput[i.xy + int2(-1, 0)]
                +WriteOutput[i.xy + int2(+1, 0)]

                // +WriteOutput[i.xy + int2(0, 2)] /2
                // +WriteOutput[i.xy + int2(0, -2)]/2
                // +WriteOutput[i.xy + int2(-2, 0)]/2
                // +WriteOutput[i.xy + int2(+2, 0)]/2              

                +WriteOutput[i.xy]                
                )/5;

    
    WriteOutput[i.xy] = sumNeighbours;
    //AllMemoryBarrier();
}

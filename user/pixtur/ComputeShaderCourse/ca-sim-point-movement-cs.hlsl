#include "hash-functions.hlsl"
#include "point.hlsl"

cbuffer ParamConstants : register(b0)
{
    float RadiusFactor;
    // float HeightF;
    // float HistoryStepsF;
    // float NumStates;
    // float NeighbourCountF;
    // float MousePosX;
    // float MousePosY;
    // float MouseDown;
    // float Reset;
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
// RWStructuredBuffer<Cell> WriteField : register(u1); 
// RWStructuredBuffer<Cell> TransitionFunctions : register(u2); 
// RWTexture2D<float4> WriteOutput  : register(u3); 
//StructuredBuffer<Point> Points : t0;
//Texture2D<float4> texture2 : register(t1);


static const int NeighbourCount = 1;

[numthreads(256,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{   
    int texWidth;
    int texHeight;
    WriteOutput.GetDimensions(texWidth, texHeight);
    float angle= Points[i.x].w * (RadiusFactor + beatTime);

    float3 pos = Points[i.x].position;
    pos += float3(sin(angle),cos(angle),0) * 0.1;
    pos = mod(pos + 1,2)-1; 

    // Map coordinates to grid
    Points[i.x].position = pos;
    float2 gridPos = (pos.xy * float2(1,-1) +1)  * float2(texWidth, texHeight)/2;
    int2 celAddress = int2(gridPos.x, gridPos.y);

    WriteOutput[celAddress] += 1.3;

}

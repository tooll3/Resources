#include "hash-functions.hlsl"
#include "point.hlsl"

cbuffer ParamConstants : register(b0)
{
    float RadiusFactor;
    float TrailEnergy;

    float SampleDistance;
    float SampleAngle;

    float MoveDistance;
    float RotateAngle;

    float RerferenceEnergy;

    float AgentCount;
    float SnapToAnglesCounts;
    float SnapToAnglesRatio;
}

cbuffer TimeConstants : register(b1)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

cbuffer ResolutionBuffer : register(b2)
{
    float TargetWidth;
    float TargetHeight;
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

int2 cellAddressFromPosition(float3 pos) 
{
    float2 gridPos = (pos.xy * float2(1,-1) +1)  * float2(TargetWidth, TargetHeight)/2;
    int2 celAddress = int2(gridPos.x, gridPos.y);
    return celAddress;
}

// Rounds an input value i to steps values
// See: https://www.desmos.com/calculator/qpvxjwnsmu
float RoundValue(float i, float stepsPerUnit, float stepRatio) 
{
    float u = 1 / stepsPerUnit;
    float v = stepRatio / (2 * stepsPerUnit);
    float m = i % u;
    float r = m - (m < v
                    ? 0
                    : m > (u - v)
                        ? u
                        : (m - v) / (1 - 2 * stepsPerUnit * v));
    float y = i - r;
    return y;
}

static const float ToRad = 3.141592/180;

[numthreads(256,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{   
    int texWidth;
    int texHeight;
    WriteOutput.GetDimensions(texWidth, texHeight);

    float3 pos = Points[i.x].position;
    float angle = Points[i.x].w;

    float3 leftSamplePos = pos + float3(sin(angle - SampleAngle*ToRad),cos(angle - SampleAngle*ToRad),0) * SampleDistance;
    int2 leftSampleAddress = cellAddressFromPosition(leftSamplePos);
    float4 leftSample = WriteOutput[leftSampleAddress];
    
    float3 rightSamplePos = pos + float3(sin(angle + SampleAngle*ToRad),cos(angle + SampleAngle*ToRad),0) * SampleDistance;
    int2 rightSampleAddress = cellAddressFromPosition(rightSamplePos);
    float4 rightSample = WriteOutput[rightSampleAddress] ;

    float leftValue = abs(leftSample.r - RerferenceEnergy);
    float rightValue = abs(rightSample.r - RerferenceEnergy);
    float rotateDirection = leftValue - rightValue;// rightSample.r;
    
    angle += rotateDirection * RotateAngle*ToRad;
    angle = mod(angle, 2 * 3.141592);
    float roundedAngle = RoundValue(angle, SnapToAnglesCounts/(2*3.141592), SnapToAnglesRatio) + 0.8;
    pos += float3(sin(roundedAngle),cos(roundedAngle),0) * MoveDistance;
    Points[i.x].w = roundedAngle;
    
    //float angle= (Points[i.x].w * RadiusFactor) + beatTime * Points[i.x].w;

    //pos += float3(sin(angle),cos(angle),0) * 0.03;

    // Map coordinates to grid
    pos = mod(pos + 1,2)-1; 
    Points[i.x].position = pos;
    Points[i.x].rotation = rotate_angle_axis(-roundedAngle, float3(0,0,1));
    

    // Update map
    float2 gridPos = (pos.xy * float2(1,-1) +1)  * float2(texWidth, texHeight)/2;
    int2 celAddress = int2(gridPos.x, gridPos.y);
    WriteOutput[celAddress] += TrailEnergy / pow(AgentCount,0.5);
}

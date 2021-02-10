#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "point.hlsl"

cbuffer Params : register(b0)
{
    float3 Translate;
    float ScatterTranslate;

    float3 Scale;
    float RotateAngle;

    float3 RotateAxis;
    float VolumeType;
    
    float3 VolumePosition;
    float SoftRadius;

    float3 VolumeSize;
    float Bias;
}



StructuredBuffer<Point> SourcePoints : t0;        
RWStructuredBuffer<Point> ResultPoints : u0;   


float sdEllipsoid( float3 p, float3 r )
{
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}


[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;
    SourcePoints.GetDimensions(numStructs, stride);
    if(i.x >= numStructs) {
        ResultPoints[i.x].w = 0 ;
        return;
    }

    Point p = SourcePoints[i.x];

    float3 pToCenter = p.position - VolumePosition;

    float r = length(VolumeSize);
    float d1 = sdEllipsoid(pToCenter, VolumeSize.xyz/2);

    float d = smoothstep( 0.5/r + SoftRadius, 0.5/r, d1*2);
    p.w += d * 1;


    pToCenter = rotate_vector(pToCenter, rotate_angle_axis(RotateAngle * d, normalize(RotateAxis)));

    p.position = lerp(p.position, VolumePosition + pToCenter * Scale,  d) + d * Translate;
    ResultPoints[i.x] = p;
}


#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "point.hlsl"

cbuffer TimeConstants : register(b0)
{
    float GlobalTime;
    float Time;
    float RunTime;
    float BeatTime;
    float LastFrameDuration;
}; 
 

cbuffer Params : register(b1)
{
    float Amount;
    float Frequency;
    float Phase;
    float Variation;
    float3 AmountDistribution;
    float RotationLookupDistance;

}

StructuredBuffer<Point> SourcePoints : t0;        
RWStructuredBuffer<Point> ResultPoints : u0;   

float3 GetNoise(float3 pos, float3 variation) 
{
    float3 noiseLookup = (pos * 0.91 + variation + Phase ) * Frequency;
    return snoiseVec3(noiseLookup) * Amount/100 * AmountDistribution;
}


float4 q_from_matrix (float3x3 m) {
    
	float w = sqrt( 1.0 + m._m00 + m._m11 + m._m22) / 2.0;
	float  w4 = (4.0 * w);
	float x = (m._m21 - m._m12) / w4 ;
	float y = (m._m02 - m._m20) / w4 ;
	float z = (m._m10 - m._m01) / w4 ;
    return float4(x,y,z,w);
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

    float3 variationOffset = hash31((float)(i.x%1234)/0.123 ) * Variation;

    Point p = SourcePoints[i.x];
    float3 pointPos = p.position;
    float3 offsetAtPoint = GetNoise(pointPos, variationOffset);

    float3 xDir = rotate_vector(float3(RotationLookupDistance,0,0), p.rotation);
    float3 offsetAtPosXDir = GetNoise(pointPos + xDir, variationOffset);
    float3 rotatedXDir = (pointPos + xDir + offsetAtPosXDir) - (pointPos + offsetAtPoint);
    //float4 rotationFromXDisplace = from_to_rotation( normalize(xDir), normalize(rotatedXDir));

    float3 yDir = rotate_vector(float3(0, RotationLookupDistance,0), p.rotation);
    float3 offsetAtPosYDir = GetNoise(pointPos + yDir, variationOffset);
    float3 rotatedYDir = (pointPos + yDir + offsetAtPosYDir) - (pointPos + offsetAtPoint);
    //float4 rotationFromYDisplace = from_to_rotation( normalize(yDir), normalize(rotatedYDir));

    float3 rotatedXDirNormalized = normalize(rotatedXDir);
    float3 rotatedYDirNormalized = normalize(rotatedYDir);
    
    float3 crossXY = cross(rotatedXDirNormalized, rotatedYDirNormalized);
    float3x3 orientationDest= float3x3(
        rotatedXDirNormalized, 
        cross(crossXY, rotatedXDirNormalized), 
        crossXY );

    ResultPoints[i.x].rotation = normalize(q_from_matrix(transpose(orientationDest)));

    ResultPoints[i.x].position = p.position + offsetAtPoint ;
    ResultPoints[i.x].w = SourcePoints[i.x].w;
}


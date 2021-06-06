#include "hash-functions.hlsl"
#include "point.hlsl"


cbuffer Params : register(b0)
{
    float3 Center;
    float LengthFactor;

    float3 Direction;
    float Pivot;

    float W;
    float WOffset;
    float OrientationAngle;
    float Twist;
}

RWStructuredBuffer<Point> ResultPoints : u0;    // output

float3 RotatePointAroundAxis(float3 In, float3 Axis, float Rotation)
{
    float s = sin(Rotation);
    float c = cos(Rotation);
    float one_minus_c = 1.0 - c;

    Axis = normalize(Axis);
    float3x3 rot_mat = 
    {   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
        one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
        one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
    };
    return mul(rot_mat,  In);
}

[numthreads(256,4,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint index = i.x; 

    uint pointCount, stride;
    ResultPoints.GetDimensions(pointCount, stride);
    if(index == pointCount -1) {
        ResultPoints[index].w = sqrt(-1);
        return;
    }

    float f = (float)(index)/(pointCount-1) - Pivot;

    ResultPoints[index].position = lerp(Center, Center + Direction * LengthFactor, f);
    ResultPoints[index].w = W + WOffset * f;

    // FIXME: this rotation is hard to control and feels awkward. 
    // I didn't come up with another method, though
    float4 rotate = rotate_angle_axis(3.141578/2, float3(0,0,1));
    float4 rot2 = qmul(q_look_at(Direction, float3(1,1,0)), rotate);

    ResultPoints[index].rotation = rotate;
}


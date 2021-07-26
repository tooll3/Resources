#include "hash-functions.hlsl"
#include "point.hlsl"


cbuffer Params : register(b0)
{
    float Count;
    float Radius;
    float RadiusOffset;
    float __padding1;

    float3 Center;
    float __padding2;

    float3 CenterOffset;
    float __padding3;

    float StartAngle;
    float Cycles;
    float2 __padding4;
    
    float3 Axis;
    float W;

    float WOffset;
    float CloseCircle;    
    float2 __padding5;

    float3 OrientationAxis;
    float1 OrientationAngle;

}


//StructuredBuffer<Point> Points1 : t0;         // input
//StructuredBuffer<Point> Points2 : t1;         // input
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

static float phi = PI *  (3. - sqrt(5.));  // golden angle in radians

[numthreads(256,4,1)]
void main(uint3 dtID : SV_DispatchThreadID)
//void main(uint i : SV_GroupIndex)
{
    uint count, stride;
    ResultPoints.GetDimensions(count, stride);

    float i = dtID.x;

    float t = i / float(count - 1);
    float y = 1 - t * 2;  // y goes from 1 to -1
    float radius = sqrt(1 - y * y);  // radius at y

    float theta = phi * i;  // golden angle increment

    float x = cos(theta) * radius;
    float z = sin(theta) * radius;

    //float points.append((x, y, z))

    ResultPoints[dtID.x].position = float3(x,y,z);
    ResultPoints[dtID.x].w = 1;
 
    //float3 axis = float3(x,0,z);
    //float angle = -atan2( length(float2(x,z)), y) + PI/2;
    float4 rot = rotate_angle_axis( -theta, float3(0,1,0));
    float4 rot2 = rotate_angle_axis( (2-t) * PI, float3(0,0,1));
    
    ResultPoints[dtID.x].rotation = qmul(rot,rot2); // normalize(rotate_angle_axis(lerp(0, PI, t) , axis));
}


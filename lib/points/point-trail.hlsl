#include "point.hlsl"

cbuffer Params : register(b0)
{
    float PointCount;
    float TrailLength;
    float CycleIndex;
}

StructuredBuffer<Point> SourcePoints : t0;         // input
RWStructuredBuffer<Point> TrailPoints : u0;    // output

float4 q_look_at(float3 forward, float3 up)
{
    float3 right = normalize(cross(forward, up));
    up = normalize(cross(forward, right));

    float m00 = right.x;
    float m01 = right.y;
    float m02 = right.z;
    float m10 = up.x;
    float m11 = up.y;
    float m12 = up.z;
    float m20 = forward.x;
    float m21 = forward.y;
    float m22 = forward.z;

    float num8 = (m00 + m11) + m22;
    float4 q = float4(0,0,0,1);
    if (num8 > 0.0)
    {
        float num = sqrt(num8 + 1.0);
        q.w = num * 0.5;
        num = 0.5 / num;
        q.x = (m12 - m21) * num;
        q.y = (m20 - m02) * num;
        q.z = (m01 - m10) * num;
        return q;
    }

    if ((m00 >= m11) && (m00 >= m22))
    {
        float num7 = sqrt(((1.0 + m00) - m11) - m22);
        float num4 = 0.5 / num7;
        q.x = 0.5 * num7;
        q.y = (m01 + m10) * num4;
        q.z = (m02 + m20) * num4;
        q.w = (m12 - m21) * num4;
        return q;
    }

    if (m11 > m22)
    {
        float num6 = sqrt(((1.0 + m11) - m00) - m22);
        float num3 = 0.5 / num6;
        q.x = (m10 + m01) * num3;
        q.y = 0.5 * num6;
        q.z = (m21 + m12) * num3;
        q.w = (m20 - m02) * num3;
        return q;
    }

    float num5 = sqrt(((1.0 + m22) - m00) - m11);
    float num2 = 0.5 / num5;
    q.x = (m20 + m02) * num2;
    q.y = (m21 + m12) * num2;
    q.z = 0.5 * num5;
    q.w = (m01 - m10) * num2;
    return q;
}


[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint pointCount = (uint)(PointCount + 0.5);
    uint sourceIndex = i.x;
    if(i.x >= pointCount)
        return;

    uint trailLength = (uint)(TrailLength + 0.5);
    uint bufferLength = (uint)(PointCount + 0.5) * trailLength;
    uint cycleIndex = (uint)(CycleIndex + 0.5);
    uint targetIndex = (cycleIndex + sourceIndex * trailLength) % bufferLength;

    TrailPoints[targetIndex] = SourcePoints[sourceIndex];
    float3 lastPos = SourcePoints[sourceIndex-1].position;
    TrailPoints[targetIndex].rotation = normalize(q_look_at(SourcePoints[sourceIndex].position, lastPos));

    Point p = SourcePoints[i.x];
    //TrailPoints[targetIndex].w = 0.4;

    // Flag follow position W as NaN line devider
    TrailPoints[(targetIndex + 1) % bufferLength].w = 1./0;
}

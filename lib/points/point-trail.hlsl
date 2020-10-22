cbuffer Params : register(b0)
{
    float PointCount;
    float TrailLength;
    float CycleIndex;
}

struct Point {
    float3 Position;
    float W;
};

StructuredBuffer<Point> SourcePoints : t0;         // input
RWStructuredBuffer<Point> TrailPoints : u0;    // output

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

    Point p = SourcePoints[i.x];
    TrailPoints[targetIndex].W = 0.4;

    // Flag follow position W as NaN line devider
    TrailPoints[(targetIndex + 1) % bufferLength].W = 1./0;
}
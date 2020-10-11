cbuffer Params : register(b0)
{
    float CountA;
    float CountB;
}

struct Point {
    float3 Position;
    float W;
};

StructuredBuffer<Point> Points1 : t0;         // input
StructuredBuffer<Point> Points2 : t1;         // input
RWStructuredBuffer<Point> ResultPoints : u0;    // output

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint sourcePointsBatch = (uint)(CountA + 0.1);  
    uint pointIndex = i.x % sourcePointsBatch;
    
    if(pointIndex == sourcePointsBatch-1) {
        ResultPoints[i.x].Position =  0;
        ResultPoints[i.x].W = 1./0;
    }
    else {
        uint targetIndex = (i.x / sourcePointsBatch )  % (uint)CountB;
        Point A = Points1[pointIndex];
        Point B = Points2[targetIndex];
        ResultPoints[i.x].Position =  A.Position + B.Position;
        ResultPoints[i.x].W = A.W * B.W;
    }

}

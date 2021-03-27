#include "hash-functions.hlsl"
#include "point.hlsl"

StructuredBuffer<Point> PointsB : t0;         // input
RWStructuredBuffer<Point> ResultPoints : u0; 



cbuffer Params : register(b0)
{
    float MixOriginal;
    float Reset;
};


[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    if(Reset > 0.5) {
        ResultPoints[i.x] = PointsB[i.x];
        return;
    }
    ResultPoints[i.x].position = lerp(ResultPoints[i.x].position,  PointsB[i.x].position, MixOriginal);
    float currentW = ResultPoints[i.x].w;
    float orgW = PointsB[i.x].w;

    ResultPoints[i.x].w = (isnan(orgW) || isnan(currentW)) ? orgW
                                          : lerp( currentW, orgW, MixOriginal );
    ResultPoints[i.x].rotation = q_slerp(ResultPoints[i.x].rotation,  PointsB[i.x].rotation, MixOriginal);
}
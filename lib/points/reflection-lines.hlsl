#include "point.hlsl"
#include "pbr.hlsl"

cbuffer Params : register(b0)
{
    float StepCount;
    float DecayW;
    //float CountB;
}

StructuredBuffer<Point> SourcePoints : t0;
StructuredBuffer<PbrVertex> Vertices: t1;
StructuredBuffer<int3> Indices: t2;

RWStructuredBuffer<Point> ResultPoints : u0;


// Casual Moller-Trumbore GPU Ray-Triangle Intersection Routine
float intersect(in float3 orig, in float3 dir, in float3 v0, in float3 v1, in float3 v2, out float2 baryzentricUV) 
{
    float3 e1 = v1 -  v0;
    float3 e2 = v2 -  v0;
    float3 normal = normalize(cross(e1, e2));
    float b = dot(normal, dir);
    float3 w0 = orig -  v0;
    float a = -dot(normal, w0);
    float t = a / b;
    float3 p = orig + t * dir;
    float uu, vv, uv, wu, wv, inverseD;
    baryzentricUV = 0;
    
    uu = dot(e1, e1);
    uv = dot(e1, e2);
    vv = dot(e2, e2);
    float3 w = p -  v0;
    wu = dot(w, e1);
    wv = dot(w, e2);
    inverseD = uv * uv -  uu * vv;
    inverseD = 1.0f / inverseD;
    float u = (uv * wv -  vv * wu) * inverseD;

    if (u < 0.0f || u > 1.0f)    
        return -1.0f;

    float v = (uv * wu -  uu * wv) * inverseD;
    if (v < 0.0f || (u + v) > 1.0f)    
        return -1.0f;

    baryzentricUV = float2(u,v);
        return t;
}




void findClosestPointAndDistance(
    in uint faceCount, 
    in float3 orig, 
    in float3 dir,
    out uint closestFaceIndex, 
    out float3 closestSurfacePoint,
    out float2 closestBaryzentricUV) 
{
    closestFaceIndex = -1; 
    float closestDistance = 99999;

    for(uint faceIndex = 0; faceIndex < faceCount; faceIndex++) 
    {
        int3 f = Indices[faceIndex];
        float2 baryzentricUV;
        float t = intersect(
            orig,
            dir,
            Vertices[f[0]].Position,
            Vertices[f[1]].Position,
            Vertices[f[2]].Position,
            baryzentricUV
        );
        if(t < 0.5) {
            //closestSurfacePoint = float3(0,0.4,0);
            //closestFaceIndex = 0;
            continue;
        }

        //float distance2 = length(pointOnFace - pos);
        if( t < closestDistance) {
            closestDistance = t;
            closestFaceIndex = faceIndex;
            closestSurfacePoint = orig + dir * t;
            closestBaryzentricUV = baryzentricUV;
        }
    }
}

static const float NaN = sqrt(-1);

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint sourcePointCount, stride;
    SourcePoints.GetDimensions(sourcePointCount, stride);

    if(sourcePointCount == 0) {

    }
    else if(i.x >= sourcePointCount) {
        return;
    }

    uint vertexCount; 
    Vertices.GetDimensions(vertexCount, stride);

    uint faceCount; 
    Indices.GetDimensions(faceCount, stride);

    uint stepCount = (uint)StepCount; // including separator
    
    uint rayGroupStartIndex= i.x * stepCount;

    Point p = SourcePoints[i.x];

    ResultPoints[rayGroupStartIndex + 0] = p;
    ResultPoints[rayGroupStartIndex + stepCount -1].w = NaN;

    float3 orig = p.position;
    float3 dir =  rotate_vector( float3(0,0,1), p.rotation);
    //float3 dir = 0;

    int closestFaceIndex;
    float3 closestSurfacePoint;
    float2 closestBaryzentricUV;
    float w = p.w;

    for(uint stepIndex=1; stepIndex < (stepCount - 1); stepIndex++ ) 
    {
        w *= DecayW;

        findClosestPointAndDistance(faceCount, orig, dir, closestFaceIndex, closestSurfacePoint, closestBaryzentricUV);

        ResultPoints[rayGroupStartIndex + stepIndex] = p;
        if(closestFaceIndex < 0) 
        {
            orig += dir * 0.2;
            ResultPoints[rayGroupStartIndex + stepIndex].position = orig;
            ResultPoints[rayGroupStartIndex + stepIndex].w = w;
            continue;
        }
    
        orig= closestSurfacePoint;
        
        ResultPoints[rayGroupStartIndex + stepIndex].position = orig;
        ResultPoints[rayGroupStartIndex + stepIndex].w = w;

        int v0Index = Indices[closestFaceIndex][0];
        float3 n0 = Vertices[Indices[closestFaceIndex][0]].Normal;
        float3 n1 = Vertices[Indices[closestFaceIndex][1]].Normal;
        float3 n2 = Vertices[Indices[closestFaceIndex][2]].Normal;
        float u = closestBaryzentricUV.y;
        float v = closestBaryzentricUV.x;
        float3 n = normalize(u*n0 + v*n1 + (1 - u - v)*n2);

        dir= reflect( dir, n);
    }    
}

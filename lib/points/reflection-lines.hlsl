#include "point.hlsl"
#include "pbr.hlsl"

cbuffer Params : register(b0)
{
    float StepCount;
    float DecayW;
    float Extend;
}

StructuredBuffer<Point> SourcePoints : t0;
StructuredBuffer<PbrVertex> Vertices: t1;
StructuredBuffer<int3> Indices: t2;

RWStructuredBuffer<Point> ResultPoints : u0;


// Casual Moller-Trumbore GPU Ray-Triangle Intersection Routine
// Casual Moller-Trumbore GPU Ray-Triangle Intersection Routine
// float intersect(in float3 orig, in float3 dir, in float3 v0, in float3 v1, in float3 v2, out float2 baryzentricUV)
// {
//     float3 e1 = v1 -  v0;
//     float3 e2 = v2 -  v0;
//     float3 normal = normalize(cross(e1, e2));
//     float b = dot(normal, dir);
//     float3 w0 = orig -  v0;
//     float a = -dot(normal, w0);
//     float t = a / b;
//     float3 p = orig + t * dir;
//     float uu, vv, uv, wu, wv, inverseD;
//     baryzentricUV = 0;

//     uu = dot(e1, e1);
//     uv = dot(e1, e2);
//     vv = dot(e2, e2);
//     float3 w = p -  v0;
//     wu = dot(w, e1);
//     wv = dot(w, e2);
//     inverseD = uv * uv -  uu * vv;
//     inverseD = 1.0f / inverseD;
//     float u = (uv * wv -  vv * wu) * inverseD;

//     if (u < 0.0f || u > 1.0f)
//         return -1.0f;

//     float v = (uv * wu -  uu * wv) * inverseD;
//     if (v < 0.0f || (u + v) > 1.0f)
//         return -1.0f;

//     baryzentricUV = float2(u,v);
//         return t;
// }

static const float kEpsilon = 0.0001;

// from https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-rendering-a-triangle/barycentric-coordinates
// float intersect(
//     float3 orig, float3 dir,
//     float3 v0, float3 v1, float3 v2,
//     out float2 bary)
// {
//     float u,v;
//     //dir= normalize(dir);

//     // compute plane's normal
//     float3 v0v1 = v1 - v0;
//     float3 v0v2 = v2 - v0;
//     // no need to normalize
//     float3 N = normalize(cross(v0v1, v0v2)); // N
//     float denom = dot(N,N);

//     // Step 1: finding P

//     // check if ray and plane are parallel ?
//     float NdotRayDirection = dot(N, dir);
//     if (abs(NdotRayDirection) < kEpsilon) // almost 0
//         return -1; // they are parallel so they don't intersect !

//     // compute d parameter using equation 2
//     float d = dot(N, v0);

//     // compute t (equation 3)
//     float t = (dot(N,orig) + d) / NdotRayDirection;
//     // check if the triangle is in behind the ray
//     if (t < 0) return -1; // the triangle is behind

//     // compute the intersection point using equation 1
//     float3 P = orig + t * dir;

//     // Step 2: inside-outside test
//     float3 C; // vector perpendicular to triangle's plane

//     // edge 0
//     float3 edge0 = v1 - v0;
//     float3 vp0 = P - v0;
//     C = cross(edge0, vp0);
//     if (dot(N, C) < 0) return -1; // P is on the right side

//     // edge 1
//     float3 edge1 = v2 - v1;
//     float3 vp1 = P - v1;
//     C = cross(edge1, vp1);
//     if ((u = dot(N, C)) < 0)  return -1; // P is on the right side

//     // edge 2
//     float3 edge2 = v0 - v2;
//     float3 vp2 = P - v2;
//     C = cross(edge2, vp2);
//     if ((v = dot(N, C)) < 0) return -1; // P is on the right side;

//     u /= denom;
//     v /= denom;
//     bary = float2(u,v);

//     return t; // this ray hits the triangle
// }

// From https://graphicscodex.courses.nvidia.com/app.html?page=_rn_rayCst#section4.2
bool intersect(
    float3 orig, float3 dir,
    float3 v0, float3 v1, float3 v2,
    out float3 b,
    out float t)
{
    // Edge vectors
        float3 e_1 = v1 - v0;
        float3 e_2 = v2 - v0;

        // Face normal
        float3 n = normalize(cross(e_1, e_2));

        float3 q = cross(dir, e_2);
        float a = dot(e_1, q);

        // Backfacing / nearly parallel, or close to the limit of precision?
        if ((dot(n, dir) >= 0) || (abs(a) <= kEpsilon)) return false;

        float3 s = (orig - v0) / a;
        float3 r = cross(s, e_1);

        b[0] = dot(s, q);
        b[1] = dot(r, dir);
        b[2] = 1.0f - b[0] - b[1];

        t = dot(e_2,r);

        // Intersected inside triangle?
        return ((b[0] >= 0) && (b[1] >= 0) && (b[2] >= 0) && (t >= 0));
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
        float3 bary;
        float t;

        if(!intersect(
            orig,
            dir,
            Vertices[f[0]].Position,
            Vertices[f[1]].Position,
            Vertices[f[2]].Position,
            bary,
            t
        )) {
            continue;
        }

        if( t < closestDistance)
        {
            closestDistance = t;
            closestFaceIndex = faceIndex;
            closestSurfacePoint = orig + dir * t;
            closestBaryzentricUV = bary.zx;
        }

        //float distance2 = length(pointOnFace - pos);
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
            orig += dir * Extend;
            ResultPoints[rayGroupStartIndex + stepIndex].position = orig;
            ResultPoints[rayGroupStartIndex + stepIndex].w = w;
            return;
            //continue;
        }

        orig= closestSurfacePoint;

        ResultPoints[rayGroupStartIndex + stepIndex].position = orig;
        ResultPoints[rayGroupStartIndex + stepIndex].w = w;

        int v0Index = Indices[closestFaceIndex][0];
        float3 n0 = normalize(Vertices[Indices[closestFaceIndex][0]].Normal);
        float3 n1 = normalize(Vertices[Indices[closestFaceIndex][1]].Normal);
        float3 n2 = normalize(Vertices[Indices[closestFaceIndex][2]].Normal);
        float u = closestBaryzentricUV.x;
        float v = closestBaryzentricUV.y;

        float3 n = normalize(u*n0 + v*n1 + (1 - u - v)*n2);

        dir= reflect( dir, n * 1);
    }
}

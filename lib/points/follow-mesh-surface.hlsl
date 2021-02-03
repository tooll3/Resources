#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "point.hlsl"
#include "pbr.hlsl"

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
    float RestorePosition;
    float Speed;
    float SurfaceDistance;
    float Spin;
    //float Acceleration;

    // float Amount;
    // float Frequency;
    // float Phase;
    // float Variation;
    // float3 AmountDistribution;
    // float RotationLookupDistance;

}

// struct Point {
//     float3 Position;
//     float W;
// };

StructuredBuffer<Point> Points : t0;         // input
StructuredBuffer<PbrVertex> Vertices: t1;
StructuredBuffer<int3> Indices: t2;

RWStructuredBuffer<Point> ResultPoints : u0;    // output






//--------------------------------------------


float3 closesPointOnTriangle( in float3 p0, in float3 p1, in float3 p2, in float3 sourcePosition )
{
    float3 edge0 = p1 - p0;
    float3 edge1 = p2 - p0;
    float3 v0 = p0 - sourcePosition;

    float a = dot(edge0, edge0 );
    float b = dot(edge0, edge1 );
    float c = dot(edge1, edge1 );
    float d = dot(edge0, v0 );
    float e = dot(edge1, v0 );

    float det = a*c - b*b;
    float s = b*e - c*d;
    float t = b*d - a*e;

    if ( s + t < det )
    {
        if ( s < 0.f )
        {
            if ( t < 0.f )
            {
                if ( d < 0.f )
                {
                    s = clamp( -d/a, 0.f, 1.f );
                    t = 0.f;
                }
                else
                {
                    s = 0.f;
                    t = clamp( -e/c, 0.f, 1.f );
                }
            }
            else
            {
                s = 0.f;
                t = clamp( -e/c, 0.f, 1.f );
            }
        }
        else if ( t < 0.f )
        {
            s = clamp( -d/a, 0.f, 1.f );
            t = 0.f;
        }
        else
        {
            float invDet = 1.f / det;
            s *= invDet;
            t *= invDet;
        }
    }
    else
    {
        if ( s < 0.f )
        {
            float tmp0 = b+d;
            float tmp1 = c+e;
            if ( tmp1 > tmp0 )
            {
                float numer = tmp1 - tmp0;
                float denom = a-2*b+c;
                s = clamp( numer/denom, 0.f, 1.f );
                t = 1-s;
            }
            else
            {
                t = clamp( -e/c, 0.f, 1.f );
                s = 0.f;
            }
        }
        else if ( t < 0.f )
        {
            if ( a+d > b+e )
            {
                float numer = c+e-b-d;
                float denom = a-2*b+c;
                s = clamp( numer/denom, 0.f, 1.f );
                t = 1-s;
            }
            else
            {
                s = clamp( -e/c, 0.f, 1.f );
                t = 0.f;
            }
        }
        else
        {
            float numer = c+e-b-d;
            float denom = a-2*b+c;
            s = clamp( numer/denom, 0.f, 1.f );
            t = 1.f - s;
        }
    }

    return p0 + s * edge0 + t * edge1;
}


void findClosestPointAndDistance(
    in uint faceCount, 
    in float3 pos, 
    out uint closestFaceIndex, 
    out float3 closestSurfacePoint) 
{
    closestFaceIndex = -1; 
    float closestDistance = 99999;
    //closestPoint = 0;


    for(uint faceIndex = 0; faceIndex < faceCount; faceIndex++) 
    {
        int3 f = Indices[faceIndex];
        float3 pointOnFace = closesPointOnTriangle(
            Vertices[f[0]].Position,
            Vertices[f[1]].Position,
            Vertices[f[2]].Position,
            pos
        );
        
        float distance2 = length(pointOnFace - pos);
        if(distance2 < closestDistance) {
            closestDistance = distance2;
            closestFaceIndex = faceIndex;
            closestSurfacePoint = pointOnFace;
        }
    }
}


[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint pointCount, pointStride;
    Points.GetDimensions(pointCount, pointStride);
    if(i.x >= pointCount) {
        ResultPoints[i.x].w = 0 ;
        return;
    }


    uint vertexCount, vertexStride; 
    Vertices.GetDimensions(vertexCount, vertexStride);

    uint faceCount, faceStride; 
    Indices.GetDimensions(faceCount, faceStride);

    
    Point p = ResultPoints[i.x];
    p.w = 1;
    //p.rotation = float4(0,0,0,1);


    float3 pos = RestorePosition > 1
                 ? Points[i.x].position
                 : lerp( p.position, Points[i.x].position, RestorePosition) ;

    //p.rotation = float4(0,0,0,1);
    float3 forward =  rotate_vector( float3(0,0,1), p.rotation);
    float3 pos2 = pos + forward * Speed;

    int closestFaceIndex;
    float3 closestSurfacePoint;
    findClosestPointAndDistance(faceCount, pos2,  closestFaceIndex, closestSurfacePoint);

    float3 targetPosWithDistance = closestSurfacePoint + normalize(pos2 - closestSurfacePoint) * SurfaceDistance;



    //float3 pos = p.position;

    // for(uint vertexIndex = 0; vertexIndex < vertexCount; vertexIndex++) 
    // {
    //     closesPointOnTriangle();
        
    //     float distance2 = length(Vertices[vertexIndex].Position - pos);
    //     if(distance2 < closestDistance) {
    //         closestDistance = distance2;
    //         closestIndex = vertexIndex;
    //     }
    // }

    if(closestFaceIndex >= 0) 
    {
        p.position = targetPosWithDistance;
    }


    float randomRot = (hash11(i.x) - 0.5) * Spin;
    p.rotation = normalize(qmul(p.rotation, normalize(float4(randomRot, 0.005, 0, 1))));

    ResultPoints[i.x] = p;
}


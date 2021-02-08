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
    float ScatterSurfaceDistance;
    float Freeze;
}

StructuredBuffer<Point> Points : t0;         // input
StructuredBuffer<PbrVertex> Vertices: t1;
StructuredBuffer<int3> Indices: t2;

RWStructuredBuffer<Point> ResultPoints : u0;    // output
RWStructuredBuffer<Point> DebugPoints : u1;    // output
RWStructuredBuffer<Point> DebugPoints2 : u1;    // output


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


float4 q_from_matrix (float3x3 m) 
{   
    float w = sqrt( 1.0 + m._m00 + m._m11 + m._m22) / 2.0;
    float  w4 = (4.0 * w);
    float x = (m._m21 - m._m12) / w4 ;
    float y = (m._m02 - m._m20) / w4 ;
    float z = (m._m10 - m._m01) / w4 ;
    return float4(x,y,z,w);
}

float4 q_from_matrix2 (float3x3 m) 
{   
    float tr = m._m00 + m._m11 + m._m22;

    if (tr > 0) { 
        float S = sqrt(tr+1.0) * 2; // S=4*qw 
        return float4(
            (m._m21 - m._m12) / S,
            (m._m02 - m._m20) / S,
            (m._m10 - m._m01) / S, 
            0.25 * S
        );
    } else if ((m._m00 > m._m11)&(m._m00 > m._m22)) { 
        float S = sqrt(1.0 + m._m00 - m._m11 - m._m22) * 2; // S=4*qx 
        return float4(
            0.25 * S,
            (m._m01 + m._m10) / S ,
            (m._m02 + m._m20) / S ,
            (m._m21 - m._m12) / S
        );
    } else if (m._m11 > m._m22) { 
        float S = sqrt(1.0 + m._m11 - m._m00 - m._m22) * 2; // S=4*qy
        return float4(
            (m._m01 + m._m10) / S,
            0.25 * S,
            (m._m12 + m._m21) / S,
            (m._m02 - m._m20) / S
        );
    } else { 
        float S = sqrt(1.0 + m._m22 - m._m00 - m._m11) * 2; // S=4*qz
        return float4(
            (m._m02 + m._m20) / S,
            (m._m12 + m._m21) / S,
            0.25 * S,
            (m._m10 - m._m01) / S
        );
    }
}

float4 q_from_tangentAndNormal(float3 dx, float3 dz)
{
    // float a = -acos(dot( dx, dz));
    // float4 r = rotate_angle_axis(a, dz);

    // float4 rx = rotate_angle_axis(PI/2, dx) ;
    // rx = float4(0,0,0,1);
    // return qmul(rx,r);

    dx = normalize(dx);
    dz = normalize(dz);
    float3 dy = -cross(dx, dz);
    
    float3x3 orientationDest= float3x3(
        dx, 
        dy,
        dz
        );
    
    return normalize( q_from_matrix2( transpose( orientationDest)));
}


[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    if(Freeze > 0.5)
        return;

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

    
    float pointHash = hash11(i.x);
    float signedPointHash = hash11(i.x);
    Point p = ResultPoints[i.x];

    if(RestorePosition > 1) {
        p = Points[i.x];
    }

    float3 pos = RestorePosition > 1
                 ? Points[i.x].position
                 : lerp( p.position, Points[i.x].position, RestorePosition) ;

    float3 forward =  rotate_vector( float3(1,0,0), p.rotation);
    float3 pos2 = pos + forward * Speed;

    int closestFaceIndex;
    float3 closestSurfacePoint;
    findClosestPointAndDistance(faceCount, pos2,  closestFaceIndex, closestSurfacePoint);

    // Keep outside
    float3 distanceFromSurface= normalize(pos2 - closestSurfacePoint) * (SurfaceDistance + signedPointHash * ScatterSurfaceDistance);
    distanceFromSurface *= dot(distanceFromSurface, Vertices[Indices[closestFaceIndex].x].Normal) > 0 
        ? 1 : -1;

    float3 targetPosWithDistance = closestSurfacePoint + distanceFromSurface;

    
    if(closestFaceIndex < 0) {
        return;
    }

    float3 movement = targetPosWithDistance - p.position;
    p.position = targetPosWithDistance;
    float4 orientation = q_from_tangentAndNormal(movement, distanceFromSurface);
    float4 mixedOrientation = q_slerp(orientation, p.rotation, 0.96);

    if(abs(Spin) > 0.001) 
    {
        float randomAngle = signedPointHash  * Spin;
        mixedOrientation = qmul( mixedOrientation, rotate_angle_axis(randomAngle, distanceFromSurface ));
    }
        
    p.rotation = mixedOrientation;
    ResultPoints[i.x] = p;
}


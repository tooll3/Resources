#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "point.hlsl"
#include "pbr.hlsl"

cbuffer Params : register(b0)
{
    // float SmoothDistance;
    // float SampleMode;
    // float2 SampleRange;
}

StructuredBuffer<Point> RailPoints : t0;
StructuredBuffer<Point> ShapePoints : t1;

RWStructuredBuffer<PbrVertex> Vertices : u0;
RWStructuredBuffer<int3> TriangleIndices : u1;



[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{

    uint triangleCount, stride;
    TriangleIndices.GetDimensions(triangleCount, stride);

    uint vertexCount;
    Vertices.GetDimensions(vertexCount, stride);

    if(i.x >= vertexCount) {
        return;
    }

    

    uint rows;
    ShapePoints.GetDimensions(rows, stride);

    uint columns;
    RailPoints.GetDimensions(columns, stride);

    uint vertexIndex = i.x;
    uint rowIndex = vertexIndex % rows;
    uint columnIndex = vertexIndex / rows;

    PbrVertex v;
    Point railPoint = RailPoints[columnIndex];
    Point shapePoint = ShapePoints[rowIndex];

    float4 rotation = normalize(qmul(railPoint.rotation, shapePoint.rotation ));
    float3 position = rotate_vector(shapePoint.position, railPoint.rotation) + railPoint.position;

    v.Position =  position;
    v.Normal = rotate_vector(float3(1,0,0), rotation);
    v.Tangent = rotate_vector(float3(0,0,-1), rotation);
    v.Bitangent = rotate_vector(float3(0,1,0), rotation);
    v.TexCoord = float2((float)columnIndex/(columns-1),(float)rowIndex/(rows-1));
    v.Selected = 1;
    v.__padding =0;

    Vertices[vertexIndex] = v;

    if( isnan(RailPoints[vertexIndex].w) 
     || isnan(RailPoints[vertexIndex+1].w)
     || isnan(RailPoints[vertexIndex+rows].w)
     || isnan(RailPoints[vertexIndex+rows+1].w)) 
    {
        int faceIndex =  2 * (rowIndex + columnIndex * (rows-1));
        if (columnIndex < columns - 1 && rowIndex < rows - 1) 
        {
            TriangleIndices[faceIndex + 0] = int3(0, 0, 0);
            TriangleIndices[faceIndex + 1] = int3(0, 0, 0);
            //TriangleIndices[faceIndex - 1] = int3(0, 0, 0);
        }
        return;
    }


    // Write face indices
    if (columnIndex < columns - 1 && rowIndex < rows - 1) 
    {
        int faceIndex =  2 * (rowIndex + columnIndex * (rows-1));
        TriangleIndices[faceIndex + 0] = int3(vertexIndex, vertexIndex + rows, vertexIndex + 1);
        TriangleIndices[faceIndex + 1] = int3(vertexIndex + rows, vertexIndex + rows+1, vertexIndex + 1);
    }
}


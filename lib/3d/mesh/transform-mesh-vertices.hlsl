#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "pbr.hlsl"

cbuffer Params : register(b0)
{
    float4x4 TransformMatrix;
}

StructuredBuffer<PbrVertex> SourceVerts : t0;        
RWStructuredBuffer<PbrVertex> ResultVerts : u0;   


[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;
    SourceVerts.GetDimensions(numStructs, stride);
    if(i.x >= numStructs) {
        return;
    }
    
    ResultVerts[i.x].Position = mul(float4(SourceVerts[i.x].Position,1), TransformMatrix).xyz;
    ResultVerts[i.x].Normal = normalize(mul(float4(SourceVerts[i.x].Normal,0), TransformMatrix).xyz);
    ResultVerts[i.x].Tangent = normalize(mul(float4(SourceVerts[i.x].Tangent,0), TransformMatrix).xyz);
    ResultVerts[i.x].Bitangent = normalize(mul(float4(SourceVerts[i.x].Bitangent,0), TransformMatrix).xyz);
    ResultVerts[i.x].TexCoord = SourceVerts[i.x].TexCoord;
}


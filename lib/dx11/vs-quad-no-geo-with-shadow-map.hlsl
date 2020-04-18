
static const float3 Quad[] = 
{
  float3(-1, -1, 0),
  float3( 1, -1, 0), 
  float3( 1,  1, 0), 
  float3( 1,  1, 0), 
  float3(-1,  1, 0), 
  float3(-1, -1, 0), 
};


cbuffer Transforms : register(b0)
{
    float4x4 clipSpaceTcamera;
    float4x4 cameraTclipSpace;
    float4x4 cameraTworld;
    float4x4 worldTcamera;
    float4x4 clipSpaceTworld;
    float4x4 worldTclipSpace;
    float4x4 worldTobject;
    float4x4 objectTworld;
    float4x4 cameraTobject;
    float4x4 clipSpaceTobject;
};

cbuffer Params : register(b1)
{
    float4 Color;
    float Width;
    float Height;
};

struct vsOutput
{
    float4 position : SV_POSITION;
    float4 world_P : POSITION;
    float2 texCoord : TEXCOORD;
};

vsOutput vsMain(uint vertexId: SV_VertexID)
{
    vsOutput output;
    float2 quadVertex = Quad[vertexId].xy;
    float2 object_P_quadVertex = quadVertex * float2(Width, Height);
    output.world_P = mul(worldTobject, float4(object_P_quadVertex, 0, 1));
    output.position = mul(clipSpaceTworld, output.world_P);
    output.texCoord = quadVertex*float2(0.5, -0.5) + 0.5;

    return output;
}

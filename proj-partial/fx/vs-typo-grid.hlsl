
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

struct GridEntry
{
    float3 position;
    float dummy;
    float2 uv;
    float2 size;
};

struct Output
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
    float4 color : COLOR;
};

StructuredBuffer<GridEntry> GridEntries : t0;

Output vsMain(uint id: SV_VertexID)
{
    Output output;

    int quadIndex = id % 6;
    int entryIndex = id / 6;
    float3 quadPos = Quad[quadIndex];
    GridEntry entry = GridEntries[entryIndex];
    float4 worldPquadPos = mul(worldTobject, float4(entry.position,1));
    worldPquadPos.xy += quadPos.xy*6.0 * entry.size;
    float4 cameraPquadPos = mul(cameraTworld, worldPquadPos);
    output.position = mul(clipSpaceTcamera, cameraPquadPos);
    output.position.z = 0;
    output.color = float4(0,1,1,1);
    output.texCoord = entry.uv;

    return output;
}


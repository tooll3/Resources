
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
    float1 Size;
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
Texture2D<float4> displaceTexture : register(t1);
sampler texSampler : register(s0);


Output vsMain(uint id: SV_VertexID)
{
    Output output;

    int vertexIndex = id % 6;
    int entryIndex = id / 6;
    float3 quadPos = Quad[vertexIndex];


    GridEntry entry = GridEntries[entryIndex];

    float4 texColor = displaceTexture.SampleLevel(texSampler, entry.position.xy * 0.1, 0);
    //float4 texColor = displaceTexture.SampleLevel(texSampler, float2(0,0) ,0 );
    //texColor = float4(0.5,1,1,1);


    float4 worldPquadPos = mul(worldTobject, float4(entry.position,1) + float4( texColor.b * -3, 0,0,0));
    worldPquadPos.xy += quadPos.xy * entry.size * Size * texColor.g*4;
    float4 cameraPquadPos = mul(cameraTworld, worldPquadPos);
    output.position = mul(clipSpaceTcamera, cameraPquadPos);
    output.position.z = 0;
    output.color = Color * texColor;
    output.texCoord = (entry.uv + quadPos * float2(0.5, -0.5) + 0.5)/16;

    return output;
}
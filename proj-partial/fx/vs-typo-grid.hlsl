
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
    float2 GridSize;
    float2 CellSize;
    float2 CellPadding;
    float2 TextOffset;
    float4 Color;
    float3 OverridePosition;
    float OverrideScale;
};

struct GridEntry
{
    float2 gridPos;
    float2 charUv;
    //float2 size;
    //float2 __filldummy;
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

    float4 texColor = displaceTexture.SampleLevel(texSampler, entry.gridPos - (TextOffset.xy * float2(1,-1) % 1) / GridSize, 0);
    //float4 texColor = displaceTexture.SampleLevel(texSampler, float2(0,0) ,0 );
    //texColor = float4(0.5,1,1,1);

    float2 centeredGridPos = float2( (entry.gridPos.x - 0.5) * GridSize.x, 
                                    (-0.5 + entry.gridPos.y ) * GridSize.y
                                );
    centeredGridPos.xy +=  TextOffset.xy * float2(-1,1) % 1;

    float3 objectPos =  float3( centeredGridPos * CellSize,0 );

    //objectPos += float3(GridSize.x *-0.5, +GridSize.y * 0.5 ,0);
    objectPos+= float3( texColor.b * OverridePosition);

    float4 worldPquadPos = mul(worldTobject, float4(objectPos.xyz,1));
    
    worldPquadPos.xy += quadPos.xy * CellSize * (1+texColor.g* OverrideScale) /2;
    
    float4 cameraPquadPos = mul(cameraTworld, worldPquadPos);
    output.position = mul(clipSpaceTcamera, cameraPquadPos);
    //output.position.z = 0;
    output.color = Color * texColor.rrra;
    output.texCoord = (entry.charUv + quadPos * float2(0.5, -0.5) + 0.5)/16;
    return output;
}
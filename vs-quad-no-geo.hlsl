
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
};


struct Output
{
    float4 position : SV_POSITION;
};

Output vsMain(uint id: SV_VertexID)
{
    Output output;

    float4 worldPquad = mul(worldTobject, float4(Quad[id]*120.0, 1));
    float4 camPquad = mul(cameraTworld, worldPquad);
    output.position = mul(clipSpaceTcamera, camPquad); //todo: check why using clipSpaceTobject directly doesn't work

    return output;
}


float4 psMain(Output input) : SV_TARGET
{
    return float4(1,1,1,1) * Color;
}


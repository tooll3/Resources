cbuffer ParamConstants : register(b1)
{
    float4 Color;
}

struct Output
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
    float4 color : COLOR;
};

Texture2D<float4> inputTexture : register(t0);
sampler texSampler : register(s0);

float4 psMain(Output input) : SV_TARGET
{
    float f = inputTexture.Sample(texSampler, input.texCoord).r;
    float c2= float4(1,1,1,1);
    return input.color * f * Color * c2;
    //return float4(1,1,1,1) * Color;
}
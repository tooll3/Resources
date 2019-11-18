
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
    return input.color * float4(f,f,f,18.0*f);
}

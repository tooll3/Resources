Texture2D<float> color : register(t0);
Texture2D<float> coc : register(t1);

RWTexture2D<float4> color4 : register(u0);
RWTexture2D<float4> colorCoCFar4 : register(u1);
RWTexture2D<float2> coc4 : register(u2);

sampler texSampler : register(s0);

cbuffer ParamConstants : register(b0)
{
    float4 a;
}

[numthreads(16,16,1)]
void main(uint3 i : SV_DispatchThreadID)
{
//    float4 om = shadowMap.SampleLevel(texSampler, uv, 0);
//    coc4[i.xy] = float2(nearCoC, farCoC);
}

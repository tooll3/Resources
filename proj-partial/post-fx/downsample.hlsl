Texture2D<float4> color : register(t0);
Texture2D<float2> coc : register(t1);

// RWTexture2D<float4> color4 : register(u0);
// RWTexture2D<float4> colorCoCFar4 : register(u1);
// RWTexture2D<float2> coc4 : register(u2);
RWTexture2D<float4> output : register(u0);

sampler texSampler : register(s0);

cbuffer ParamConstants : register(b0)
{
    float4 a;
}

[numthreads(16,16,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    float4 f;
    float n = 0;
    const int SIZE = 25;
    for (int j = -SIZE; j < SIZE; j++)
    for (int k = -SIZE; k < SIZE; k++)
    {
        uint2 index = uint2(i.x + j, i.y + k);
        float s = coc[index].r;
        n += s;
        f += color[index].xyzw * s;
    }
    f /= n;
    f = f;// * coc[i.xy].r;// + color[i.xy] * (1.0 - coc[i.xy].r) ;
    // f.a = 1;
    output[i.xy] = f;
    // output[i.xy] = lerp(f, color[i.xy], 1);//coc[i.xy].r);
}

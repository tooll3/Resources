#include "noise-functions.hlsl"

RWTexture3D<float4> outputTexture : register(u0);

[numthreads(8,8,8)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint width, height, depth;
    outputTexture.GetDimensions(width, height, depth);

    /*float2 uv = (float2)i.xy / float2(width - 1, height - 1);*/
    /*uv = uv*2.0 - 1.0;*/
    /*float l = length(uv);*/
    /*uv *= strength * sin(l*time*speed);*/
    /*uv = uv*0.5 + 0.5;*/

    float3 s = 1.0 / 8.0;
    float3 c = cnoise((float3)i.xyz * s);
    outputTexture[i.xyz] = float4(c.xxx, 0.7);
}


cbuffer Transforms : register(b0)
{
    float4x4 CameraToClipSpace;
    float4x4 ClipSpaceToCamera;
    float4x4 WorldToCamera;
    float4x4 CameraToWorld;
    float4x4 WorldToClipSpace;
    float4x4 ClipSpaceToWorld;
    float4x4 ObjectToWorld;
    float4x4 WorldToObject;
    float4x4 ObjectToCamera;
    float4x4 ObjectToClipSpace;
};

cbuffer Params : register(b1)
{
    float4 Color;
    float Width;
    float Height;
};

Texture2D<float4> InputTexture : register(t0);
Texture2D<float4> RefTexture : register(t1);
sampler texSampler : register(s0);
sampler pointSampler : register(s1);


struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

float4 psMain(vsOutput input) : SV_TARGET
{
    float2 texCoord = input.texCoord;
    texCoord = float2(0.25,-0.35) + texCoord*0.15;
    // return RefTexture.Sample(texSampler, texCoord);
    float dist = InputTexture.Sample(texSampler, texCoord).r;
    float t = 0.5;
    float aastep;
    float p;
    // aastep = 0.7 * length(float2(ddx(dist), ddy(dist)));
    aastep = 0.5*fwidth(dist);
    p = smoothstep(t - aastep, t + aastep, dist);
    // aastep = fwidth(dist);
    // p = smoothstep(t, t + aastep, dist);
    float alpha = InputTexture.Sample(pointSampler, texCoord).a;
    alpha = dist > t - aastep ? alpha : 0;
    // p = alpha;
    // p = InputTexture.Sample(pointSampler, texCoord).r;
    // alpha = 1;
    float3 color = float3(1,1,1);
    return float4(color*p,alpha);
}

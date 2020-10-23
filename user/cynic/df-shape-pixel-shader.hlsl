
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
sampler texSampler : register(s0);


struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

float4 psMain(vsOutput input) : SV_TARGET
{
    float2 texCoord = input.texCoord;
    texCoord = float2(0.25,-0.35) + texCoord*0.15;
    float dist = InputTexture.Sample(texSampler, texCoord).r;
    float t = 0.5;
    float aastep = 0.5 * fwidth(dist);
    float p = smoothstep(t - aastep, t + aastep, dist);
    return float4(p,p,p,1);
}

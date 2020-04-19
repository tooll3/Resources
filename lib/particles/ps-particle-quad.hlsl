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

cbuffer ShadowTransforms : register(b1)
{
    float4x4 shadow_clipSpaceTcamera;
    float4x4 shadow_cameraTclipSpace;
    float4x4 shadow_cameraTworld;
    float4x4 shadow_worldTcamera;
    float4x4 shadow_clipSpaceTworld;
    float4x4 shadow_worldTclipSpace;
    float4x4 shadow_worldTobject;
    float4x4 shadow_objectTworld;
    float4x4 shadow_ameraTobject;
    float4x4 shadow_clipSpaceTobject;
};


Texture2D<float4> ShadowMap : register(t0); // opacity shadow map
Texture2D<float4> inputTexture : register(t1);
sampler texSampler : register(s0);

struct Input
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
    float4 color : COLOR;
    float4 world_P : POSITION;
};

float4 psMain(Input input) : SV_TARGET
{
    // float4 color = input.color;

    float4 scsPparticlePos = mul(shadow_clipSpaceTworld, input.world_P);
    scsPparticlePos.xyz /= scsPparticlePos.w;
    scsPparticlePos.xy = scsPparticlePos.xy*0.5 + 0.5;
    scsPparticlePos.y = 1.0-scsPparticlePos.y;
    float sz = scsPparticlePos.z - 0.25;
    float4 color = float4(1,1,1,1);
    // color = inputTexture.Sample(texSampler, input.texCoord);
    float4 om = ShadowMap.SampleLevel(texSampler, scsPparticlePos.xy, 0);
    float4 mask0 = saturate((float4(sz,sz,sz,sz) - float4(0.00, 0.25, 0.50, 0.75)) * 4.0);
    om *= mask0;
    // om *= 0.25;
    float occlusion = saturate((om.x + om.y + om.z + om.w)/1.0);
    // color.rgba = lerp(float4(0.8,0,0.8,1), float4(0.1,0.1,0.1,1), occlusion);
    occlusion = 1.0 - occlusion;
    color.rgb *= occlusion;
    // color.a = 0.5;
    // color.rgb = om;
    float2 xy = 2.0 * input.texCoord - float2(1,1);
    float r2 = dot(xy, xy);
    float opacity = exp2(-r2 * 5.0)*5;
    color.a = opacity;
    // color.a = 0.5;

    return color;
}


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
sampler texSampler : register(s0);

struct Input
{
    float4 position : SV_POSITION;
    float4 world_P : POSITION;
    float2 texCoord : TEXCOORD;
};


float4 psMain(Input input) : SV_TARGET
{
    // float4x4 shadowClipSpaceTobject = mul(shadow_clipSpaceTworld, worldTobject);
    float4 scsPparticlePos = mul(shadow_clipSpaceTworld, input.world_P);
    scsPparticlePos.xyz /= scsPparticlePos.w;
    scsPparticlePos.xy = scsPparticlePos.xy*0.5 + 0.5;
    scsPparticlePos.y = 1.0-scsPparticlePos.y;
    float sz = scsPparticlePos.z;
    float4 color = float4(0.75,0.6,0.4,1);
    float4 om = ShadowMap.SampleLevel(texSampler, scsPparticlePos.xy, 0);
    float4 mask0 = saturate((float4(sz,sz,sz,sz) - float4(0.00, 0.25, 0.50, 0.75)) * 4.0);
    om *= mask0;
    // om *= 0.25;
    float occlusion = 1.0 - saturate(om.x + om.y + om.z + om.w);
    // occlusion = 1.0 - om.w;
    color.rgb *= occlusion;
    color.a = 0.5;
    // color.rg *= input.texCoord;

    return color;float4(0.75,0.6,0.4,1); //saturate(Color);
}

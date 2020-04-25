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


Texture2D<float4> ShadowMap0 : register(t0); // opacity shadow map
Texture2D<float4> ShadowMap1 : register(t1); // opacity shadow map
Texture2D<float4> ShadowMap2 : register(t2); // opacity shadow map
Texture2D<float4> ShadowMap3 : register(t3); // opacity shadow map
sampler texSampler : register(s0);

struct Input
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
    float4 color : COLOR;
    float4 world_P : POSITION;
};

float getOcclusion(Texture2D<float4> shadowMap, float2 uv, float z)
{
    float sz = z;
    float4 color = float4(0.75,0.6,0.4,1);
    float4 om = shadowMap.SampleLevel(texSampler, uv, 0);
    float4 mask = saturate((float4(sz,sz,sz,sz) - float4(0.00, 0.25, 0.50, 0.75)) * 4.0);
    om *= mask;
    float occlusion = om.x + om.y + om.z + om.w;

    return occlusion;
}

float4 psMain(Input input) : SV_TARGET
{
    // float4 color = input.color;

    float4 scsPparticlePos = mul(shadow_clipSpaceTworld, input.world_P);
    scsPparticlePos.xyz /= scsPparticlePos.w;
    scsPparticlePos.xy = scsPparticlePos.xy*0.5 + 0.5;
    scsPparticlePos.y = 1.0-scsPparticlePos.y;
    float sz = scsPparticlePos.z - 0.25*0.25;

    float occlusion = 0.0;
    occlusion += getOcclusion(ShadowMap0, scsPparticlePos.xy, clamp(scsPparticlePos.z, 0, 0.25)*4.0);
    occlusion += getOcclusion(ShadowMap1, scsPparticlePos.xy, 4.0*(clamp(scsPparticlePos.z, 0.25, 0.5) - 0.25));
    occlusion += getOcclusion(ShadowMap2, scsPparticlePos.xy, 4.0*(clamp(scsPparticlePos.z, 0.5, 0.75) - 0.5));
    occlusion += getOcclusion(ShadowMap3, scsPparticlePos.xy, 4.0*(clamp(scsPparticlePos.z, 0.75, 1.0) - 0.75));
    occlusion *= 0.25;
    occlusion = 1.0 - saturate(occlusion);

    float4 color = float4(1,1,1,1);
    color.rgb *= occlusion;
    color.a = 0.2;

    // float2 xy = 2.0 * input.texCoord - float2(1,1);
    // float r2 = dot(xy, xy);
    // float opacity = exp2(-r2 * 5.0)*5;
    // color.a *= opacity;
    // color.a = 0.5;

    return color;
}

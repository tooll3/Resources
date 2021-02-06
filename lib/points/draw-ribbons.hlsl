#include "point.hlsl"
#include "point-light.hlsl"
#include "pbr.hlsl"

static const float3 Corners[] = 
{
  float3(0, -1, 0),
  float3(1, -1, 0), 
  float3(1,  1, 0), 
  float3(1,  1, 0), 
  float3(0,  1, 0), 
  float3(0, -1, 0),  
};

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
    float Spin;
    float Twist;
    float TextureMode;
    float2 TextureRange;    
};

cbuffer FogParams : register(b2)
{
    float4 FogColor;
    float FogDistance;
    float FogBias;   
}

cbuffer PointLights : register(b3)
{
    PointLight Lights[8];
    int ActiveLightCount;
}

struct psInput
{
    float4 position : SV_POSITION;
    float4 color : COLOR;
    float2 texCoord : TEXCOORD;
};

sampler texSampler : register(s0);

StructuredBuffer<Point> Points : t0;
Texture2D<float4> texture2 : register(t1);

psInput vsMain(uint id: SV_VertexID)
{
    psInput output;
    float discardFactor = 1;
    int quadIndex = id % 6;
    int particleId = id / 6;
    float3 cornerFactors = Corners[quadIndex];

    int offset = cornerFactors.x < 0.5 ? 0 : 1; 
    Point p = Points[particleId+offset];

    float side = cornerFactors.y;

    float3 widthV = rotate_vector(float3(side,0,0), p.rotation) * Width * p.w;;
    float3 pInObject = p.position + widthV;

    float3 normal = normalize(rotate_vector(float3(0,1,0), p.rotation));
    float4 normalInScreen = mul(float4(normal,0), ObjectToClipSpace);

    float4 pInScreen  = mul(float4(pInObject,1), ObjectToClipSpace);

    if(pInScreen.z < -0)
        discardFactor = 0;

    float3 lightDirection = float3(1.2, 1, -0.1);
    float phong = pow(  abs(dot(normal,lightDirection )),1);
    
    output.position = pInScreen;

    output.texCoord = float2(cornerFactors.x , cornerFactors.y /2 +0.5);
    output.color = Color;
    if(normalInScreen.z < 0) {
        output.color.rgb = float3(0.4,0,0);
    }
    
    output.color.rgb *= phong;
    output.color.a = discardFactor;

    float3 light = 0;
    float4 posInWorld = mul(float4(pInObject,1), ObjectToWorld);

    for(int i=0; i< ActiveLightCount; i++) {
        
        float distance = length(posInWorld.xyz - Lights[i].position);
        
        light += distance < Lights[i].range 
                          ? Lights[i].color * Lights[i].intensity / (distance * distance)
                          : 0 ;
    }
    output.color.rgb *= light;

    // Fog
    float4 posInCamera = mul(float4(pInObject,1), ObjectToCamera);
    float fog = pow(saturate(-posInCamera.z/FogDistance), FogBias);
    output.color.rgb = lerp(output.color.rgb, FogColor.rgb,fog);

    return output;    
}

float4 psMain(psInput input) : SV_TARGET
{
    float4 imgColor = texture2.Sample(texSampler, input.texCoord);
 
    float dFromLineCenter= abs(input.texCoord.y -0.5)*2;
    float a= 1; //smoothstep(1,0.95,dFromLineCenter) ;
    float4 color = input.color * imgColor;// * input.color;

    return clamp(float4(color.rgb, color.a * a), 0, float4(1,100,100,100));
}

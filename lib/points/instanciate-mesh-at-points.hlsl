#include "point.hlsl"
#include "point-light.hlsl"
#include "pbr.hlsl"

static const float3 Corners[] = 
{
  float3(-1, -1, 0),
  float3( 1, -1, 0), 
  float3( 1,  1, 0), 
  float3( 1,  1, 0), 
  float3(-1,  1, 0), 
  float3(-1, -1, 0), 
};


// struct Face
// {
//     float3 positions[3];
//     float2 texCoords[3];
//     float3 normals[3];
//     int id;
//     float normalizedFaceArea;
//     float cdf;
// };


struct PbrVertex
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
    float3 Bitangent;
    float2 TexCoord;
    float2 __padding;
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

cbuffer TimeConstants : register(b1)
{
    float GlobalTime;
    float Time;
    float RunTime;
    float BeatTime;
}


cbuffer Params : register(b2)
{
    float4 Color;    
    float Size;
    float SegmentCount;
};

cbuffer FogParams : register(b3)
{
    float4 FogColor;
    float FogDistance;
    float FogBias;   
}

cbuffer PointLights : register(b4)
{
    PointLight Lights[8];
    int ActiveLightCount;
}

cbuffer PbrParams : register(b5)
{
    float4 BaseColor;
    float4 EmissiveColor;
    float Roughness;
    float Specular;
    float Metal;
}

struct psInput
{
    //float4 worldPosition : SV_POSITION;
    //float4 color : COLOR;
    float2 texCoord : TEXCOORD;

    float4 pixelPosition : SV_POSITION;
    float3 worldPosition : POSITION;
    //float2 texcoord : TEXCOORD;
    float3x3 tangentBasis : TBASIS;    
    float fog:VPOS;
};

sampler texSampler : register(s0);

StructuredBuffer<PbrVertex> PbrVertices : t0;
StructuredBuffer<int3> FaceIndices : t1;
StructuredBuffer<Point> Points : t2;

Texture2D<float4> BaseColorMap : register(t3);
Texture2D<float4> EmissiveColorMap : register(t4);
Texture2D<float4> RSMOMap : register(t5);
Texture2D<float4> NormalMap : register(t6);


psInput vsMain(uint id: SV_VertexID)
{
    psInput output;

    uint faceCount, meshStride;
    FaceIndices.GetDimensions( faceCount,meshStride);

    int verticesPerInstance = faceCount * 3;

    int faceIndex = (id % verticesPerInstance) / 3;
    int faceVertexIndex = id % 3;

    uint instanceCount, instanceStride;
    Points.GetDimensions( instanceCount,instanceStride);

    int instanceIndex = id / verticesPerInstance;

    PbrVertex vertex = PbrVertices[FaceIndices[faceIndex][faceVertexIndex]];
    float4 posInObject = float4( vertex.Position,1);
    output.worldPosition = posInObject; //TODO: this is probably wrong

    posInObject.xyz *= Points[instanceIndex].w * Size;
    posInObject = float4(rotate_vector(posInObject.xyz, Points[instanceIndex].rotation ),1);

    posInObject += float4(Points[instanceIndex].position, 1) ; 

    float4 posInClipSpace = mul(posInObject, ObjectToClipSpace);
    //posInClipSpace /= posInClipSpace.w;
    output.pixelPosition = posInClipSpace;

    float2 uv = vertex.TexCoord;
    output.texCoord = float2(uv.x , 1- uv.y);

    // Pass tangent space basis vectors (for normal mapping).
    float3x3 TBN = float3x3(vertex.Tangent, vertex.Bitangent, vertex.Normal);
    output.tangentBasis = mul((float3x3)ObjectToWorld, transpose(TBN));

    //float3 light;

    // if(ActiveLightCount > 0) 
    // {
    //     light = 0; // HACK
    //     float4 posInWorld = mul(posInObject, ObjectToWorld);
    //     for(int i=0; i< ActiveLightCount; i++) 
    //     {            
    //         float distance = length(posInWorld.xyz - Lights[i].position);        
    //         light += distance < Lights[i].range 
    //                         ? (Lights[i].color.rgb * Lights[i].intensity.x / (distance * distance + 1))
    //                         : 0 ;
    //     }
    // }
    // else {
    //     light = 1;
    // }
    // output.color.rgb = light.rgb;

    // Fog
    if(FogDistance > 0) 
    {
        float4 posInCamera = mul(posInObject, ObjectToCamera);
        float fog = pow(saturate(-posInCamera.z/FogDistance), FogBias);
        output.fog = fog;
    }
    
    return output;
}

// float4 psMain(psInput input) : SV_TARGET
// {
//     float4 textureCol = albedoTexture.Sample(texSampler, input.texCoord);
//     float4 color = textureCol;
//     if(input.fog > 0) {
//         color = lerp(color, FogColor, input.fog);
//     }
//     return clamp(color, float4(0,0,0,0), float4(1000,1000,1000,1));// * float4(input.texCoord,1,1);    
// }


float4 psMain(psInput pin) : SV_TARGET
{
    // Sample input textures to get shading model params.
    float3 albedo = BaseColorMap.Sample(texSampler, pin.texCoord).rgb;
    float metalness = 0; //metalnessTexture.Sample(texSampler, pin.texCoord).r;
    float roughness = 0.4; //roughnessTexture.Sample(texSampler, pin.texCoord).r;

    // Outgoing light direction (vector from world-space fragment position to the "eye").
    float3 eyePosition =  mul( float4(0,0,0,1), CameraToWorld);
    float3 Lo = normalize(eyePosition - pin.worldPosition);

    // Get current fragment's normal and transform to world space.
    float3 N = float3(0,1,0);// normalize(2.0 * normalTexture.Sample(texSampler, pin.texCoord).rgb - 1.0);
    N = normalize(mul(pin.tangentBasis, N));
    
    // Angle between surface normal and outgoing light direction.
    float cosLo = max(0.0, dot(N, Lo));
        
    // Specular reflection vector.
    float3 Lr = 2.0 * cosLo * N - Lo;

    // Fresnel reflectance at normal incidence (for metals use albedo color).
    //float3 F0 = lerp(Fdielectric, albedo, metalness);
    float3 F0 = lerp(Fdielectric, albedo, metalness);

    // Direct lighting calculation for analytical lights.
    float3 directLighting = 0.0;
    for(uint i=0; i < ActiveLightCount; ++i)
    {
        float3 Li =  Lights[i].position; //- Lights[i].direction;
        float3 Lradiance = Lights[i].color; //Lights[i].radiance;

        // Half-vector between Li and Lo.
        float3 Lh = normalize(Li + Lo);

        // Calculate angles between surface normal and various light vectors.
        float cosLi = max(0.0, dot(N, Li));
        float cosLh = max(0.0, dot(N, Lh));

        // Calculate Fresnel term for direct lighting. 
        float3 F  = fresnelSchlick(F0, max(0.0, dot(Lh, Lo)));
        // Calculate normal distribution for specular BRDF.
        float D = ndfGGX(cosLh, roughness);
        // Calculate geometric attenuation for specular BRDF.
        float G = gaSchlickGGX(cosLi, cosLo, roughness);

        // Diffuse scattering happens due to light being refracted multiple times by a dielectric medium.
        // Metals on the other hand either reflect or absorb energy, so diffuse contribution is always zero.
        // To be energy conserving we must scale diffuse BRDF contribution based on Fresnel factor & metalness.
        float3 kd = lerp(float3(1, 1, 1) - F, float3(0, 0, 0), metalness);

        // Lambert diffuse BRDF.
        // We don't scale by 1/PI for lighting & material units to be more convenient.
        // See: https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
        float3 diffuseBRDF = kd * albedo;

        // Cook-Torrance specular microfacet BRDF.
        float3 specularBRDF = (F * D * G) / max(Epsilon, 4.0 * cosLi * cosLo);

        // Total contribution for this light.
        directLighting += (diffuseBRDF + specularBRDF) * Lradiance * cosLi;
    }

    // Ambient lighting (IBL).
    float3 ambientLighting;
    {
        // Sample diffuse irradiance at normal direction.
        float3 irradiance = 0;// irradianceTexture.Sample(texSampler, N).rgb;

        // Calculate Fresnel term for ambient lighting.
        // Since we use pre-filtered cubemap(s) and irradiance is coming from many directions
        // use cosLo instead of angle with light's half-vector (cosLh above).
        // See: https://seblagarde.wordpress.com/2011/08/17/hello-world/
        float3 F = fresnelSchlick(F0, cosLo);

        // Get diffuse contribution factor (as with direct lighting).
        float3 kd = lerp(1.0 - F, 0.0, metalness);

        // Irradiance map contains exitant radiance assuming Lambertian BRDF, no need to scale by 1/PI here either.
        float3 diffuseIBL = kd * albedo * irradiance;

        // Sample pre-filtered specular reflection environment at correct mipmap level.
        //uint specularTextureLevels = querySpecularTextureLevels(BaseColorMap);
        //float3 specularIrradiance = BaseColorMap.SampleLevel(texSampler, Lr.xy, roughness * specularTextureLevels).rgb;
        float3 specularIrradiance = 0;

        // Split-sum approximation factors for Cook-Torrance specular BRDF.
        float2 specularBRDF = 0.4; //specularBRDF_LUT.Sample(spBRDF_Sampler, float2(cosLo, roughness)).rg;

        // Total specular IBL contribution.
        float3 specularIBL = (F0 * specularBRDF.x + specularBRDF.y) * specularIrradiance;

        // Total ambient lighting contribution.
        ambientLighting = diffuseIBL + specularIBL;
    }

    // Final fragment color.
    return float4(directLighting + ambientLighting * 0, 1.0) * BaseColor;

    // float4 textureCol = albedoTexture.Sample(texSampler, input.texCoord);
    // float4 color = textureCol;
    // if(input.fog > 0) {
    //     color = lerp(color, FogColor, input.fog);
    // }
    // return clamp(color, float4(0,0,0,0), float4(1000,1000,1000,1));// * float4(input.texCoord,1,1);    
}

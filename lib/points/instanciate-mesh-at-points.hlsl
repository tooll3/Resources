#include "point.hlsl"
#include "point-light.hlsl"

static const float3 Corners[] = 
{
  float3(-1, -1, 0),
  float3( 1, -1, 0), 
  float3( 1,  1, 0), 
  float3( 1,  1, 0), 
  float3(-1,  1, 0), 
  float3(-1, -1, 0), 
};


struct Face
{
    float3 positions[3];
    float2 texCoords[3];
    float3 normals[3];
    int id;
    float normalizedFaceArea;
    float cdf;
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


struct psInput
{
    float4 position : SV_POSITION;
    float4 color : COLOR;
    float2 texCoord : TEXCOORD;
    float fog:VPOS;
};

sampler texSampler : register(s0);

StructuredBuffer<Point> Points : t0;
StructuredBuffer<Face> Faces : t1;

Texture2D<float4> texture2 : register(t2);

psInput vsMain(uint id: SV_VertexID)
{
    psInput output;

    uint faceCount, meshStride;
    Faces.GetDimensions( faceCount,meshStride);

    int verticesPerInstance = faceCount * 3;

    int faceIndex = (id % verticesPerInstance) / 3;
    int vertexIndex = id % 3;

    uint instanceCount, instanceStride;
    Points.GetDimensions( instanceCount,instanceStride);

    int instanceIndex = id / verticesPerInstance;

    // int quadIndex = id % 6;
    // int particleId = id / 6;
    // Point pointDef = Points[particleId];

    //float4 aspect = float4(CameraToClipSpace[1][1] / CameraToClipSpace[0][0],1,1,1);
    //float3 quadPos = Corners[quadIndex];
    //output.texCoord = (quadPos.xy * 0.5 + 0.5);

    //quadPos = rotate_vector(quadPos, pointDef.rotation); 
    //float3 quadPos2 = rotated;

    float4 posInObject = float4( Faces[faceIndex].positions[vertexIndex],1);
    posInObject.xyz *= Points[instanceIndex].w * Size;
    posInObject = float4(rotate_vector(posInObject.xyz, Points[instanceIndex].rotation ),1);

    posInObject += float4(Points[instanceIndex].position, 1) ; 

    float4 posInClipSpace = mul(posInObject, ObjectToClipSpace);
    posInClipSpace /= posInClipSpace.w;
    output.position = posInClipSpace;

    float2 uv = Faces[faceIndex].texCoords[vertexIndex];
    output.texCoord = float2(uv.x , 1- uv.y);

    float3 light;


    if(ActiveLightCount > 0) 
    {
        light = 0; // HACK
        float4 posInWorld = mul(posInObject, ObjectToWorld);
        for(int i=0; i< ActiveLightCount; i++) 
        {            
            float distance = length(posInWorld.xyz - Lights[i].position);        
            light += distance < Lights[i].range 
                            ? (Lights[i].color.rgb * Lights[i].intensity.x / (distance * distance + 1))
                            : 0 ;
        }
    }
    else {
        light = 1;
    }
    output.color.rgb = light.rgb;
    //output.color.rgb *= pointDef.rotation.xyz;
    //output.color =1;

    // Fog
    if(FogDistance > 0) 
    {
        float4 posInCamera = mul(posInObject, ObjectToCamera);
        float fog = pow(saturate(-posInCamera.z/FogDistance), FogBias);
        output.fog = fog;
        //output.color.rgb = fog; //lerp(output.color.rgb, FogColor.rgb, fog);
    }
    
    //output.color.rgb = float3(2,0,0);

    return output;
}

float4 psMain(psInput input) : SV_TARGET
{
    //return float4(1,1,0,1);

    //return float4(ActiveLightCount / 2.,0,0,1);
    float4 textureCol = texture2.Sample(texSampler, input.texCoord);
    float4 color = input.color * textureCol;
    if(input.fog > 0) {
        color = lerp(color, FogColor, input.fog);
    }
    // if(textureCol.a < 0.2)
    //     discard;

 
    return clamp(color, float4(0,0,0,0), float4(1000,1000,1000,1));// * float4(input.texCoord,1,1);    
}

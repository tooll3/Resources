#include "point.hlsl"
// struct Point
// {
//     float3 position;
//     float size;
// };

static const float3 Corners[] = 
{
  float3(0, -1, 0),
  float3(1, -1, 0), 
  float3(1,  1, 0), 
  float3(1,  1, 0), 
  float3(0,  1, 0), 
  float3(0, -1, 0),  
};

cbuffer Params : register(b0)
{
    float4 Color;
    float Size;

    float CurrentStep;
    float StepCount;
    float LinesPerStep;
    // float ShrinkWithDistance;
    // float OffsetU;
    // float UseWForWidth;
    // float UseWForU;
};


cbuffer Transforms : register(b1)
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

cbuffer FogParams : register(b2)
{
    float4 FogColor;
    float FogDistance;
    float FogBias;  
}

struct psInput
{
    float4 position : SV_POSITION;
    float4 color : COLOR;
    float2 texCoord : TEXCOORD;
    float fog: FOG;
};

sampler texSampler : register(s0);

// struct LinePointsIndices {
//     int StartIndex;
//     int EndIndex;
// };


StructuredBuffer<Point> Points : t0;
StructuredBuffer<uint2> LinePoints : t1;
Texture2D<float4> texture2 : register(t2);
Texture2D<float4> progressTexture : register(t3);

psInput vsMain(uint id: SV_VertexID)
{

    psInput output;
    float discardFactor = 1;

    uint pointCount, stride;
    Points.GetDimensions(pointCount, stride);

    float4 aspect = float4(CameraToClipSpace[1][1] / CameraToClipSpace[0][0],1,1,1);
    int quadIndex = id % 6;
    uint particleId = id / 6;
    float3 cornerFactors = Corners[quadIndex];
    
    uint2 indexPair = LinePoints[particleId];
    
    Point pointA = Points[indexPair.x];
    Point pointB = Points[indexPair.y];

    if(isnan(pointA.w) || isnan(pointB.w) ) 
    {
        output.position = 0;
        return output;
    }

    float4 forward = mul(float4(0,0,-1,0), CameraToWorld);
    forward = mul(float4(forward.xyz,0), WorldToObject);

    float3 posInObject = cornerFactors.x < 0.5
        ? pointA.position
        : pointB.position;

    float3 side = normalize(cross(forward.xyz, pointA.position- pointB.position));

    output.texCoord = float2(lerp( pointA.w  , pointB.w , cornerFactors.x), cornerFactors.y /2 +0.5);


    float stepIndex = (id /6) / LinesPerStep;
    
    float animationProgress = ((CurrentStep - stepIndex + StepCount)  % StepCount) / StepCount;
    float4 progressColor = progressTexture.SampleLevel(texSampler, float2(animationProgress, 0),0);

    //float3 side = float3(1,0,0);

    float hide = (indexPair.x== 0 || indexPair.y == 0 || indexPair.x >= pointCount || indexPair.y >= pointCount) ? sqrt(-1) : 1;

    posInObject += side * Size * cornerFactors.y * hide;

    //output.position =  float4(corner.xyz,1);
    output.position = mul(float4(posInObject,1), ObjectToClipSpace);

    float4 posInCamSpace = mul(float4(posInObject,1), ObjectToCamera);
    posInCamSpace.xyz /= posInCamSpace.w;
    posInCamSpace.w = 1;

    output.fog = pow(saturate(-posInCamSpace.z/FogDistance), FogBias);
    output.color =  Color.rgba * progressColor.rgba;
    return output;    
}

float4 psMain(psInput input) : SV_TARGET
{
    //return float4(1,1,0,1);
    float4 imgColor = texture2.Sample(texSampler, input.texCoord);
    float dFromLineCenter= abs(input.texCoord.y -0.5)*2;
    //float a= 1;//smoothstep(1,0.95,dFromLineCenter) ;

    float4 col = input.color * imgColor;
    col.rgb = lerp(col.rgb, FogColor.rgb, input.fog);
    return clamp(col, float4(0,0,0,0), float4(1000,1000,1000,1));

    // float4 color = lerp(input.color * imgColor, FogColor, input.fog); // * input.color;
    // return clamp(float4(color.rgb, color.a * a), 0, float4(100,100,100,1));
}

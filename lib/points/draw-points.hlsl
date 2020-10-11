struct Point
{
    float3 position;
    float size;
};

static const float3 Corners[] = 
{
  float3(-1, -1, 0),
  float3( 1, -1, 0), 
  float3( 1,  1, 0), 
  float3( 1,  1, 0), 
  float3(-1,  1, 0), 
  float3(-1, -1, 0), 
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

struct psInput
{
    float4 position : SV_POSITION;
    float4 color : COLOR;
    float2 texCoord : TEXCOORD;
    //float3 objectPos: POSITIONT;
    //float3 posInWorld: POSITIONT;
};

sampler texSampler : register(s0);

//StructuredBuffer<Particle> Particles : t0;
StructuredBuffer<Point> Points : t0;
Texture2D<float4> texture2 : register(t1);

psInput vsMain(uint id: SV_VertexID)
{
    psInput output;

    // Points
    int quadIndex = id % 6;
    int particleId = id / 6;
    float4 aspect = float4(CameraToClipSpace[1][1] / CameraToClipSpace[0][0],1,1,1);
    float3 quadPos = Corners[quadIndex];

    Point pointDef = Points[particleId];
    float4 worldPos = float4(pointDef.position,1);
    float4 quadPosInCamera = mul(worldPos, ObjectToCamera);
    output.color = Color;
    quadPosInCamera.xy += quadPos.xy*0.050  * pointDef.size * Size;
    output.position = mul(quadPosInCamera, CameraToClipSpace);
    //output.posInWorld = mul(quadPosInCamera, CameraToWorld).xyz;
    output.color.a = 1;
    output.texCoord = (quadPos.xy * 0.5 + 0.5);
    //output.objectPos = worldPos;
    return output;


    // Lines
    // float4 aspect = float4(CameraToClipSpace[1][1] / CameraToClipSpace[0][0],1,1,1);
    // int quadIndex = id % 6;
    // int particleId = id / 6;
    // float3 cornerFactors = Corners[quadIndex];
    

    // Point pointAA = Points[ particleId<1 ? 0: particleId-1];
    // Point pointA = Points[particleId];
    // Point pointB = Points[particleId+1];
    // Point pointBB = Points[particleId+2];

    // float4 aaInScreen  = mul(float4(pointAA.position,1), ObjectToClipSpace);
    // float4 aInScreen  = mul(float4(pointA.position,1), ObjectToClipSpace);
    // float4 bInScreen  = mul(float4(pointB.position,1), ObjectToClipSpace);
    // float4 bbInScreen  = mul(float4(pointBB.position,1), ObjectToClipSpace);

    // float3 direction = (aInScreen - bInScreen).xyz;
    // float3 directionA = (aaInScreen - aInScreen).xyz;
    // float3 directionB = (bInScreen - bbInScreen).xyz;

    // float3 normal =  normalize(cross(direction, float3(0,0,1))); 

    // float3 normalA =  normalize(cross(directionA, float3(0,0,1))); 
    // float3 normalB =  normalize(cross(directionB, float3(0,0,1))); 

    // float3 neighboarNormal = lerp(normalA, normalB, cornerFactors.x);
    // float3 meterNormal = normalize(normal + neighboarNormal) / aspect.xyz;

    // float thickness = lerp( pointA.size , pointB.size, cornerFactors.x) * Size;
    // //float thickness = 1;

    // float4 pos = lerp(aInScreen, bInScreen, cornerFactors.x);
    // pos+= cornerFactors.y * 0.1f * thickness * float4(meterNormal,0);

    // output.position = pos;

    // float strokeFactor = (particleId+ cornerFactors.x) / SegmentCount;
    // output.texCoord = float2(strokeFactor, cornerFactors.y /2 +0.5);
    // output.color = Color;
    // return output;    
}

float4 psMain(psInput input) : SV_TARGET
{
    //return float4(1,1,0,1);
    // float2 p = input.texCoord * float2(2.0, 2.0) - float2(1.0, 1.0);
    // float d= dot(p, p);
    // if (d > 1.0)
    //      discard;
    float4 xxx = texture2.Sample(texSampler, input.texCoord);
    return clamp(input.color * xxx, float4(0,0,0,0), float4(1,1000,1000,1000));// * float4(input.texCoord,1,1);    
}

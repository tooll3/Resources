
static const float3 Quad[] = 
{
  float3(0, -1, 0),
  float3( 1, -1, 0), 
  float3( 1,  0, 0), 
  float3( 1,  0, 0), 
  float3(0,  0, 0), 
  float3(0, -1, 0), 

};

static const float4 UV[] = 
{ 
    //    min  max
     //   U V  U V
  float4( 1, 0, 0, 1), 
  float4( 0, 0, 1, 1), 
  float4( 0, 1, 1, 0), 
  float4( 0, 1, 1, 0), 
  float4( 1, 1, 0, 0), 
  float4( 1, 0, 0, 1), 
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
    float2 GridSize;
    float2 CellSize;

    float2 CellPadding;
    float2 TextOffset;
    float4 Color;

    float3 OverridePosition;
    float OverrideScale;

    float4 HighlightColor;
    float OverrideBrightness;
};

struct GridEntry
{
    // float2 gridPos;
    // float2 charUv;
    // float highlight;
    // float3 __filldummy;
    //float2 size;
    //float2 __filldummy;

    float3 Position;
    float Size;
    float3 Orientation;
    float AspectRatio;
    float4 Color;
    float4 UvMinMax;
    float BirthTime;
    float Speed;
    uint Id;        
};

struct Output
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
    float4 color : COLOR;
};

StructuredBuffer<GridEntry> GridEntries : t0;
Texture2D<float4> fontTexture : register(t1);
sampler texSampler : register(s0);


Output vsMain(uint id: SV_VertexID)
{
    Output output;

    int vertexIndex = id % 6;
    int entryIndex = id / 6;
    float3 quadPos = Quad[vertexIndex];


    GridEntry entry = GridEntries[entryIndex];
    // float2 samplePos = float2(0,1)+entry.Position * float2(1,-1);

    // float4 overrideColor = fontTexture.SampleLevel(texSampler, samplePos - (TextOffset.xy * float2(1,-1) % 1) / GridSize, 0);
    // overrideColor = clamp(overrideColor, 0, float4(1,100,100,1));    
    // float overrideDisplace = overrideColor.b;
    // float overrideScale = overrideColor.g;
    // float overrideBrightness = clamp((overrideColor.r * 0.5 + overrideColor.b * 0.3 + overrideColor.g * 0.2) * overrideColor.a,0,1);

    // float2 centeredGridPos = float2( (entry.Position.x - 0.5) * GridSize.x, 
    //                                 (-0.5 + entry.Position.y ) * GridSize.y
    //                             );
    // centeredGridPos.xy +=  TextOffset.xy * float2(-1,1) % 1;

    //float3 posInObject =  float3( centeredGridPos * CellSize,0 );
    float3 posInObject = entry.Position;

    //objectPos += float3(GridSize.x *-0.5, +GridSize.y * 0.5 ,0);
    //posInObject+= float3( overrideDisplace * OverridePosition);

    float4 quadPosInWorld = mul(float4(posInObject.xyz,1), ObjectToWorld);
    
    quadPosInWorld.xy += quadPos.xy * float2(entry.Size * entry.AspectRatio, entry.Size) ; //CellSize *  (1- CellPadding) * (1+overrideScale* OverrideScale) /2;
    
    float4 quadPosInCamera = mul(quadPosInWorld, WorldToCamera);
    output.position = mul(quadPosInCamera, CameraToClipSpace);
    //output.position.z = 0;
    //output.color = lerp(Color, HighlightColor, entry.highlight) * overrideBrightness;
    //output.texCoord = (entry.charUv + quadPos * float2(0.5, -0.5) + 0.5)/16;
    float4 uv = entry.UvMinMax * UV[vertexIndex];
    output.texCoord =  uv.xy + uv.zw;
    return output;
}


struct PsInput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
    float4 color : COLOR;
};

float median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

float4 psMain(PsInput input) : SV_TARGET
{
    float4 texColor = fontTexture.Sample(texSampler, input.texCoord);

    float2 msdfUnit = float2(1,1) * 1;// pxRange/float2(textureSize(msdf, 0));

    float sigDist = median(texColor.r, texColor.g, texColor.b) - 0.5;
    sigDist *= dot(msdfUnit, 0.5/fwidth(texColor).x);
    float opacity = clamp(sigDist + 0.5, 0.0, 1.0);
    float4 bgColor = float4(1,1,1,0);
    float4 fgColor = float4(1,1,1,1);
    float4 color = lerp(bgColor, fgColor, opacity);    
    return color;// + float4(0.1,0.1,0.1,0.2);
}

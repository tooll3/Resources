#include "point.hlsl"


static const float3 Quad[] = 
{
  // xy front
  float3(-1, -1, 1),
  float3( 1, -1, 1), 
  float3( 1,  1, 1), 
  float3( 1,  1, 1), 
  float3(-1,  1, 1), 
  float3(-1, -1, 1), 
  // yz right
  float3(1, -1,  1),
  float3(1, -1, -1),
  float3(1,  1, -1),
  float3(1,  1, -1),
  float3(1,  1,  1), 
  float3(1, -1,  1),
  // xz top
  float3(-1, 1,  1),
  float3( 1, 1,  1),
  float3( 1, 1, -1),
  float3( 1, 1, -1),
  float3(-1, 1, -1),
  float3(-1, 1,  1),
  // xy back
  float3( 1, -1, -1),
  float3(-1, -1, -1),
  float3(-1,  1, -1),
  float3(-1,  1, -1),
  float3( 1,  1, -1),
  float3( 1, -1, -1),
  // yz left
  float3(-1, -1, -1),
  float3(-1, -1,  1),
  float3(-1,  1,  1),
  float3(-1,  1,  1),
  float3(-1,  1, -1),
  float3(-1, -1, -1),
  // xz bottom
  float3(-1, -1,  1),
  float3( 1, -1,  1),
  float3( 1, -1, -1),
  float3( 1, -1, -1),
  float3(-1, -1, -1),
  float3(-1, -1,  1),
};



float3 UvAndIndexToBoxCoord(float2 uv, uint face)
{
    float3 n = float3(0,0,0);
    float3 t = float3(0,0,0);

    // xy front
    if (face == 0) // negz (yellow)
    {
        n = float3(0,0,1);
        t = float3(0,1,0);
    }
        // yz right    
    else if (face == 1) // posx (red)
    {
        n = float3(1,0,0);
        t = float3(0,1,0);
    }
        // xz top
    else if (face == 2) // negy (magenta)
    {
        n = float3(0,1,0);
        t = float3(0,0,1);
    }
        // xy back
    else if (face == 3) // posz (blue)
    {
        n = float3(0,0,-1);
        t = float3(0,1,0);
    }
        // yz left
    else if (face == 4) // negx (cyan)
    {
        n = float3(-1,0,0);
        t = float3(0,1,0);
    }
    // xz bottom
    else if (face == 5) // posy (green)
    {
        n = float3(0,-1,0);
        t = float3(0,0,-1);
    }
    float3 x = cross(n, t);
 
    uv = uv * 2 - 1;
     
    n = n + t*uv.y + x*uv.x;
    n.y *= -1;
    n.z *= -1;
    return n;
}


//static const float Roughness = 0;
//static const int NumSamples = 1;

cbuffer Params : register(b0)
{
    float Orientation;
}

//TextureCube<float4> CubeMap : register(t0);
Texture2D Image : register(t0);
sampler texSampler : register(s0);


float2 ComputeUvFromNormal(float3 n) 
{
    //float PI = 3.141578;
    float3 N = normalize(n);      
    float2 uv = N.xy;
    uv.y = acos(N.y) / PI + 1;
    uv.x = atan2(N.x, N.z) / PI /2 + 1;
    return uv;
}

 
struct vsOutput
{
    float4 position : SV_POSITION;
    float3 normal : TEXCOORD0;
    float4 color : COLOR0;
    uint faceId : SV_RENDERTARGETARRAYINDEX;
};

vsOutput vsMain(uint vertexId: SV_VertexID)
{
    vsOutput output;

    int faceIndex = vertexId / 6;

    float4 quadPos = float4(Quad[vertexId], 1) ;

    float2 uv= quadPos.xy*float2(0.5, -0.5) + 0.5;
    output.normal= UvAndIndexToBoxCoord(uv, faceIndex);
    output.position = quadPos;
    output.faceId = faceIndex;
    output.color = 1;
    return output; 
}

float4 psMain(in vsOutput i) : SV_TARGET0
{
    float2 uv = ComputeUvFromNormal(i.normal) + float2(Orientation, 0);
    return Image.Sample(texSampler,uv);
}

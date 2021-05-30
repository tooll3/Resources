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

static const float Roughness = 0;
static const int NumSamples = 1;

cbuffer Params : register(b0)
{
    //float Roughness;
}

TextureCube<float4> CubeMap : register(t0);
sampler texSampler : register(s0);


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

//----------------------------------------------------------------------------
float radicalInverse_VdC(uint bits) 
{
     bits = (bits << 16u) | (bits >> 16u);
     bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
     bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
     bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
     bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
     return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}

// http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
float2 Hammersley(uint i, uint N)
{
    return float2(float(i)/float(N), radicalInverse_VdC(i));
}

float G_schlick_IBL(float NoV, float NoL, float roughness)
{
    float k = roughness*roughness/2.0f;
    float one_minus_k = 1.0f - k;
    return (NoL / (NoL * one_minus_k + k)) * (NoV / (NoV * one_minus_k + k) );
}
 
// Image-Based Lighting
// http://www.unrealengine.com/files/downloads/2013SiggraphPresentationsNotes.pdf
float3 ImportanceSampleGGX( float2 Xi, float roughness, float3 N )
{
    float a = roughness * roughness;
    float Phi = 2 * PI * Xi.x;
    float CosTheta = sqrt( (1 - Xi.y) / ( 1 + (a*a - 1) * Xi.y ) );
    float SinTheta = sqrt( 1 - CosTheta * CosTheta );
    float3 H;
    H.x = SinTheta * cos( Phi );
    H.y = SinTheta * sin( Phi );
    H.z = CosTheta;
    float3 UpVector = abs(N.z) < 0.999 ? float3(0,0,1) : float3(1,0,0);
    float3 TangentX = normalize( cross( UpVector, N ) );
    float3 TangentY = cross( N, TangentX );
    // Tangent to world space
    return TangentX * H.x + TangentY * H.y + N * H.z;
}
 
 
// Ignacio Castano via http://the-witness.net/news/2012/02/seamless-cube-map-filtering/
float3 fix_cube_lookup_for_lod(float3 v, float cube_size, float lod)
{
    float M = max(max(abs(v.x), abs(v.y)), abs(v.z));
    float scale = 1 - exp2(lod) / cube_size;
    if (abs(v.x) != M) v.x *= scale;
    if (abs(v.y) != M) v.y *= scale;
    if (abs(v.z) != M) v.z *= scale;
    return v;
}

float D_GGX(float NoH, float roughness)
{
    // towbridge-reitz / GGX distribution
    float alpha = roughness*roughness;
    float alpha2 = alpha*alpha;
    float NoH2 = NoH*NoH;
    float f = NoH2 * (alpha2 - 1.0) + 1;
    return alpha2 / (3.1415 * f*f);
}


float4 psMain(in vsOutput i) : SV_TARGET0
{
    float3 N = normalize(i.normal);
//    return colorOfBox(i.face);
     
    float4 totalRadiance = float4(0,0,0,0);
    float roughness = max(Roughness, 0.01);
    
#ifdef REFERENCE_ON
    uint NUM_SAMPLES = 25000;
#else
    uint NUM_SAMPLES = NumSamples;
#endif

    [fastopt]
    for (uint j = 0; j < NUM_SAMPLES; ++j)
    {
        float2 Xi = Hammersley(j, NUM_SAMPLES);
        float3 H = ImportanceSampleGGX(Xi, roughness, N);
        float3 L = 2*dot(N, H)*H - N;
        float NdotL = saturate(dot(N, L));

        if (NdotL > 0)
        {

#ifdef REFERENCE_ON
            float mipmapLevel = 0;
#else
            float NdotH = saturate(dot(N,H));        
            
            float pdf_H = D_GGX(NdotH, roughness)*NdotH;
            float pdf = pdf_H/(4*NdotH); // transform from half to incoming
            
            float area = 2*3.1415f; // hemispehere area
            float solidangleSample = area/(NUM_SAMPLES*pdf); // solid angle for sample
            float solidangleTexel = area/(3.0*128*128); // solid angle per cubemap texel 

            const int BaseMip = 0;
            float mipmapLevel = clamp(0.5 * log2(solidangleSample/solidangleTexel), BaseMip, 9);
#endif

            totalRadiance.rgb += CubeMap.SampleLevel(texSampler, L, mipmapLevel).rgb*NdotL;
            totalRadiance.w += NdotL;
        }
    }
//return float4(Roughness, Roughness, Roughness, 1);
    return float4(totalRadiance.rgb / totalRadiance.w, 1);
}

cbuffer ParamConstants : register(b0)
{
    float4 Fill;
    float4 Background;
    float4 LineColor;
    float2 Center;
    float Scale;
    float ImageScale;
    float PingPong;
    float LineThickness;
    float Smooth;
    float Bias;
}

cbuffer TimeConstants : register(b1)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

cbuffer TimeConstants : register(b2)
{
    float TargetWidth;
    float TargetHeight;
}

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

Texture2D<float4> ImageA : register(t0);
sampler texSampler : register(s0);

//#define mod(x, y) (x - y * floor(x / y))

float mod(float x, float y) {
    return (x - y * floor(x / y));
} 


float2 mod(float2 x, float2 y) {
    return (x - y * floor(x / y));
} 

// "ShaderToy Tutorial - Hexagonal Tiling" 
// by Martijn Steinrucken aka BigWings/CountFrolic - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// This shader is part of a tutorial on YouTube
// https://youtu.be/VmrIDyYiJBA

float HexDist(float2 p) {
	p = abs(p);
    
    float c = dot(p, normalize(float2(1,1.73)));
    c = max(c, p.x);
    
    return c;
}

float4 HexCoords(float2 uv) {
	float2 r = float2(1, 1.73);
    float2 h = r*.5;
    
    float2 a = mod(uv, r)-h;
    float2 b = mod(uv-h, r)-h;
    
    float2 gv = dot(a, a) < dot(b,b) ? a : b;
    
    float x = atan2(gv.x, gv.y);
    float y = .5-HexDist(gv);
    float2 id = uv-gv;
    return float4(x, y, id.x,id.y);
}


float4 psMain(vsOutput psInput) : SV_TARGET
{    
    float aspectRatio = TargetWidth/TargetHeight;
    float2 p = psInput.texCoord;
    p.x *= 1.777;
    p *=2;
    float2 uv = p;
    float3 col = float3(0,0,0);
    uv *= Scale;    
    float4 hc = HexCoords(uv);    

    float value = sin(hc.z*hc.w+beatTime );
    
    float4 orgColor = ImageA.Sample(texSampler, hc.zw * ImageScale);
    value = orgColor.g /4;
    float c = smoothstep(.001, .015, hc.y * value) * (1-value*4);    
    col = lerp(Background, Fill,c);
    return float4(col,1.0);
}
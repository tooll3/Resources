cbuffer ParamConstants : register(b0)
{
    float4 Fill;
    float4 Background;
    float2 Offset;
    float Divisions;
    float LineThickness;    
    float MixOriginal;
    // float ImageDivisions;
    // float PingPong;
    // float Smooth;
    // float Bias;
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
Texture2D<float> Effects : register(t1);
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
    //float4 orgColor2 = ImageA.Sample(texSampler, psInput.texCoord);
    //return float4(orgColor2.r,0,0,1);


    float aspectRatio = TargetWidth/TargetHeight;
    float2 p = psInput.texCoord;
    float2 cellOffset = Offset/ Divisions;

    p.x /= aspectRatio;
    p += cellOffset;
    p-= float2(0.5, 0.5);
    p *= Divisions;

    float4 col = float4(0,0,0,0);
    float4 hc = HexCoords(p);    
    float2 uv = (hc.zw /Divisions  + 0.5 - cellOffset)* float2(aspectRatio,1);

    float4 orgColor = ImageA.Sample(texSampler, uv);
    //return float4(orgColor.r,0,0,1);
    //return orgColor;

    //float value = sin(hc.z*hc.w+globalTime );
    
    //return float4(hc.zw/10,0,1);

    //float4 orgColor = ImageA.Sample(texSampler, hc.zw * ImageDivisions);
    float value = (orgColor.r +orgColor.g + orgColor.b)  /3;

    //float xxx = Effects.Sample(texSampler, float2(hc.y,0));

    //value = Effects.Sample(texSampler, value) / 100;
    //float yyy = Effects.Sample(texSampler, float2(value,0));

    float4 orgColorWithDisplacement = ImageA.Sample(texSampler, uv - 0.1 );
    float c = smoothstep(.001, LineThickness / 100, hc.y * value) * (1-value*4);    
    col = lerp(Background, Fill,c);
    //col = lerp(col, orgColorWithDisplacement, MixOriginal);
    return float4(col);

}
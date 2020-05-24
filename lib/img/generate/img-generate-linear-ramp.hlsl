cbuffer ParamConstants : register(b0)
{
    float4 Fill;
    float4 Background;
    float2 Center;
    float Width;
    float Rotation;
    float PingPong;
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

cbuffer Resolution : register(b2)
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

float4 psMain(vsOutput psInput) : SV_TARGET
{    
    float2 uv = psInput.texCoord;
    //float4 orgColor = inputTexture.SampleLevel(texSampler, uv, 0.0);

    float aspectRation = TargetWidth/TargetHeight;
    float2 p = uv;
    p-= 0.5;
    p.x *=aspectRation;

    //float2 p = psInput.texCoord;

    float radians = Rotation / 180 *3.141578;
    float2 angle =  float2(sin(radians),cos(radians));

    float4 orgColor = ImageA.Sample(texSampler, psInput.texCoord);

    float c=  dot(p-Center, angle);

    if(PingPong > 0.5) {
        c = abs(c) / Width;
    }
    else {
        c = saturate(c /Width + 0.5);
    }
    

    if(Smooth > 0.5) {
        c= smoothstep(0,1,c);
    }

    float dBiased = Bias>= 0 
        ? pow( c, Bias+1)
        : 1-pow( clamp(1-c,0,10), -Bias+1);

    float4 cOut= lerp(Fill, Background, dBiased);

    float a = orgColor.a + cOut.a - orgColor.a*cOut.a;
    float3 rgb = (1.0 - cOut.a)*orgColor.rgb + cOut.a*cOut.rgb;   

    return float4(rgb,a);
}
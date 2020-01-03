Texture2D<float4> inputTexture : register(t0);
sampler texSampler : register(s0);

cbuffer ParamConstants : register(b0)
{
    float4 MapBlackTo;
    float4 MapWhiteTo;
    float4 ChannelWeights;
    float Amount;
    float Bias;
}


cbuffer TimeConstants : register(b1)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};


float4 psMain(vsOutput psInput) : SV_TARGET
{
    //return float4(1,1,0,1); 
    float2 uv = psInput.texCoord;
    float4 c = inputTexture.SampleLevel(texSampler, uv, 0.0);

    float t = length(c * normalize(ChannelWeights)) + 0.0001;
    //float b = Bias +1;
    t = Bias> 0 
        ? pow( t, Bias+1)
        : 1-pow( 1-t, -Bias+1);

    float4 mapped = lerp(MapBlackTo, MapWhiteTo, t); 

    return lerp(c, mapped, Amount);
}

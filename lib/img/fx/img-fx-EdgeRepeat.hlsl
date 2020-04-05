cbuffer ParamConstants : register(b0)
{
    float4 Fill;
    float4 Background;
    float4 LineColor;
    float2 Center;
    float Width;
    float Rotation;
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

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

Texture2D<float4> ImageA : register(t0);
sampler texSampler : register(s0);

float4 psMain(vsOutput psInput) : SV_TARGET
{    

    float width, height;
    ImageA.GetDimensions(width, height);

    float aspectRatio = width/height;
    float2 p = psInput.texCoord;
    p.x *= aspectRatio;

    // Show Center
    // if( length(p - Center) < 0.01) {
    //     return float4(1,1,0,1);
    // }

    float radians = Rotation / 180 *3.141578;
    float2 angle =  float2(sin(radians),cos(radians));


    //float4 orgColor = ImageA.Sample(texSampler, psInput.texCoord);

    float dist=  dot(p-Center, angle) / Width;


    if(dist < 0) {
        dist = -dist;
        angle *= -1;
    }
    // if(PingPong > 0.5) {
    //     c = abs(-c);
    // }
    // else {
    //     c= c +0.5 * Width;
    // }

    float4 colorEffect = Fill;


    // if(Smooth > 0.5) {
    //     c= smoothstep(0,1,c);
    // }

    if(dist > 1 ) {
        p -= (dist - 1) * Width * angle;
        colorEffect = Background;
    }

    float line2= smoothstep(1,0, abs(1-dist)*1000*Width-LineThickness+1);

    colorEffect = lerp(colorEffect, LineColor, line2);

    //if( abs(1-dist) < 0.01)
    //    return LineColor;


    return ImageA.Sample(texSampler, p) * colorEffect;

    // float dBiased = Bias>= 0 
    //     ? pow( c, Bias+1)
    //     : 1-pow( clamp(1-c,0,10), -Bias+1);

    // //d = smoothstep(Round, Round+Feather, dBiased);

    // float4 cOut= lerp(Fill, Background, dBiased);

    // float a = orgColor.a + cOut.a - orgColor.a*cOut.a;
    // float3 rgb = (1.0 - cOut.a)*orgColor.rgb + cOut.a*cOut.rgb;   

    // return float4(rgb,a);
}
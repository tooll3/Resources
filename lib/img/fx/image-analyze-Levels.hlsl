cbuffer ParamConstants : register(b0)
{
    //float4 Fill;
    //float4 Background;
    float2 Center;
    float Width;
    float Rotation;
    float TestParam;
    // float PingPong;
    // float Repeat;
    // float Bias;
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

Texture2D<float4> inputTexture : register(t0);
sampler texSampler : register(s0);


float IsBetween( float value, float low, float high) {
    return (value >= low && value <= high) ? 1:0;
}


float4 psMain(vsOutput psInput) : SV_TARGET
{
    uint width, height;
    inputTexture.GetDimensions(width, height);

    float2 uv = psInput.texCoord;
    //float4 orgColor = inputTexture.SampleLevel(texSampler, uv, 0.0);

    float aspectRation = TargetWidth/TargetHeight;
    float2 p = uv;
    p-= 0.5;
    p.x *=aspectRation;

    //float2 p = psInput.texCoord;

    float radians = Rotation / 180 *3.141578;
    float2 angle =  float2(sin(radians),cos(radians));


    float distanceFromCenter=  dot(p-Center, angle);
    float normalizedDistance  = -distanceFromCenter / Width;
    if(normalizedDistance < 0) {
        //return float4(p* 10 %1,0,1);
        return inputTexture.Sample(texSampler, uv);
    }

    if( IsBetween(normalizedDistance, 1, 1.01)) {
        return float4(0.4,0.4,0.4,1);
    }

    // if( IsBetween(normalizedDistance, 0, 0.01)) {
    //     return float4(0,0,0,1);
    // }


    //if(normalizedDistance < 1)  {
        //p.x *= aspectRation;
        //p.y+= 0.25;        
        float2 pOnLine = p;
        pOnLine +=  (- distanceFromCenter)  *  angle;
        pOnLine.x /= aspectRation;
        pOnLine += 0.5;
        //return float4(pOnLine * 10 %1,0,1);
        //float2 pOnLine = p-Center +  distanceFromCenter * angle;
        float4 colorOnLine = inputTexture.Sample(texSampler, pOnLine);

        float4 curveColor = float4(0,0,0,1);

        curveColor.rgb = (colorOnLine.rgb < normalizedDistance ) ? 0:0.2;
        curveColor.rgb *= (colorOnLine.rgb < normalizedDistance + 0.01 ) ? 3:1;
        //curveColor.r = (colorOnLine.r < normalizedDistance ) ? 1:0;

        return curveColor;
    //}

    //return float4(0,0,0,1);
    
    //float4 orgColor = 


    // c = PingPong > 0.5 
    //     ? (Repeat < 0.5 ? (abs(c) / Width)
    //                     : 1-abs( fmod(c,Width *2) -Width)  / Width)
    //     : c / Width + 0.5;

    // c = Repeat > 0.5 
    //     ? fmod(c,1)
    //     : saturate(c);

    // if(Smooth > 0.5) {
    //     c= smoothstep(0,1,c);
    // }

    // float dBiased = Bias>= 0 
    //     ? pow( c, Bias+1)
    //     : 1-pow( clamp(1-c,0,10), -Bias+1);

    //float4 cOut= lerp(Fill, Background, dBiased);

    //float4 rgb = float39

    // float4 gradient = Gradient.Sample(texSampler, float2(dBiased, 0));
    // float a = orgColor.a + gradient.a - orgColor.a*gradient.a;
    // float3 rgb = (1.0 - gradient.a)*orgColor.rgb + gradient.a*gradient.rgb;   

    //return float4(rgb,a);
}

cbuffer ParamConstants : register(b0)
{
    float2 Center;
    float Width;
    float Rotation;
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

    float aspectRation = TargetWidth/TargetHeight;
    float2 p = uv;
    p-= 0.5;
    p.x *=aspectRation;

    float radians = Rotation / 180 *3.141578;
    float2 angle =  float2(sin(radians),cos(radians));
    float distanceFromCenter=  dot(p-Center, angle);
    float normalizedDistance  = -distanceFromCenter / Width;
    if(normalizedDistance < 0) {
        return inputTexture.Sample(texSampler, uv);
    }

    if( IsBetween(normalizedDistance, 1, 1.01)) {
        return float4(0.2, 0.2, 0.2, 1);
    }

    float2 pOnLine = p;
    pOnLine +=  (- distanceFromCenter)  *  angle;
    pOnLine.x /= aspectRation;
    pOnLine += 0.5;
    float4 colorOnLine = inputTexture.Sample(texSampler, pOnLine);
    float4 curveColor = float4(0,0,0,1);

    curveColor.rgb = (colorOnLine.rgb < normalizedDistance ) ? 0:0.3;
    curveColor.rgb *= (colorOnLine.rgb < normalizedDistance + 0.02 ) ? 3:1;

    
    curveColor.rgb += inputTexture.Sample(texSampler, uv) * ((normalizedDistance <1) ? 0.6 : 1);
    return curveColor;
}

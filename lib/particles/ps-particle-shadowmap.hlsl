
struct Input
{
    float4 position : SV_POSITION;
    float4 mask : MASK;
    float2 texCoord : TEXCOORD0;
};

float4 psMain(Input input) : SV_TARGET
{
    // return float4(input.mask.rgb, 1);
    // return input.mask;
    float2 xy = 2.0 * input.texCoord - float2(1,1);
    float r2 = dot(xy, xy);
    float opacity = exp2(-r2 * 5.0) * 0.025;

    float f = 0.1;//5.0/255.0;
    // opacity = float4(f,f,f,f);
    // return opacity;
    return opacity * input.mask;
}
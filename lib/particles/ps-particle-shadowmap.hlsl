
struct Input
{
    float4 position : SV_POSITION;
    float4 mask : MASK;
};

float4 psMain(Input input) : SV_TARGET
{
    // return float4(input.mask.rgb, 1);
    // return input.mask;
    float4 opacity = float4(0.1, 0.1, 0.1, 0.1);
    // return opacity;
    return opacity * input.mask;
}

struct Input
{
    float4 position : SV_POSITION;
    float4 color : COLOR;
    float2 texCoord : TEXCOORD0;
};

float4 psMain(Input input) : SV_TARGET
{
    float2 p = input.texCoord * float2(2.0, 2.0) - float2(1.0, 1.0);
    float d= dot(p, p);
    if (d > 1.0)
         discard;


    float4 color = input.color * float4(1-d,1-d,1-d,1);
    return color;
}

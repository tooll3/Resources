Texture2D<float> inputTexture : register(t0);
RWTexture2D<float2> outputTexture : register(u0);

cbuffer ParamConstants : register(b0)
{
    float NearCoCBegin;
    float NearCoCEnd;
    float FarCoCBegin;
    float FarCoCEnd;
}

[numthreads(16,16,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    float n = 0.1;
    float f = 1000.0;
    float depth = n + inputTexture[i.xy] * (f - n);
    float nearCoC = 1.0 - saturate((depth - NearCoCBegin)/(NearCoCEnd - NearCoCBegin));
    float farCoC = saturate((depth - FarCoCBegin)/(FarCoCEnd - FarCoCBegin));

    outputTexture[i.xy] = float2(nearCoC, farCoC);
}

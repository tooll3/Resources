//RWTexture2D<float4> outputTexture : register(u0);
Texture2D<float4> inputTexture : register(t0);
sampler texSampler : register(s0);

cbuffer ParamConstants : register(b0)
{
    float4 Fill;
    float4 Background;
    float2 Size;
    float2 Offset;
    float2 OffsetCopies;

    float Rotate;
    float LineWidth;
    float Fade;
    float Copies;
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

static float PI2 = 2*3.141578;

#define mod(x,y) (x-y*floor(x/y))

float4 psMain(vsOutput psInput) : SV_TARGET
{
    float2 uv = psInput.texCoord;
    float4 orgColor = inputTexture.SampleLevel(texSampler, uv, 0.0);
    //return float4(MixOriginal, 0,0,1);

    float aspectRation = TargetWidth/TargetHeight;
    float2 p = uv;
    p-= 0.5;
    
    //float edgeSmooth = 0.1 / Amplitude;

    // Rotate
    float imageRotationRad = (-Rotate - 90) / 180 *3.141578;     
    float aspectRatio = TargetWidth/TargetHeight;

    float sina = sin(-imageRotationRad - 3.141578/2);
    float cosa = cos(-imageRotationRad - 3.141578/2);

    p.x *=aspectRation;

    p = float2(
        cosa * p.x - sina * p.y,
        cosa * p.y + sina * p.x 
    );


    p.x /=aspectRation;
    
    float c;
    int copiesCount = clamp((int)Copies, 1, 10);
    float2 pp = p;
    for(int i=0; i < copiesCount; i++) {
        pp.y = p.y+ sin(
                pp.x / Size.x * PI2/2 
                + Offset.x/2 * PI2 
                +  OffsetCopies.x * PI2 * i
                ) * Size.y/2 + Offset.y + OffsetCopies.y *i;

        c = max(c, 1-pow(abs(pp.y / LineWidth), 1/Fade));
    }



    return float4(c,c,c,1);
}

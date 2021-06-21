cbuffer ParamConstants : register(b0)
{
    float SampleRadius;
    float Strength;
    float Contrast;
    // float2 Size;
    // float2 Position;
    // float Round;
    // float Feather;
    // float GradientBias;
    // float Rotate;
}

cbuffer Resolution : register(b1)
{
    float TargetWidth;
    float TargetHeight;
}

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

Texture2D<float4> Image : register(t0);
sampler texSampler : register(s0);



float sdBox( in float2 p, in float2 b )
{
    float2 d = abs(p)-b;
    return length(
        max(d,float2(0,0))) + min(max(d.x,d.y), 
        0.0);
}

float4 psMain(vsOutput input) : SV_TARGET
{
    float width, height;
    Image.GetDimensions(width, height);
    
    float sx = SampleRadius / width;
    float sy = SampleRadius / height;
    
    float x = input.texCoord.x;
    float y = input.texCoord.y;

    float4 y1= Image.Sample(texSampler, float2(input.texCoord.x,       input.texCoord.y + sy));
    float4 y2= Image.Sample(texSampler, float2(input.texCoord.x,       input.texCoord.y - sy));
    
    float4 x1= Image.Sample(texSampler,  float2(input.texCoord.x + sx, input.texCoord.y));
    float4 x2= Image.Sample(texSampler,  float2(input.texCoord.x - sx, input.texCoord.y)); 
    float4 m =  Image.Sample(texSampler, float2(input.texCoord.x,      input.texCoord.y)); 
    //return ((m-y1) + (m-y2) + (m-x1) + (m-x2)) * Strength;
    
    float average =  (           
                    abs(x1.r-m.r) + abs(x2.r-m.r) + abs(y1.r - m.r) +abs(y2.r - m.r) +
                    abs(x1.g-m.g) + abs(x2.g-m.g) + abs(y1.g - m.g) +abs(y2.g - m.g) +
                    abs(x1.b-m.b) + abs(x2.b-m.b) + abs(y1.b - m.b) +abs(y2.b - m.b)
                ) * Strength + Contrast;
                
    
    if(x<= sx*8 || x>= 1-sx*8 
    ||y<= sy*8 || y>= 1-sy*8) {
    average=0;
    }
    return  clamp(float4(average,average,average,1),0 , 10000);

    // float2 delta = float2(TestParam, TestParam);
    // float4 orgColor1 = Image.Sample(texSampler, psInput.texCoord + delta);
    // float4 orgColor2 = Image.Sample(texSampler, psInput.texCoord- delta);
    
    // return ( saturate (orgColor1 - orgColor2).rgb, 1);


    //return orgColor;


    // float aspectRatio = TargetWidth/TargetHeight;

    // float2 p = psInput.texCoord;
    // //p.x -= 0.5;
    // p -= 0.5;
    // p.x *= aspectRatio;

    // // Rotate
    // float imageRotationRad = (-Rotate - 90) / 180 *3.141578;     

    // float sina = sin(-imageRotationRad - 3.141578/2);
    // float cosa = cos(-imageRotationRad - 3.141578/2);

    // //p.x *=aspectRatio;

    // p = float2(
    //     cosa * p.x - sina * p.y,
    //     cosa * p.y + sina * p.x 
    // );

    // p-=Position * float2(1,-1);
    
    // float d = sdBox(p, Size/2);
    

    // d = smoothstep(Round/2 - Feather/4, Round/2 + Feather/4, d);

    // float dBiased = GradientBias>= 0 
    //     ? pow( d, GradientBias+1)
    //     : 1-pow( clamp(1-d,0,10), -GradientBias+1);

    // float4 c= lerp(Fill, Background,  dBiased);

    // float4 orgColor = Image.Sample(texSampler, psInput.texCoord);
    // //orgColor = float4(1,1,1,0);
    // float a = clamp(orgColor.a + c.a - orgColor.a*c.a, 0,1);

    // // FIXME: blend
    // //float mixA = a;
    // //float3 rgb = lerp(orgColor.rgb, c.rgb,  mixA);    
    // float3 rgb = (1.0 - c.a)*orgColor.rgb + c.a*c.rgb;   
    // return float4(rgb,a);
}
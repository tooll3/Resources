cbuffer ParamConstants : register(b0)
{
    float SampleRadius;
    float Displacement;
    float DisplaceOffset;
    float SampleCount;
    float ShiftX;
    float ShiftY;
    float Angle;
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
Texture2D<float4> ImageB : register(t1);
sampler texSampler : register(s0);


float IsBetween( float value, float low, float high) {
    return (value >= low && value <= high) ? 1:0;
}


float4 psMain(vsOutput psInput) : SV_TARGET
{    
    float width, height;
    ImageA.GetDimensions(width, height);
    float2 uv = psInput.texCoord;
    float2 uv2= uv+ float2(ShiftX, ShiftY);
    float4 ccc = ImageA.Sample(texSampler, uv);
   
    float sx = SampleRadius / width;
    float sy = SampleRadius / height;
    
    float4 cy1= ImageB.Sample(texSampler, float2(uv2.x,       uv2.y + sy));
    float4 cy2= ImageB.Sample(texSampler, float2(uv2.x,       uv2.y - sy));
    
    float4 cx1= ImageB.Sample(texSampler,  float2(uv2.x + sx, uv2.y));
    float4 cx2= ImageB.Sample(texSampler,  float2(uv2.x - sx, uv2.y)); 
    float4 c =  ImageB.Sample(texSampler, float2(uv2.x,      uv2.y)); 

    float cc= (c.r+ c.g +c.b);
    float x1= (cx1.r + cx1.g + cx1.b) / 3;
    float x2= (cx2.r + cx2.g + cx2.b) / 3;
    float y1= (cy1.r + cy1.g + cy1.b) / 3;
    float y2= (cy2.r + cy2.g + cy2.b) / 3;

    
    float2 d = float2( (x1-x2) , (y1-y2));
    float len = length(d);
    float a = length(d) ==0 ? 0 :  atan2(d.x, d.y) + Angle / 180 * 3.14158;

    float2 direction = float2( sin(a), cos(a));
    float2 p2 = direction * (Displacement * len + DisplaceOffset) * float2(height/ height, 1);
    
    
    float4 t1= float4(0,0,0,0);
    for(float i=-0.5; i< 0.5; i+= 1.0/ abs(SampleCount)) 
    {    
        t1+=ImageA.Sample(texSampler, uv + p2 * i); 
    }    

    //c.r=1;
    float4 c2=t1/SampleCount;
    c2.a = clamp( c2.a, 0.00001,1);
    //outputTexture[input.xy] = c2;
    return c2;
}
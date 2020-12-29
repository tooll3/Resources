//#include "hash-functions.hlsl"

cbuffer ParamConstants : register(b0)
{
    float Impacted;
    float Shade;
    float Twist;
    float SampleRadius;
    float2 Offset;
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

Texture2D<float4> Image : register(t0);
Texture2D<float4> DisplaceMap : register(t1);
sampler texSampler : register(s0);


float IsBetween( float value, float low, float high) {
    return (value >= low && value <= high) ? 1:0;
}


float4 psMain(vsOutput psInput) : SV_TARGET
{   
    float displaceMapWidth, displaceMapHeight;
    DisplaceMap.GetDimensions(displaceMapWidth, displaceMapHeight);

    float2 uv = psInput.texCoord;
    
    float sx = SampleRadius / (float)displaceMapWidth;
    float sy = SampleRadius / (float)displaceMapHeight;
    float4 cx1= DisplaceMap.Sample(texSampler,  float2(uv.x + sx, uv.y));
    float4 cx2= DisplaceMap.Sample(texSampler,  float2(uv.x - sx, uv.y)); 
    float4 cy1= DisplaceMap.Sample(texSampler, float2(uv.x,       uv.y + sy));
    float4 cy2= DisplaceMap.Sample(texSampler, float2(uv.x,       uv.y - sy));    

    float x1= (cx1.r + cx1.g + cx1.b) / 3;
    float x2= (cx2.r + cx2.g + cx2.b) / 3;
    float y1= (cy1.r + cy1.g + cy1.b) / 3;
    float y2= (cy2.r + cy2.g + cy2.b) / 3;

    float2 d = float2( (x1-x2) , (y1-y2));
    d+= Offset/10;

    float4 uvImage = DisplaceMap.Sample(texSampler, uv);
    //d = (uvImage.xy-0.5) * float2(1,-1);
    //d.x =0;
    //return float4(-d.xxx,1);

    //d = pow(1*d,3);
    //d= 1/d;
    //d=smoothstep(0,1,d);
    float angle = (d.x == 0 && d.y==0) ? 0 :  atan2(d.x, d.y) + Twist / 180 * 3.14158;
    //return float4((d * Impacted+0.5),0.5,1);

    float2 direction = float2( sin(angle), cos(angle));

    //float distanceFromCenter = length(uv- float2(-2,1));
    float len = length(d); //1 * pow(distanceFromCenter,DirectionImpact);
    float4 cc= Image.Sample(texSampler, -direction * len * 10* Impacted + 0.5);
    
    //float4 cc= Image.Sample(texSampler, d.xy * Impacted +0.5 );

    //return float4(distanceFromCenter, 0,0,1);
    //return float4(uvImage.bbb,1);

    //cc.rgb *= 1-len*Shade*100 * (Shade/5) * (uvImage.r + uvImage.g + uvImage.b)/3;
    cc.rgb = lerp(uvImage.rgb, uvImage.rgb+cc.rbg - 0.5, Shade );

    ///return clamp(cc, 0, float4(10,10,10,uvImage.a));
    cc.a *= uvImage.a;
    return float4( clamp(cc, float4(0,0,0,0) , float4(100,100,100,1)));
}
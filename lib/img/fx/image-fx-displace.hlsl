cbuffer ParamConstants : register(b0)
{
    float SampleRadius;
    float DisplaceAmount;
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
    int samples = (int)clamp(SampleCount+0.5,1,32);
    float displaceMapWidth, displaceMapHeight;
    DisplaceMap.GetDimensions(displaceMapWidth, displaceMapHeight);
    float2 uv = psInput.texCoord;
    float2 dispMapUv= uv+ float2(ShiftX, ShiftY);
    float4 ccc = Image.Sample(texSampler, uv);
   
    float sx = SampleRadius / displaceMapWidth;
    float sy = SampleRadius / displaceMapHeight;
    
    float4 cy1a= DisplaceMap.Sample(texSampler, float2(dispMapUv.x,       dispMapUv.y + sy));
    float4 cy2a= DisplaceMap.Sample(texSampler, float2(dispMapUv.x,       dispMapUv.y - sy));    
    float4 cx1a= DisplaceMap.Sample(texSampler,  float2(dispMapUv.x + sx, dispMapUv.y));
    float4 cx2a= DisplaceMap.Sample(texSampler,  float2(dispMapUv.x - sx, dispMapUv.y)); 

    // float g=0;
    // float4 cy1b= DisplaceMap.Sample(texSampler, float2(dispMapUv.x,       dispMapUv.y + g*sy));
    // float4 cy2b= DisplaceMap.Sample(texSampler, float2(dispMapUv.x,       dispMapUv.y - g*sy));    
    // float4 cx1b= DisplaceMap.Sample(texSampler,  float2(dispMapUv.x + g*sx, dispMapUv.y));
    // float4 cx2b= DisplaceMap.Sample(texSampler,  float2(dispMapUv.x - g*sx, dispMapUv.y)); 

    // float4 c =  DisplaceMap.Sample(texSampler, float2(dispMapUv.x,      dispMapUv.y)); 

    //float cc= (c.r+ c.g +c.b)/3;
    float x1= (cx1a.r + cx1a.g + cx1a.b) / 3;
    float x2= (cx2a.r + cx2a.g + cx2a.b) / 3;
    float y1= (cy1a.r + cy1a.g + cy1a.b) / 3;
    float y2= (cy2a.r + cy2a.g + cy2a.b) / 3;

    float2 d = float2( (x1-x2) , (y1-y2));
    //return float4(d*100,0,1);
    // float2 d2 = float2(
    //      -((cc-x1) + (x2-cc)),
    //      -((cc-y1) + (y2-cc)));

    
    // if( abs(uv.x - beatTime*0.1%1) < 0.001)
    //     return float4(0,0,0,0.1);
    // float2 d = uv.x < beatTime*.1%1 ? d1:d2;
    float len = -length(d);
    float a = (d.x == 0 && d.y==0) ? 0 :  atan2(d.x, d.y) + Angle / 180 * 3.14158;

    // Image -----

    float2 direction = float2( sin(a), cos(a));
    float2 p2 = direction * (DisplaceAmount * len * 10 + DisplaceOffset);// * float2(height/ height, 1);
    float imgAspect = TargetWidth/TargetHeight;
    p2.x /=imgAspect;
    
    
    float4 t1= float4(0,0,0,0);
    //for(float i=1; i> 0; i-= 1.0001/ samples) 
    for(float i=-0.5; i< 0.5; i+= 1.0001/ samples) 
    {    
        t1+=Image.Sample(texSampler, uv + p2 * i); 
    }    

    // for(float i=1; i> 0; i-= 1.0001/ samples) 
    // {    
    //     t1+=Image.Sample(texSampler, uv + p2 * i/-2); 
    // }    


    //c.r=1;
    float4 c2=t1/samples;
    c2.a = clamp( c2.a, 0.00001,1);
    //outputTexture[input.xy] = c2;
    return c2;
}
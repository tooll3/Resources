cbuffer ParamConstants : register(b0)
{
    float RotateMirror;
    float RotateImage;
    float Width;
    float Offset;
    
    float2 OffsetImage;
    float __dummy__;
    float ShadeAmount;
    float4 ShadeColor;
    float2 Center;
}

cbuffer TimeConstants : register(b1)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

cbuffer TimeConstants : register(b2)
{
    float TargetWidth;
    float TargetHeight;
}

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

Texture2D<float4> ImageA : register(t0);
sampler texSampler : register(s0);

float mod(float x, float y) {
    return (x - y * floor(x / y));
} 

float4 psMain(vsOutput psInput) : SV_TARGET
{   

    float imageRotationRad = (-RotateImage - 90) / 180 *3.141578;
     
    float aspectRatio = TargetWidth/TargetHeight;
    float2 p = psInput.texCoord;
    p.x *= aspectRatio;

    p-= float2(0.5 * aspectRatio, 0.5);



    float sina = sin(-imageRotationRad - 3.141578/2);
    float cosa = cos(-imageRotationRad - 3.141578/2);

    p = float2(
        cosa * p.x - sina * p.y,
        cosa * p.y + sina * p.x 
    );


    float mirrorRotationRad = (-RotateMirror - RotateImage - 90) / 180 *3.141578;

    // Show Center
    // if( length(p - Center) < 0.01) {
    //     return float4(1,1,0,1);
    // }

    float2 angle =  float2(sin(mirrorRotationRad),cos(mirrorRotationRad));

    float dist=  dot(p-Center, angle); 
    float offset = Offset %1;
    dist += offset;
    float shade = 0;

    float d=0;
    float mDist = dist % (2*Width);
    if(dist > Width) 
    {        
        if(mDist > Width) {
            shade =1;
            d= -2*(mDist -Width);
        }
    }
    else if( dist <0) 
    {
        mDist *= -1;
        if(mDist < Width) {
            shade = 1;
        }
        else {
            d= -2*(mDist -Width);
        }
    }
    d-= dist - mDist;
    d+= offset;
    p+= d * angle;


    p+= OffsetImage;



    p += float2(0.5 / aspectRatio, 0.5);
    p.x *= aspectRatio;

    //float line2= smoothstep(1,0, abs(1-dist)*1000*Width-LineThickness+1);   
    //colorEffect = lerp(colorEffect, LineColor, line2);


    float4 texColor= ImageA.Sample(texSampler, p);
    float4 color = lerp( texColor, ShadeColor, shade * ShadeAmount);
    //color.rgb *= shade;
    color = clamp(color, float4(0,0,0,0), float4(100,100,100,1));
    return color;






    // Reference implementation for soft edge
    // (didn't look too convincing...)
    //
    //float softEdge=0;
    // if(dist > Width) 
    // {
    //     float mDist = dist % (2*Width);
    //     if(mDist < Width) {
    //         softEdge= 1-saturate(mDist / Width* PingPong);
    //         softEdge = softEdge * softEdge * softEdge;            
    //     }
    //     else {
    //         softEdge= (1-saturate((1-( mDist - Width) / Width)*PingPong));
    //         softEdge = softEdge * softEdge *  softEdge;
    //         shade =1;
    //         d= -2*(mDist -Width);
    //         //d-= softEdge  * LineThickness;
    //     }
    //     d+= softEdge * (Width/ PingPong/3 );
    //     d-= dist - mDist;
    //     p+= d * angle;
    // }









}
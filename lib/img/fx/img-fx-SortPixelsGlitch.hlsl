Texture2D<float4> inputTexture : register(t0);
sampler texSampler : register(s0);

cbuffer ParamConstants : register(b0)
{
    float Range;
    float Threshold;
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



float4 psMain(vsOutput psInput) : SV_TARGET
{
    float2 uv = psInput.texCoord;

    int steps = (int)clamp(Range,1,600);

    float2 direction = 1/ float2(TargetWidth, TargetHeight);
    direction.y=0;

/*
    float4 colorAtPix = inputTexture.SampleLevel(texSampler, uv, 0.0);
    float4 minColor = colorAtPix;
    float colorAtPixSum = colorAtPix.r + colorAtPix.g + colorAtPix.b;
    float minColorSum = colorAtPixSum;
    float minColorStep =0;
    float4 c;
    float sum;

    for(int i = 1; i<= steps; i++) 
    {
        c = inputTexture.SampleLevel(texSampler, uv + direction * i, 0.0);
        
        sum = c.r + c.g + c.b;
        //if(sum > colorAtPixSum)
        //    break;

        if(sum < minColorSum) {
            minColorSum = sum;
            minColor = c; 
            minColorStep = i;           
        }
    }
    float f =  minColorStep / Range ;


    return lerp(minColor, colorAtPix,f);
    return minColor;
*/

    float maxColorStep=0;
    float minColorStep=0;
    float maxColorSum = -1;
    float minColorSum = 999;
    float4 minColor = float4(0,0,0,1);
    float4 maxColor =1;
    
    //float4 c;
    float sum = 0;
    float4 orgC = inputTexture.SampleLevel(texSampler, uv, 0.0);
    float orgSum = orgC.r + orgC.g + orgC.b;

    float4 sumColorLeft = 0;
    float4 leftColor=orgC;
    float4 c;
    for(int leftSteps = 1; leftSteps< steps; leftSteps++) 
    {
        c = inputTexture.SampleLevel(texSampler, uv - direction * leftSteps, 0.0);
        sum = c.r + c.g + c.b;
        if(abs(sum -orgSum)  > Threshold)  {
        //if(sum > orgSum  + Threshold)  {
            
            leftColor=c;
            break;
        }
        sumColorLeft += c;
    }
    if(leftSteps == steps) {
        
        sumColorLeft /= leftSteps;
        leftColor = sumColorLeft;
    }

    float4 sumColorRight = 0;
    float4 rightColor=orgC;
    for(int rightSteps = 1; rightSteps< steps; rightSteps++) 
    {
        c = inputTexture.SampleLevel(texSampler, uv + direction * rightSteps, 0.0);
        sum = c.r + c.g + c.b;
        if( abs(sum - orgSum) >  Threshold)  
        //if( sum  <  orgSum - Threshold)  
        {
            
            c=rightColor;            
            break;
        }
        sumColorRight += rightColor;
    }
    if(rightSteps == steps) 
    {
        sumColorRight /= rightSteps;
        rightColor = sumColorRight;
    }
    
    //return maxColor;
    float f = leftSteps*1./(leftSteps + rightSteps);
    float center = (leftSteps + rightSteps * 1.)/2.;
    float distanceFromCenter = abs(center-f)/5.;
    //return float4(distanceFromCenter/30.,0,0,1);
    // return float4(
    //     leftSteps/100. * 0, 
    //     rightSteps/100. * 0, 
    //     f * 1,
    //     1);

    //return float4(f,0,0,1);
    if(f < 0.5) {
        return lerp( rightColor, orgC, f*2);    
    }
    else {
        return lerp( orgC, leftColor,  f*2-1);    
    }
    

    //maxColor= max(maxColor,inputTexture.SampleLevel(texSampler, uv,0) );

    float test = minColorStep/Range;
    
    //return float4(0, 0 ,test2 ,1);


    //return c;


    // float a2 = clamp(Background.a + c.a - Background.a*c.a, 0,1);
    // float3 rgb2 = clamp((1.0 - c.a)*Background.rgb + c.a*c.rgb, 0.00001, 100);   
    // return float4(rgb2, a2);
}

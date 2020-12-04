#include "hash-functions.hlsl"

Texture2D<float4> inputTexture : register(t0);
sampler texSampler : register(s0);

cbuffer ParamConstants : register(b0)
{
    float Threshold;
    float MaxSteps;
    float Range;
    float Increment;
    float RandomSeed;
    float RandomAmount;
    float DoCalculateStep;
    float BlendLastStepFactor;

}

cbuffer Resolution : register(b1)
{
    float TargetWidth;
    float TargetHeight;
}


cbuffer TimeConstants : register(b2)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

struct Pixel {
    float4 Color;
};

RWStructuredBuffer<Pixel> ReadPoints : u0; 
RWStructuredBuffer<Pixel> WritePoints : u1; 
RWTexture2D<float4> WriteOutput  : register(u2); 
//RWTexture2D<float4> outputTexture : register(u0);
static int _maxRangeSteps;
static int2 _centerPos;
static int2 _screenSize;
static int _maxSteps;
static int _threshold;


int GetCCAMatches(int2 direction, int tc) 
{
    int sum = 0;
    int2 pos = _centerPos;
    for(int step=0; step < _maxRangeSteps; step++) 
    {
        pos += direction;
        pos = fmod(pos,_screenSize);
        float4 neighbourColor = WritePoints[pos.x + pos.y *TargetWidth].Color;
        int t = (int)(neighbourColor.r + 0.1) % _maxSteps;
        //bool matchesIncrement = abs(((neighbourColor.r +1) % (int)MaxSteps) - value.r ) < 0.1;
        sum+= (abs(tc - t) == 1) ? 1:0;    
    } 
    return sum;
}

static const int2 Directions[] = 
{
  int2( -1,  0),
  int2( -1, +1),
  int2(  0, +1),
  int2( +1, +1),
  int2( +1,  0),
  int2( +1, -1),
  int2(  0, -1),
  int2( -1, -1),
};

static const int2 Directions2[] = 
{
  int2( -1,  0),
  int2( +1,  0),
  int2(  0, -1),
  int2(  0, +1),
};


[numthreads(16,16,1)]
void main(uint3 i : SV_DispatchThreadID)
{         
    //int index = i.x;

    _screenSize = int2(TargetWidth, TargetHeight);
    _centerPos = i.xy;//int2(index % TargetWidth, index / TargetWidth);
    float2 uv = _centerPos / (float2)_screenSize;
    _maxSteps = (int)(MaxSteps + 0.5) +  (int)(uv.x * 6);
    _threshold = (int)(Threshold + 0.5);// +  (int)(uv.y * 4);
    
    float4 c = ReadPoints[i.x].Color;    

    
    if(RandomAmount>0 ) 
    {
        bool isInitialized = c.a > 0.5;

        float hash = hash12( uv * 431 + 111 + RandomSeed);
        bool shouldFill = hash < RandomAmount;
        
        if(shouldFill || !isInitialized) 
        {
            c = float4((int)(hash * _maxSteps),0,0,1);
            WritePoints[i.x + i.y * TargetWidth].Color = c;
            ReadPoints[i.x + i.y * TargetWidth].Color = c;
        }
    }

    if(DoCalculateStep) 
    {
        int rangeOffset = (int)(uv.y * 4);
        _maxRangeSteps = clamp(Range + rangeOffset, 1,100);

        int tc= (int)(c.r + 0.1);

        int sum =0;
        for(int directionIndex = 0; directionIndex < 8; directionIndex ++)
        {
            int2 direction = Directions[directionIndex];
            //sum+=GetCCAMatches(Directions[directionIndex],tc);            
            int2 pos = _centerPos;
            for(int step=0; step < _maxRangeSteps; step++) 
            {
                pos += direction;
                //pos = fmod(pos,_screenSize);
                float4 neighbourColor = ReadPoints[pos.x + pos.y *TargetWidth].Color;
                int t = (int)(neighbourColor.r + 0.1) % _maxSteps;
                //bool matchesIncrement = abs(((neighbourColor.r +1) % (int)MaxSteps) - value.r ) < 0.1;
                sum+= (abs(tc - t) == 1) ? 1:0;    
            } 
        }

        // int sum = GetCCAMatches(int2(-1, 0),tc)
        //         + GetCCAMatches(int2( 0, 1),tc)
        //         + GetCCAMatches(int2( 1, 0),tc)
        //         + GetCCAMatches(int2( 0,-1),tc);


        c.g = c.r;  // keep last step in green channel
        if(sum >= _threshold) 
        {            
            c.r++;
            //c.r=0;
            //c.b = sum * 1 + 0.1 ;

        }
        if(c.r >= _maxSteps) 
        {
            c.r =0;
        }
        c.r += 0;

        //c.b = lerp(c.g, c.r, BlendLastStepFactor) / MaxSteps;
        //c.b = sum + 0.5;
    }
    //c.b=1;
    //c.b = lerp(c.g, c.r, BlendLastStepFactor) / _maxSteps;    
    WritePoints[i.x + i.y * TargetWidth].Color = c;// float4(Threshold, 0,0,1);
    //ReadPoints[i.x].Color = float4(0, 1,0,1);
    WriteOutput[i.xy] = c;// * float4(1,0,0,1); 
}

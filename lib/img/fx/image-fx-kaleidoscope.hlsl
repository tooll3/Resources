cbuffer ParamConstants : register(b0)
{
    float Param1;
}

cbuffer TimeConstants : register(b1)
{
    float globalTime;
    float time;
    float iTime;
    float beatTime;
}

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

Texture2D<float4> inputTexture : register(t0);
sampler texSampler : register(s0);


float IsBetween( float value, float low, float high) {
    return (value >= low && value <= high) ? 1:0;
}




//===================
// https://www.shadertoy.com/view/XslGz7

static int numPoints = 3;
//bool showFolds = true;

struct Ray
{
	float2 Origin;
	float2 Direction;
};

float rand( float2 n ) {
	return frac(sin(dot(n.xy, float2(12.9898, 78.233)))* 43758.5453);
}


float noise(float2 n) {
	float2 d = float2(0.0, 1.0);
	float2 b = floor(n), f = smoothstep(float2(0,0 ), float2(1,1), frac(n));
	return lerp(lerp(rand(b), rand(b + d.yx), f.x), lerp(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float2 noise2(float2 n)
{
	return float2(
        noise(float2(n.x+0.2, n.y-0.6)), 
        noise(float2(n.y+3., n.x-4.))
    );
}

Ray GetRay(float i)
{
	Ray ray;
    ray.Origin = noise2(float2(i*6.12+iTime*0.1, i*4.43+iTime*0.1));
    ray.Direction = normalize(noise2(float2(i*7 + iTime*0.05, i*6))*2-1);		
    return ray;	
}


float4 psMain(vsOutput input) : SV_TARGET
{
	float2 curPos = input.texCoord;
	bool showFolds = true;
    
	for(int i=0; i < numPoints; i++)
	{
		Ray ray=GetRay(float(i+1) * 3 );	

		if(showFolds && length(ray.Origin-curPos)<0.01)
		{
			return float4(1,1,1,1);
		}

		if (showFolds && length(curPos-(ray.Origin+ray.Direction*0.1))<0.01)
		{
			return  float4(1,0,0,1);
		}

        float offset=dot(curPos-ray.Origin, ray.Direction);

        if(showFolds && abs(offset)<0.001)
        {
            return  float4(0,0,1,1);
        }

        if(offset < 0)
        {
            curPos -= ray.Direction * offset * 2;
        }									
		
	}


    float4 c = inputTexture.Sample(texSampler, curPos);
    return c;
}

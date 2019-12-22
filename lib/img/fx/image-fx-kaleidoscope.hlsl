cbuffer ParamConstants : register(b0)
{
    float Scale;
    float CenterX;
    float CenterY;

    float OffsetX;
    float OffsetY;

    float Angle;    // <--- not working?
    float AngleOffset;
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

static int numPoints = 4;
static float PI = 3.141578;
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

Ray GetRay2(float i)
{
	Ray ray;
    ray.Origin =float2(CenterX + OffsetX *i, CenterY + OffsetY *i);

    float angle= Angle * 3.141578 / 180 + AngleOffset * 3.141578 / 180 * i;
    ray.Direction = float2(
            sin(angle), 
            cos(angle)
        )*1;
    return ray;	
}


float fmod(float x, float y)
{
  return x - y * floor(x/y);
}

float4 psMain2(vsOutput input) : SV_TARGET
{
	float2 curPos = input.texCoord;
	bool showFolds = true;
    float foldCount =0;
	for(int i=0; i < numPoints; i++)
	{
		Ray ray=GetRay(float(i+1));	

		if(showFolds && length(ray.Origin-curPos)<0.01 * (i+1))
		{
			return float4(1,1,1,1);
		}

		if (showFolds && length(curPos-(ray.Origin+ray.Direction*0.1))<0.01 * (i+1))
		{
			return  float4(1,0,0,1);
		}

        float offset=dot(curPos-ray.Origin, ray.Direction);

        if(showFolds && abs(offset)<0.001)
        {
            return  float4(0,0,1,1);
        }

        if( offset > 0)
        {
            curPos -= ray.Direction * offset * 2;
            foldCount++;
        }									
		
	}


    float4 c = inputTexture.Sample(texSampler, curPos);
    c.r = foldCount *0.3;
    return c;
}


float2 Fold(float2 p, float ang)
{
    float2 n= float2(cos(-ang),sin(-ang));
    p-=2 * min(0.,dot(p,n))*n;
    return p;    
}

float2 KochFold(float2 pt) {

    // Fold horizontally
    pt.x = abs(pt.x);
    pt.x-=.5;
    //Fold across PI/6
    pt = Fold(pt,PI/6.);
    return pt;
}

float2 KochCurve(float2 pt) {
    //Fold and scale a few times
    for(int i=0;i<2;i++){
        pt*=3.;
        pt.x-=1.5;
        pt=KochFold(pt);
    }
    return pt;
}

float4 psMain(vsOutput input) : SV_TARGET
{	
    float2 pt = input.texCoord;
    pt.y-=CenterY;
    pt.x-=CenterX;
    
    pt/=Scale;
    pt = Fold(pt,-2.*PI/3.);

    pt.x += 1.;
    pt = Fold(pt,-PI/3.);
    pt= KochCurve(pt);


    float4 c = inputTexture.Sample(texSampler, pt);
    c.rgb+= abs(pt.y) < 0.05;
    return c;
}

// by CandyCat https://www.shadertoy.com/view/4sc3z2

//#define Use_Perlin
//#define Use_Value
#define Use_Simplex


cbuffer ParamConstants : register(b0)
{
    float Scale;
    float CenterX;
    float CenterY;

    float OffsetX;
    float OffsetY;

    float Angle;
    float AngleOffset;
    float Steps;
    float Fade;
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

Texture2D<float4> inputTexture : register(t0);
sampler texSampler : register(s0);


float IsBetween( float value, float low, float high) {
    return (value >= low && value <= high) ? 1:0;
}



// ========= Hash ===========

float3 hashOld33(float3 p)
{   
	p = float3( dot(p,float3(127.1,311.7, 74.7)),
			  dot(p,float3(269.5,183.3,246.1)),
			  dot(p,float3(113.5,271.9,124.6)));
    
    return -1.0 + 2.0 * frac(sin(p)*43758.5453123);
}

float hashOld31(float3 p)
{
    float h = dot(p,float3(127.1,311.7, 74.7));
    
    return -1.0 + 2.0 * frac(sin(h)*43758.5453123);
}

// Grab from https://www.shadertoy.com/view/4djSRW
#define MOD3 float3(.1031,.11369,.13787)
//#define MOD3 float3(443.8975,397.2973, 491.1871)
float hash31(float3 p3) 
{
	p3  = frac(p3 * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return -1.0 + 2.0 * frac((p3.x + p3.y) * p3.z);
}

float3 hash33(float3 p3)
{
	p3 = frac(p3 * MOD3);
    p3 += dot(p3, p3.yxz+19.19);
    return -1.0 + 2.0 * frac(float3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

// ========= Noise ===========

float value_noise(float3 p)
{
    float3 pi = floor(p);
    float3 pf = p - pi;
    
    float3 w = pf * pf * (3.0 - 2.0 * pf);
    
    return 	lerp(
        		lerp(
        			lerp(hash31(pi + float3(0, 0, 0)), hash31(pi + float3(1, 0, 0)), w.x),
        			lerp(hash31(pi + float3(0, 0, 1)), hash31(pi + float3(1, 0, 1)), w.x), 
                    w.z),
        		lerp(
                    lerp(hash31(pi + float3(0, 1, 0)), hash31(pi + float3(1, 1, 0)), w.x),
        			lerp(hash31(pi + float3(0, 1, 1)), hash31(pi + float3(1, 1, 1)), w.x), 
                    w.z),
        		w.y);
}

float perlin_noise(float3 p)
{
    float3 pi = floor(p);
    float3 pf = p - pi;
    
    float3 w = pf * pf * (3.0 - 2.0 * pf);
    
    return 	lerp(
        		lerp(
                	lerp(dot(pf - float3(0, 0, 0), hash33(pi + float3(0, 0, 0))), 
                        dot(pf - float3(1, 0, 0), hash33(pi + float3(1, 0, 0))),
                       	w.x),
                	lerp(dot(pf - float3(0, 0, 1), hash33(pi + float3(0, 0, 1))), 
                        dot(pf - float3(1, 0, 1), hash33(pi + float3(1, 0, 1))),
                       	w.x),
                	w.z),
        		lerp(
                    lerp(dot(pf - float3(0, 1, 0), hash33(pi + float3(0, 1, 0))), 
                        dot(pf - float3(1, 1, 0), hash33(pi + float3(1, 1, 0))),
                       	w.x),
                   	lerp(dot(pf - float3(0, 1, 1), hash33(pi + float3(0, 1, 1))), 
                        dot(pf - float3(1, 1, 1), hash33(pi + float3(1, 1, 1))),
                       	w.x),
                	w.z),
    			w.y);
}

float simplex_noise(float3 p)
{
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;
    
    float3 i = floor(p + (p.x + p.y + p.z) * K1);
    float3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    
    // thx nikita: https://www.shadertoy.com/view/XsX3zB
    float3 e = step(float3(0,0,0), d0 - d0.yzx);
	float3 i1 = e * (1.0 - e.zxy,1.0 - e.zxy,1.0 - e.zxy);
	float3 i2 = 1.0 - e.zxy * (1.0 - e);
    
    float3 d1 = d0 - (i1 - 1.0 * K2);
    float3 d2 = d0 - (i2 - 2.0 * K2);
    float3 d3 = d0 - (1.0 - 3.0 * K2);
    
    float4 h = max(0.6 - float4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    float4 n = h * h * h * h * float4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));
    
    return dot(float4(31.316, 31.316, 31.316, 31.316), n);
}

float noise(float3 p) {
#ifdef Use_Perlin
    return perlin_noise(p * 2.0);
#elif defined Use_Value
    return value_noise(p * 2.0);
#elif defined Use_Simplex
    return simplex_noise(p);
#endif
    
    return 0.0;
}

// ========== Different function ==========

float noise_itself(float3 p)
{
    return noise(p * 8.0);
}

float noise_sum(float3 p)
{
    float f = 0.0;
    p = p * 4.0;
    f += 1.0000 * noise(p); p = 2.0 * p;
    f += 0.5000 * noise(p); p = 2.0 * p;
	f += 0.2500 * noise(p); p = 2.0 * p;
	f += 0.1250 * noise(p); p = 2.0 * p;
	f += 0.0625 * noise(p); p = 2.0 * p;
    
    return f;
}

float noise_sum_abs(float3 p)
{
    float f = 0.0;
    p = p * 3.0;
    f += 1.0000 * abs(noise(p)); p = 2.0 * p;
    f += 0.5000 * abs(noise(p)); p = 2.0 * p;
	f += 0.2500 * abs(noise(p)); p = 2.0 * p;
	f += 0.1250 * abs(noise(p)); p = 2.0 * p;
	f += 0.0625 * abs(noise(p)); p = 2.0 * p;
    
    return f;
}

float noise_sum_abs_sin(float3 p)
{
    float f = noise_sum_abs(p);
    f = sin(f * 2.5 + p.x * 5.0 - 1.5);
    
    return f ;
}


// ========== Draw ==========

float3 draw_simple(float f)
{
    f = f * 0.5 + 0.5;
    return f * float3(25.0/255.0, 161.0/255.0, 245.0/255.0);
}

float3 draw_cloud(float f)
{
    f = f * 0.5 + 0.5;
    return lerp(	float3(8.0/255.0, 65.0/255.0, 82.0/255.0),
              	float3(178.0/255.0, 161.0/255.0, 205.0/255.0),
               	f*f);
}

float3 draw_fire(float f)
{
    f = f * 0.5 + 0.5;
    return lerp(	float3(131.0/255.0, 8.0/255.0, 0.0/255.0),
              	float3(204.0/255.0, 194.0/255.0, 56.0/255.0),
               	pow(f, 3.));
}

float3 draw_marble(float f)
{
    f = f * 0.5 + 0.5;
    return lerp(	float3(31.0/255.0, 14.0/255.0, 4.0/255.0),
              	float3(172.0/255.0, 153.0/255.0, 138.0/255.0),
               	1.0 - pow(f, 3.));
}

float3 draw_circle_outline(float2 p, float radius, float3 col)
{
    p = 2.0 * p - float2(1, 1.0); 
    return 	lerp(float3(0,0,0), col, smoothstep(0.0, 0.02, abs(length(p) - radius)));
        	
}

// ========= Marching ===========
#define FAR 30.0
#define PRECISE 0.001
#define SPEED 0.05

float map(float3 pos)
{
    return length(pos - (float3(0.0, 0.0, 1.5) + runTime * float3(0.0, 0.0, SPEED))) - 1.0;
}

float3 normal(float3 pos) {
    float2 eps = float2(0.001, 0.0);
    return normalize(float3(	map(pos + eps.xyy) - map(pos - eps.xyy),
                    		map(pos + eps.yxy) - map(pos - eps.yxy),
                         	map(pos + eps.yyx) - map(pos - eps.yyx)));
}

float3 getBackground(float2 uv, float2 split)
{
    float3 pos = float3(uv * float2(1.0, 1.0), runTime * SPEED);
    float f;
    if (uv.x < split.x && uv.y > split.y) {
        f = noise_itself(pos);
    } else if (uv.x < split.x && uv.y <= split.y) {
        f = noise_sum(pos);
    } else if (uv.x >= split.x && uv.y < split.y) {
        f = noise_sum_abs(pos);
    } else {
        f = noise_sum_abs_sin(pos);
    }
    
    float fMapped = f * 0.5 + 0.5;
    return float3(fMapped,fMapped,fMapped); 
}

float3 getColor(float2 uv, float3 pos, float3 rd, float2 split)
{
    float3 nor = normal(pos);
    float3 light = normalize(float3(0.5, 1.0, -0.2));
        
    float diff = dot(light, nor);
    diff = diff * 0.5 + 0.5;
    
    float3 col;
    float f;
    if (uv.x < split.x && uv.y > split.y) {
        f = noise_itself(pos);
        col = draw_simple(f);
    } else if (uv.x < split.x && uv.y <= split.y) {
        f = noise_sum(pos);
        col = draw_cloud(f);
    } else if (uv.x >= split.x && uv.y < split.y) {
        f = noise_sum_abs(pos);
        col = draw_fire(f);
    } else {
        f = noise_sum_abs_sin(pos);
        col = draw_marble(f);
    }
    
    float3 edge = col * pow((1.0 - clamp(dot(nor, -rd), 0.0, 1.0)), 5.0);
    
    return col + edge;
}

float3 marching(float3 ro, float3 rd, float2 uv, float2 split)
{
    float t = 0.0;
    float d = 1.0;
    float3 pos;
    for (int i = 0; i < 50; i++) {
        pos = ro + rd * t;
        d = map(pos);
        t += d;
        if (d < PRECISE || t > FAR) break;
    }
 
    float3 col = getBackground(uv, split);
    
    if (t < FAR) {
        pos = ro + rd * t;
        col = getColor(uv, pos, rd, split);
    }
    
    return col;
}

//void mainImage( out float4 fragColor, in float2 fragCoord )
//{

float4 psMain(vsOutput psInput) : SV_TARGET
{    
	float2 p = psInput.texCoord; //fragCoord.xy / iResolution.xy;
    float2 split = float2(0.5, 0.5);
    // if (iMouse.z > 0.0) {
    //     split += 2.0 * iMouse.xy/iResolution.xy - 1.0;
    // }
    
    float3 col = float3(0.0, 0.0, 0.0);
    
    float3 ro = float3(0.0, 0.0, 0.0) + runTime * float3(0.0, 0.0, SPEED);
    float3 rd = float3((p * 2.0 - 1.0) * float2(1.0, 1.0), 1.0);
    col = marching(ro, rd, p, split);
	
    col = draw_circle_outline(p * float2(1.0, 1.0), 0.9, col);
    col = lerp(float3(0.3, 0.0, 0.0), col, smoothstep(0.0, 0.005, abs(p.x - split.x)));
    col = lerp(float3(0.3, 0.0, 0.0), col, smoothstep(0.0, 0.005*1.0, abs(p.y - split.y)));
    
    return float4(col, 1.0);

}
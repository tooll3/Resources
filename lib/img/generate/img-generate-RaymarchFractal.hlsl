cbuffer ParamConstants : register (b0)
{
    float4 Fill;
    // float4 Background;
    float2 Size;
    float2 Position;
    float Round;
    float Feather;
    float GradientBias;

    float Minrad;
    float Scale;
    float3 Clamping;
    float2 Fold;
    float3 Increment;
    float MaxSteps;
    float StepSize;
    float MinDistance;
    float MaxDistance;
    float DistToColor;
    float4 Surface1;
    float4 Surface2;
    float4 Surface3;
    float4 Diffuse;
    float4 Specular;
    float2 Spec;
    float4 Glow;
    float4 AmbientOcclusion;
    float AODistance;
    float4 Background;
    float Fog;
    float3 LightPos;
    float3 SpherePos;
    float SphereRadius;
}

cbuffer TimeConstants : register (b1)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

cbuffer Transforms : register (b0)
{
    float4x4 clipSpaceTcamera;
    float4x4 cameraTclipSpace;
    float4x4 cameraTworld;
    float4x4 worldTcamera;
    float4x4 clipSpaceTworld;
    float4x4 worldTclipSpace;
    float4x4 worldTobject;
    float4x4 objectTworld;
    float4x4 cameraTobject;
    float4x4 clipSpaceTobject;
};

//>>> _common parameters
float4x4 objectToWorldMatrix;
float4x4 worldToCameraMatrix;
float4x4 projMatrix;
Texture2D txDiffuse;
float2 RenderTargetSize;
//<<< _common parameters

float4x4 ViewToWorld;

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

Texture2D<float4> ImageA : register (t0);
sampler texSampler : register (s0);

#define mod (x, y) (x - y * floor (x / y))

float sdBox (in float2 p, in float2 b)
{
    float2 d = abs (p) - b;
    return length (
        max (d, float2 (0, 0))) + min (max (d.x, d.y),
        0.0);
}

float4 psMain (vsOutput psInput) : SV_TARGET
{
    return float4 (1, 1, 0, 1);
}

//>>> setup
SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
//<<< setup

//>>> declarations
struct VS_IN
{
    float4 pos : POSITION;
    float2 texCoord : TEXCOORD;
};

struct PS_IN
{
    float4 pos : SV_POSITION;
    float2 texCoord : TEXCOORD0;
    float3 worldTViewPos : TEXCOORD1;
    float3 worldTViewDir : TEXCOORD2;
};
//<<< declarations


PS_IN VS (VS_IN input)
{
    PS_IN output = (PS_IN) 0;
    input.pos = mul (input.pos, objectToWorldMatrix);
    output.pos = mul (input.pos, worldToCameraMatrix);
    output.pos = mul (output.pos, projMatrix);
    output.texCoord = input.texCoord;

    float4 viewTNearFragPos = float4 (input.texCoord.x * 2.0 - 1.0, -input.texCoord.y * 2.0 + 1.0, 0.0, 1.0);
    float4 worldTNearFragPos = mul (viewTNearFragPos, ViewToWorld);
    worldTNearFragPos /= worldTNearFragPos.w;

    float4 viewTFarFragPos = float4 (input.texCoord.x * 2.0 - 1.0, -input.texCoord.y * 2.0 + 1.0, 1.0, 1.0);
    float4 worldTFarFragPos = mul (viewTFarFragPos, ViewToWorld);
    worldTFarFragPos /= worldTFarFragPos.w;

    output.worldTViewDir = normalize (worldTFarFragPos.xyz - worldTNearFragPos.xyz);

    output.worldTViewPos = worldTNearFragPos;
    return output;
}


float sphereD (float3 p0)
{
    return length (p0 + float4 (SpherePos.xyz, 1)) - SphereRadius;
}


float BOX_RADIUS = 0.005;
float dBox (float3 p, float3 b)
{
    return length (max (abs (p) - b + float3 (BOX_RADIUS, BOX_RADIUS, BOX_RADIUS), 0.0)) - BOX_RADIUS;
}


int mandelBoxIterations = 4;

float dMandelbox (float3 pos)
{
    float4 pN = float4 (pos, 1);
    //return dStillLogo(pN);

    // precomputed constants
    float minRad2 = clamp (Minrad, 1.0e-9, 1.0);
    float4 scale = float4 (Scale, Scale, Scale, abs (Scale)) / minRad2;
    float absScalem1 = abs (Scale - 1.0);
    float AbsScaleRaisedTo1mIters = pow (abs (Scale), float (1 - mandelBoxIterations));
    float DIST_MULTIPLIER = StepSize;

    float4 p = float4 (pos, 1);
    float4 p0 = p; // p.w is the distance estimate

    for (int i = 0; i < mandelBoxIterations; i++)
    {
        //box folding: 
        p.xyz = abs (1 + p.xyz) - p.xyz - abs (1.0 - p.xyz); // add;add;abs.add;abs.add (130.4%)
        p.xyz = clamp (p.xyz, Clamping.x, Clamping.y) * Clamping.z - p.xyz; // min;max;mad

        // sphere folding: if (r2 < minRad2) p /= minRad2; else if (r2 < 1.0) p /= r2;
        float r2 = dot (p.xyz, p.xyz);
        p *= clamp (max (minRad2 / r2, minRad2), Fold.x, Fold.y); // dp3,div,max.sat,mul
        p.xyz += float3 (Increment.x, Increment.y, Increment.z);
        // scale, translate
        p = p * scale + p0;
    }
    float d = ((length (p.xyz) - absScalem1) / p.w - AbsScaleRaisedTo1mIters) * DIST_MULTIPLIER;
    return d;
}

float getDistance (float3 p)
{
    float d = dMandelbox (p);
    return d;
}

// Blinn-Phong shading model with rim lighting (diffuse light bleeding to the other side).
// |normal|, |view| and |light| should be normalized.
float3 blinn_phong (float3 normal, float3 view, float3 light, float3 diffuseColor)
{
    float3 halfLV = normalize (light + view);
    float spe = pow (max (dot (normal, halfLV), Spec.x), Spec.y);
    float dif = dot (normal, light) * 0.1 + 0.15;
    return dif * diffuseColor + spe * Specular;
}

float3 getNormal (float3 p, float offset)
{
    float dt = .0001;
    float3 n = float3 (getDistance (p + float3 (dt, 0, 0)),
        getDistance (p + float3 (0, dt, 0)),
        getDistance (p + float3 (0, 0, dt))) - getDistance (p);
    return normalize (n);
}

float getAO (float3 aoposition, float3 aonormal, float aodistance, float aoiterations, float aofactor)
{
    float ao = 0.0;
    float k = aofactor;
    aodistance /= aoiterations;
    for (float i = 1; i < 4; i += 1)
    {
        ao += (i * aodistance - getDistance (aoposition + aonormal * i * aodistance)) / pow (2, i);
    }
    return 1.0 - k * ao;
}

float MAX_DIST = 300;


// Compute the color at |pos|.
float3 computeColor(float3 pos)
{
    float3 p = pos, p0 = p;
    float trap = 1.0;

    for (int i = 0; i < 3; i++)
    {
        p.xyz = clamp (p.xyz, -1.0, 1.0) * 2.0 - p.xyz;
        float r2 = dot (p.xyz, p.xyz);
        p *= clamp (max (Minrad / r2, Minrad), 0.0, 1.0);
        p = p * Scale + p0.xyz;
        trap = min (trap, r2);
    }
    // |c.x|: log final distance (fractional iteration count)
    // |c.y|: spherical orbit trap at (0,0,0)
    float2 c = clamp (float2 (0.33 * log (dot (p, p)) - 1.0, sqrt (trap)), 0.0, 1.0);

    return lerp (lerp (Surface1, Surface2, c.y), Surface3, c.x);
}



float4 PS (PS_IN input) : SV_Target
{

    //float4 filter= Image2.Sample(samLinear, input.texCoord);
    float3 p = input.worldTViewPos;
    float3 dp = normalize (input.worldTViewDir);

    float totalD = 0.0;
    float D = 3.4e38;
    D = StepSize;
    float extraD = 0.0;
    float lastD;
    int steps;

    // Simple iterator
    for (steps = 0; steps < MaxSteps && abs (D) > MinDistance / 1000; steps++)
    {
        D = getDistance (p);
        p += dp * D;
    }

    p += totalD * dp;

    // Color the surface with Blinn-Phong shading, ambient occlusion and glow.
    float3 col = Background;
    float a = 1;

    // We've got a hit or we're not sure.
    if (D < MAX_DIST)
    {
        float3 n = normalize (getNormal (p, D));
        //n*=float3(1,1,10);
        n = normalize (n);
        col = computeColor(p);
        col = blinn_phong (n, -dp, LightPos, col);

        col = lerp (AmbientOcclusion, col, getAO (p, n, AODistance, 3, AmbientOcclusion.a));

        // We've gone through all steps, but we haven't hit anything.
        // Mix in the background color.
        if (D > MinDistance)
        {
            a = 1 - clamp (log (D / MinDistance) * DistToColor, 0.0, 1.0);
            col = lerp (col, Background, a);
        }
    }
    else
    {
        a = 0;
    }

    // Glow is based on the number of steps.
    col = lerp (col, Glow, float (steps) / float (MaxSteps) * Glow.a);
    float f = clamp (log (length (p - input.worldTViewPos) / Fog), 0, 1);
    col = lerp (col, Background, f);
    a *= (1 - f * Background.a);
    return float4 (col, a);

}

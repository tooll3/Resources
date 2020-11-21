Texture2D<float4> inputTexture : register(t0);
sampler texSampler : register(s0);

cbuffer ParamConstants : register(b0)
{
    float MaxSteps;    
    float DetectionThreshold;
    float RangeThresholdOffset;
    float GradientBias;

    float4 BackgroundColor;
}

cbuffer Resolution : register(b1)
{
    float TargetWidth;
    float TargetHeight;
}

struct Pixel {
    float4 Color;
};

RWStructuredBuffer<Pixel> ResultPoints : u0; 

float2 GetUvFromAddress(int col, int row) {
    return float2( 
            (float)col / (float)TargetWidth, 
            (float)row / (float)TargetHeight);
}

float GetValueFromColor(float4 color) {
    return (color.r + color.g + color.b) / 3;
}

int GetIndexFromAddress(int col, int row) {
    return row * TargetWidth + col; 
}

static int _clampedRange = 1;

static float4 _minColor;
static float4 _maxColor;
static float _minColorValue;
static float _maxColorValue;
static float4 _colorSum;

int ScanRange(int x, int rowIndex, int direction) {
    int steps = 0;
    while(true) {
        x += direction;
        steps++;
        if(steps > _clampedRange) 
            return steps;

        if(x < 0 || x > TargetWidth)  
            return steps;

        float4 c2 = inputTexture.SampleLevel(texSampler, GetUvFromAddress(x, rowIndex) , 0.0);
        float v2= GetValueFromColor(c2);
        if(v2 > DetectionThreshold + RangeThresholdOffset) 
            return steps;

        if(v2 > _maxColorValue) {
            _maxColorValue = v2;
            _maxColor = c2;
        }
        if(v2 < _minColorValue) {
            _minColorValue = v2;
            _minColor = c2;
        }
        _colorSum += c2;        
    }
    return steps;
}


float SchlickBias(float x, float bias) {
    return x / ((1 / bias - 2) * (1 - x) + 1);
}
    

[numthreads(16,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint rowIndex = i.x; 
    _clampedRange = clamp(MaxSteps, 1, 1920*2);

    float4 maxColor = 0;
    float rangeThreshold = DetectionThreshold + RangeThresholdOffset;

    int clampedWidth = clamp(TargetWidth, 1, 1920*2);
    for(int colIndex = 0; colIndex< clampedWidth; colIndex++ ) {

        float2 uv = float2( 
            (float)colIndex / (float)TargetWidth, 
            (float)rowIndex / (float)TargetHeight);

        float4 c = inputTexture.SampleLevel(texSampler, uv , 0.0);
        float v = GetValueFromColor(c);
        ResultPoints[GetIndexFromAddress(colIndex, rowIndex)].Color = c *BackgroundColor; 

        if( v < DetectionThreshold) 
        {
            _minColor = 1;
            _minColorValue = 1;

            _maxColorValue = 0;
            _maxColor = 0;
            _colorSum = 0;

            int leftStepCount = ScanRange(colIndex, rowIndex, -1);
            int rightStepCount = ScanRange(colIndex, rowIndex, 1);
            
            int stepCount = leftStepCount + rightStepCount;
            float4 averageColor = _colorSum / stepCount;

            for(int stepIndex = 0; stepIndex < stepCount; stepIndex++ )
            {
                float f = stepIndex / (float)stepCount;
                float4 c = f < 0.5 
                    ? lerp(_minColor, averageColor, SchlickBias(f * 2, GradientBias) )
                    : lerp(_maxColor, averageColor, SchlickBias(1- (f -0.5) * 2, GradientBias));
                ResultPoints[GetIndexFromAddress(colIndex - leftStepCount + stepIndex, rowIndex)].Color = c;
            }
            colIndex+= rightStepCount;
        }        
    }
}


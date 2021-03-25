#include "point.hlsl"
#include "hash-functions.hlsl"

cbuffer Params : register(b0)
{
    float3 GridSize;
    float _padding1;

    float3 GridOffset;
    float _padding3;

    float3 RandomizeGrid;
    float _padding4;

    float StrokeLength;
    float Speed;
    float PhaseOffset;
}


static const int3 TransitionSteps[] = 
{
    // Source      
    int3(0, 0, 0), // 0
    int3(1, 0, 0), // 1
    int3(1, 1, 0), // 2
    int3(1, 1, 1), // 3
    int3(2, 1, 1), // 4
    int3(2, 2, 1), // 5
    int3(2, 2, 2), // 6
    int3(3, 2, 2), // 7 
    int3(3, 3, 2), // 8 
    int3(3, 3, 3), // 9
    int3(3, 3, 3), // 10
};


StructuredBuffer<Point> StartPoints : t0;
StructuredBuffer<Point> TargetPoints : t1;
RWStructuredBuffer<Point> ResultPoints : u0;

[numthreads(11,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint totalCount, countA, countB, stride;
    ResultPoints.GetDimensions(totalCount, stride);
    StartPoints.GetDimensions(countA, stride);
    TargetPoints.GetDimensions(countB, stride);

    if(i.x > totalCount)
        return;

    const int stepsPerPairCount = 11;
    if(i.x > (uint)totalCount * stepsPerPairCount)
        return;

    uint lineIndex = i.x / stepsPerPairCount;
    uint lineStepIndex = i.x % stepsPerPairCount;

    Point A = StartPoints[lineIndex % (uint)countA];
    Point B = TargetPoints[lineIndex % (uint)countB];

    float2 hash = hash21(lineIndex);

    float3 posA = A.position + 0.0001 / GridSize + GridOffset;
    float3 posB = B.position + 0.0001 / GridSize + GridOffset;

    float3 transition[] = {
        posA,
        floor(posA) + (hash.x > 0.5 ? 1 : 0),
        floor(posB) + (hash.y > 0.5 ? 1 : 0),
        posB
    };

    float3 previousPos = 0;
    float3 p = 0;
    float d =  0;

    float4 stepPositions[11];

    for(int step =0; step <= 10; step++) 
    {
        int3 factorsForStep = TransitionSteps[step];

        p = float3(
            transition[factorsForStep.x].x,
            transition[factorsForStep.y].y,
            transition[factorsForStep.z].z
        );

        if(step > 0) 
        {
            d += length(p - previousPos);
        }

        stepPositions[step] = float4(p, 
                                     1-A.w * Speed * StrokeLength + d / StrokeLength  + PhaseOffset);

        
        previousPos = p;
    }
    
    stepPositions[9].z += 0.1;

    float4 prev = stepPositions[ max(0, lineStepIndex-1)];
    float4 current = stepPositions[ lineStepIndex];
    float4 next = stepPositions[ min(lineStepIndex + 1, 10)];

    float w = 1;
    const float NaN = sqrt(-1); // 0.1f;//

    p = current.xyz;
    d = current.w;
    //float d2 = d;

    // Case A1
    if( current.w < 0 && next.w > 1) {
        float a = abs(current.w);
        float b = next.w;
        float f = saturate(b / (a+b));
        p.xyz = lerp(current.xyz, next.xyz, 1-f);
        d = 0;
    }
    // Case A2
    else if( prev.w < 0 && current.w > 1) {
        float a = abs(current.w) -1 ;
        float b = abs(prev.w) + 1;
        float f = saturate(a / (a+b));
        p.xyz = lerp(prev.xyz, current.xyz, 1-f);
        d = 1;
    }

    // Case B0
    else if(current.w <=0  && next.w < 0) {
        w = NaN;
        //d =0;
    }

    // Case B1
    else if(current.w <= 0 && next.w > 0 && next.w < 1) 
    {
        float a = -current.w;
        float b = next.w;
        float f = saturate(a / (a+b));
        p.xyz = lerp(p, next.xyz, f);
        d =0;
        //w =2;
    }

    // Case B2
    else if(current.w >= 0 && next.w < 1) {
        //p.z += 1.1;
    }

    // Case B3
    else if(prev.w < 1 && current.w > 1) {
        float a = 1 - prev.w;
        float b = current.w - 1;
        float f = saturate(a / (a+b));
        p.xyz = lerp(prev.xyz, p, f);
        d = 1;
    }

    // Case B4
    else if(prev.w > 1 && current.w > 1) {
        w = NaN;
    }


/*

    previousD = previousD / Range.y + A.w + Range.x;
    d = d / Range.y+ A.w + Range.x;

    ResultPoints[i.x].rotation = A.rotation;

    float w = 1;
    if(previousD >= 0 &&  d <= 1 ) {
        //w = 0.1;
        //p2 = previousD;
        float t= abs(previousD) / (abs(previousD) + d);
        //p2 = p2;//lerp(p2, previousPos, 1-d );
    }
    else if(
        //(previousD < 0 && d < 0) 
        //||
         (previousD > 1 && d > 1)
        ) 
    {
        w =  sqrt(-1);
    }    
    else if(previousD < 0 && d > 1) 
    {   
        //w =  sqrt(-1);                
    }
    else if(previousD <= 0 && d >= 0) 
    {                
        float t= abs(previousD) / (abs(previousD) + d);
        //p2 = lerp(previousPos,p2, t );
    }
    else if(previousD >= 0 && previousD <= 1 && d >= 1)  {
        float t= (1-previousD)/ (abs(previousD) + abs(d));        
        //p2 = lerp(previousPos, p2,  t );                
        
    }
    else {
        //w = 100;
    }
    // else {
    //     float t= (1-previousD + d-1) * (1-previousD);
    //     p2 = lerp(previousPos, p2,  t );
    //     //p2.z += 10;
    // }
    //p2 = lerp (posA, posB, (float)lineStepIndex/10 );
    //p2.z = d;

*/
    ResultPoints[i.x].position = (p - GridOffset) * GridSize;
    //ResultPoints[i.x].position.z += current.w;

    ResultPoints[i.x].w =  d * w;

    if( lineStepIndex == 10)
        ResultPoints[i.x].w = NaN; // NaN for divider
}

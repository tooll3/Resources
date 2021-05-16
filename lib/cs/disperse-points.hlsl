//-------------------------------------------------------------------
// BUILD GRID
#include "point.hlsl"
#include "hash-functions.hlsl"
//#include "lib/cs/spatial-grid-functions.hlsl"

// layout(std430) buffer   DispatchCommandBuffer { DispatchCommand dispatchCommandBuffer[]; };
// layout(std430) buffer   AliveIndexBuffer      { uint            aliveIndexBuffer[];      };
// layout(std430) buffer   AliveIndexCountBuffer { uint            aliveIndexCountBuffer[]; };
// layout(std430) buffer   PositionBuffer        { vec4            positionBuffer[];        };


StructuredBuffer<uint> particleGridBuffer :register(t0);
StructuredBuffer<uint> particleGridCellBuffer :register(t1);
StructuredBuffer<uint> particleGridHashBuffer :register(t2);
StructuredBuffer<uint> particleGridCountBuffer :register(t3);
StructuredBuffer<uint> particleGridIndexBuffer :register(t4);

RWStructuredBuffer<Point> points :register(u0);

//uniform uint GroupSize;

#define THREADS_PER_GROUP 512

//StructuredBuffer<uint> particleGridHashBuffer :register(t0);
//StructuredBuffer<uint> particleGridCountBuffer :register(t1);

cbuffer Params : register(b0)
{
    float Threshold;
    float Dispersion;
}

//-------------------------------------------------------------------------
static const uint            ParticleGridEntryCount = 10;
static const uint            ParticleGridCellCount = 10000;
static const float           ParticleGridCellSize = 0.1f;


// bool ParticleGridInsert(in uint index, in float3 position)
// {
//     uint i;
//     int3 cell = int3(position / ParticleGridCellSize);
//     uint cellIndex = (pcg(cell.x + pcg(cell.y + pcg(cell.z))) % ParticleGridCellCount);
//     uint hashValue = max(xxhash(cell.x + xxhash(cell.y + xxhash(cell.z))), 1);
//     uint cellBegin = cellIndex * ParticleGridEntryCount;
//     uint cellEnd = cellBegin + ParticleGridEntryCount;
//     for(i = cellBegin; i < cellEnd; ++i)
//     {
//         uint entryValue;
//         InterlockedCompareExchange(particleGridHashBuffer[i], 0, hashValue, entryValue);
//         if(entryValue == 0 || entryValue == hashValue)
//             break;  // found an available entry
//     }
//     if(i >= cellEnd)
//         return false;   // out of memory

//     //const uint particleOffset = atomicAdd(particleGridCountBuffer[i], 1);

//     uint particleOffset;        
//     InterlockedAdd(particleGridCountBuffer[i], 1, particleOffset);

//     particleGridCellBuffer[index] = uint2(i, particleOffset);
//     return true;
// }

bool ParticleGridFind(in float3 position, out uint startIndex, out uint endIndex)
{
    uint i;
    int3 cell = int3(position / ParticleGridCellSize);
    uint cellIndex = (pcg(cell.x + pcg(cell.y + pcg(cell.z))) % ParticleGridCellCount);
    uint hashValue = max(xxhash(cell.x + xxhash(cell.y + xxhash(cell.z))), 1);
    uint cellBegin = cellIndex * ParticleGridEntryCount;
    uint cellEnd = cellBegin + ParticleGridEntryCount;
    for(i = cellBegin; i < cellEnd; ++i)
    {
        const uint entryValue = particleGridHashBuffer[i];
        if(entryValue == hashValue)
            break;  // found existing entry
        if(entryValue == 0)
            i = cellEnd;
    }
    if(i >= cellEnd)
        return false;
    startIndex = particleGridIndexBuffer[i];
    endIndex = particleGridCountBuffer[i] + startIndex;
    return true;
}



//----------------------------------------------------------------------

// [numthreads( THREADS_PER_GROUP, 1, 1 )]
// void ClearParticleGrid(uint DTid : SV_DispatchThreadID, uint GI: SV_GroupIndex)
// {
//     particleGridHashBuffer[GI.x] = 0;
//     particleGridCountBuffer[GI.x] = 0;
// }


// [numthreads( THREADS_PER_GROUP, 1, 1 )]
// void CountParticlesPerCell(uint DTid : SV_DispatchThreadID, uint GI: SV_GroupIndex)
// {
//     uint pointCount, stride;
//     points.GetDimensions(pointCount, stride);
    
//     //if(GI >= pointCount)
//     if(false)
//         return; // out of bounds

//     //const uint particleIndex = aliveIndexBuffer[GI.x];
//     const float3 position = points[GI.x].position;

//     if(!ParticleGridInsert(GI.x, position))
//         particleGridCellBuffer[GI.x] = uint2(uint(-1), 0);
// }

[numthreads( THREADS_PER_GROUP, 1, 1 )]
void DispersePoints(uint DTid : SV_DispatchThreadID, uint GI: SV_GroupIndex)
{
    uint pointCount, stride;
    points.GetDimensions(pointCount, stride);
        
    if(GI.x >= pointCount)
        return; // out of bounds


    float3 position = points[GI].position;

    uint startIndex, endIndex;
    if(ParticleGridFind(position, startIndex, endIndex)) 
    {
        const uint particleCount = endIndex - startIndex;
        int count =0;
        float3 sumPosition = 0;

        for(uint i=startIndex; i < endIndex; ++i) 
        {
            if( i == GI)
                continue;

            float3 otherPos = points[i].position;
            float3 direction = otherPos - position;
            float distance = length(direction);
            if(distance < Threshold)
                continue;

            sumPosition += direction;
            count++;
        }

        if(count > 0) {

            sumPosition /= count;
            points[GI].position += sumPosition * Dispersion;
        }
    }
}
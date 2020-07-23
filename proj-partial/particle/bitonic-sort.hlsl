

cbuffer SortParameterConstBuffer : register(b0)
{
    unsigned int level;
    unsigned int levelMask;
    unsigned int width;
    unsigned int height;
};

RWStructuredBuffer<unsigned int> Data : register(u0);
groupshared unsigned int SharedData[1024];

[numthreads(1024, 1, 1)]
void bitonicSort(uint3 Gid : SV_GroupID, uint3 DTid : SV_DispatchThreadID, uint3 GTid : SV_GroupThreadID, uint GI : SV_GroupIndex)
{
    SharedData[GI] = Data[DTid.x];
    GroupMemoryBarrierWithGroupSync();
    
    for (unsigned int j = level >> 1 ; j > 0 ; j >>= 1)
    {
        unsigned int result = ((SharedData[GI & ~j] <= SharedData[GI | j]) == (bool)(levelMask & DTid.x))? SharedData[GI ^ j] : SharedData[GI];
        GroupMemoryBarrierWithGroupSync();
        SharedData[GI] = result;
        GroupMemoryBarrierWithGroupSync();
    }
    
    Data[DTid.x] = SharedData[GI];
}


#define TRANSPOSE_BLOCK_SIZE 32
groupshared float2 TransposeSharedData[TRANSPOSE_BLOCK_SIZE * TRANSPOSE_BLOCK_SIZE];

[numthreads(TRANSPOSE_BLOCK_SIZE, TRANSPOSE_BLOCK_SIZE, 1)]
void transpose(uint3 Gid : SV_GroupID, uint3 DTid : SV_DispatchThreadID, uint3 GTid : SV_GroupThreadID, uint GI : SV_GroupIndex)
{
    TransposeSharedData[GI] = Data[DTid.y * width + DTid.x];
    GroupMemoryBarrierWithGroupSync();
    uint2 XY = DTid.yx - GTid.yx + GTid.xy;
    Data[XY.y * height + XY.x] = TransposeSharedData[GTid.x * TRANSPOSE_BLOCK_SIZE + GTid.y];
}
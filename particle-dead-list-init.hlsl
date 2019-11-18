AppendStructuredBuffer<int> DeadParticles : u2;

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    DeadParticles.Append(i.x);
}


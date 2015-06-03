int pCount;
int emitCount;

//Emitters Position Buffer
StructuredBuffer<float3> emitPos;
//Emitters Data Buffer (XYZ emission velocity)
StructuredBuffer<float3> emitVel;

int indexOffset;

struct particle
{
	float3 pos;
	float3 vel;
	float4 color;
	float life;
};
RWStructuredBuffer<particle> Output : BACKBUFFER;

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(1, 1, 1)]
void CSConstantForce( uint3 DTid : SV_DispatchThreadID )
{
	// Emitters Data:
	uint emitIndex = DTid.x % emitCount;
	float3 p = emitPos[emitIndex];
	float3 v = emitVel[emitIndex];

	// indices of emitted particles:
	uint index = indexOffset + DTid.x;
	index = index % pCount;

	// write position and velocity of emitted particles:
	Output[index].vel = v;
	Output[index].pos = p;
	Output[index].life = 0;
}

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 emission
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSConstantForce() ) );
	}
}

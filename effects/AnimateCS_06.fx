float2 testTest;
bool reset;
float3 gravity;
int pCount;

//Ground:
float bounce = 1;

//Reset Position (xyz) and random damping (w)
StructuredBuffer<float4> resetData;

//ATTRACTORS:
float4x4 attrForceT;
//Attractors Position Buffer
StructuredBuffer<float3> attrPos;
//Attractors Data Buffer (X = radius, Y = Strength)
StructuredBuffer<float2> attrData;

//RandomDirectionBuffer
StructuredBuffer<float3> rndDir;
int brwIndexShift;
float brwnStrenght;

struct particle
{
	float3 pos;
	float3 vel;
};
RWStructuredBuffer<particle> Output : BACKBUFFER;

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CSConstantForce( uint3 DTid : SV_DispatchThreadID )
{
	if (reset)
	{
		Output[DTid.x].pos = resetData[DTid.x].xyz;
		Output[DTid.x].vel = 0;
	}

	else
	{
		float3 p = Output[DTid.x].pos;
		float3 v = Output[DTid.x].vel;

		//Velocity Damping:
		v *= resetData[DTid.x].w;
	
		//Multiple attractors
		uint count,dummy;	
		attrPos.GetDimensions(count,dummy);
		for(uint i=0 ; i<count; i++)
		{
			//attrVec = p - attrBuffer[i];
			float3 attrVec = attrPos[i] - p;
			float attrRadius = attrData[i].x;
			float attrStrength = attrData[i].y;

			float attrForce = length(attrVec) / attrRadius;
			attrForce = 1 - attrForce;
			attrForce = saturate(attrForce);
			attrForce = pow(attrForce, 2);
			attrVec = attrVec * attrForce * attrStrength;
			//transform attraction vector:
			attrVec = mul(float4(attrVec,1), attrForceT).xyz;
			v += attrVec;
		}

		// Brownian
		uint rndIndex = DTid.x + brwIndexShift;
		rndIndex = rndIndex % pCount;
		float3 brwnForce = rndDir[rndIndex];
		v += brwnForce * brwnStrenght;
		
		//Ground:
//		if(p.y < 0) 
//		{
//			v = reflect(v, float3(0,1,0));
//			v.y *= bounce;
//			p.y = abs(p.y);
//		}
		//Bounce Smoother:
		//get the y space from 0 to 0.1 and use it attenuate gravity
		float bounceSmooth = saturate(p.y*10);  
		v += gravity * bounceSmooth;

		Output[DTid.x].vel = v;
		Output[DTid.x].pos = p + v;
	}
}

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 simulation
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSConstantForce() ) );
	}
}

//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

float4x4 tV : VIEW;
float4x4 tVP : VIEWPROJECTION;
float4x4 tVI : VIEWINVERSE;
Texture2D texture2d;

float4 c <bool color=true;> = 1;
float velColMult = 1;

struct particle
{
	float3 pos;
	float3 vel;
	float4 color;
	float life;
};
StructuredBuffer<particle> pData;

float radius = 0.05f;
 
    float3 g_positions[4]:IMMUTABLE =
    {
        float3( -1, 1, 0 ),
        float3( 1, 1, 0 ),
        float3( -1, -1, 0 ),
        float3( 1, -1, 0 ),
    };
    float2 g_texcoords[4]:IMMUTABLE = 
    { 
        float2(0,1), 
        float2(1,1),
        float2(0,0),
        float2(1,0),
    };



SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VS_IN
{
	uint iv : SV_VertexID;
	//float4 p: POSITION;	
};

struct vs2ps
{
    float4 PosWVP: SV_POSITION ;	
	float2 TexCd : TEXCOORD0 ;
	float4 Vcol : COLOR ;
};

vs2ps VS(VS_IN input)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
	
	float3 p = pData[input.iv].pos;
	float3 v = pData[input.iv].vel;
	
    Out.PosWVP = float4(p,1);// mul(float4(po.xyz,1),tVP);
	//Out.Vcol = float4(saturate(v * velColMult)+0.5,1);
	Out.Vcol = pData[input.iv].color;
	//Out.Vcol = float4(1,1,1,1);
	
    return Out;
}

[maxvertexcount(4)]
void GS(point vs2ps input[1], inout TriangleStream<vs2ps> SpriteStream)
{
    vs2ps output;
    
    //
    // Emit two new triangles
    //
    for(int i=0; i<4; i++)
    {
        float3 position = g_positions[i]*radius;
        position = mul( position, (float3x3)tVI ) + input[0].PosWVP.xyz;
    	float3 norm = mul(float3(0,0,-1),(float3x3)tVI );
        output.PosWVP = mul( float4(position,1.0), tVP );
        
        output.TexCd = g_texcoords[i];	
        output.Vcol = input[0].Vcol;
    	
        SpriteStream.Append(output);
    }
    SpriteStream.RestartStrip();
}


float4 PS_velCol(vs2ps In): SV_Target
{
    float4 col = In.Vcol;
	//if (col.r < 0.5f) { discard; }
	

    return col;
}

float4 PS_Tex(vs2ps In): SV_Target
{
    float4 col = texture2d.Sample( g_samLinear, In.TexCd)*c;
	//if (col.r < 0.5f) { discard; }
	

    return col;
}

technique10 Constant
{
	pass P0
	{
		
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex() ) );
	}
}

technique10 VelocityColor
{
	pass P0
	{
		
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_velCol() ) );
	}
}




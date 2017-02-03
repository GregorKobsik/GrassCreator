Shader "RainSplatShader" 
{
	Properties 
	{
		_DropSprite("SplatSprite", 2D) = "white" {}
		_Size("Size", Vector) = (1,1,0,0)
		_RainSize("RainSize", Vector) = (1,1,0,0)
		_Color ("Color", Color) = (1,1,1,1)
	}
	
	SubShader 
	{
		Tags{ "Queue" = "Overlay+100" "RenderType" = "Transparent" }

		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha

		Cull off
		ZWrite off
		
		Pass
		{

			CGPROGRAM
			#pragma target 5.0

			#pragma vertex vert			
			#pragma geometry geom
			#pragma fragment frag

			#pragma multi_compile_fog


			#include "UnityCG.cginc"

			sampler2D _SplatSprite;

			float4 _Color = float4(1, 0.5f, 0.0f, 1);
			float2 _RainSize = float2(1, 1);
			float2 _Size = float2(1, 1);
			float3 _WorldPos;

			struct data {
				float3 pos;
			};

			//The buffer containing the points we want to draw.
			StructuredBuffer<data> buf_Points;

			struct input
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
			};

			input vert(uint id : SV_VertexID)
			{
				input o;
				UNITY_INITIALIZE_OUTPUT(input, o);

				o.pos = float4(buf_Points[id].pos + _WorldPos, 1.0f);
				return o;
			}

			float4 RotPoint(float4 p, float3 offset, float3 sideVector, float3 upVector)
			{
				float3 finalPos = p.xyz;

				finalPos += offset.x * sideVector;
				finalPos += offset.y * upVector;

				return float4(finalPos, 1);
			}

			[maxvertexcount(4)]
			void geom(point input particle[1], inout TriangleStream<input> triStream)
			{
				if (particle[0].pos.y < 10) {
					float2 halfS = _Size;

					float4 v[4];

					float3 up = float3(0, 1, 0);
					float3 look = _WorldSpaceCameraPos - particle[0].pos.xyz;

					look = normalize(look);
					look.y = 0;
					float3 side = normalize(cross(look, up));

					v[0] = RotPoint(particle[0].pos, float3(-_Size.x, (-_Size.y - _RainSize.y), 0), side, up);
					v[1] = RotPoint(particle[0].pos, float3(-_Size.x, (_Size.y - _RainSize.y), 0), side, up);
					v[2] = RotPoint(particle[0].pos, float3(_Size.x, (-_Size.y - _RainSize.y), 0), side, up);
					v[3] = RotPoint(particle[0].pos, float3(_Size.x, (_Size.y - _RainSize.y), 0), side, up);

					input pIn;

					pIn.pos = mul(UNITY_MATRIX_VP, v[0]);
					pIn.uv = float2(0.0f, 0.0f);
					UNITY_TRANSFER_FOG(pIn, pIn.pos);
					triStream.Append(pIn);

					pIn.pos = mul(UNITY_MATRIX_VP, v[1]);
					pIn.uv = float2(0.0f, 1.0f);
					UNITY_TRANSFER_FOG(pIn, pIn.pos);
					triStream.Append(pIn);

					pIn.pos = mul(UNITY_MATRIX_VP, v[2]);
					pIn.uv = float2(1.0f, 0.0f);
					UNITY_TRANSFER_FOG(pIn, pIn.pos);
					triStream.Append(pIn);

					pIn.pos = mul(UNITY_MATRIX_VP, v[3]);
					pIn.uv = float2(1.0f, 1.0f);
					UNITY_TRANSFER_FOG(pIn, pIn.pos);
					triStream.Append(pIn);
				}
			}

			float4 frag(input i) : COLOR
			{
				fixed4 col = tex2D(_SplatSprite, i.uv) * _Color;
				UNITY_APPLY_FOG(i.fogCoord, col);

				return col;
			}
			ENDCG
		}
	}
	Fallback Off
}

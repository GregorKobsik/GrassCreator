// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "GrassBlade/GrassBillboardShader" {
	Properties{
		_MainTex("Texture", 2D) = "white"{}
		_Color("Overall Color", Color) = (1,1,1,1)
		_Colormap("Color/Shadow Map", 2D) = "white" {}
		_Heightmap("Heightmap", 2D) = "black" {}
		_Heightmap_Coeffizient("Heightmap Coeffizient", Float) = 50
		_ForceMap("Force Map", 2D) = "grey"{}
		_Noisemap("Noise Map", 2D) = "grey" {}
		_Densitymap("Density Map", 2D) = "white" {}
		//_Size("Size of Grass", Float) = 1
		_MaxSize("maximal Size of Grass", Float) = 1
		_MinSize("minimal Size of Grass", Float) = 1
		_Center("Center of Grass", Vector) = (0,0,0,0)
		_CameraPos("Position of Main Camera", Vector) = (0,0,0,0)
		_LightPos("Position of Sun", Vector) = (0,1,0,0)
		_Shininess("Shininess Factor", Float) = 1
		_forceY("ForceY", Float) = 1
		_DiffuseColor("Diffuse color", Color) = (1,1,1,1)
		_SpecularColor("Specular color", Color) = (1,1,1,1)
		_Near("Near distance of grass", Float) = 0
		_Far("Far distance of grass", Float) = 50


		CGINCLUDE

		#include "UnityCG.cginc"
		#include "Lighting.cginc"

			// vert to geo
			struct v2g
		{
			float4 pos: SV_POSITION;
			float4 texcoordGlobal : TANGENT;
			float4 color: TEXCOORD1;

		};

		// geo to frag
		struct g2f
		{
			float4 pos: SV_POSITION;
			float4 posObject : WORLDPOS;
			//float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 texcoordGlobal: TEXCOORD1;

		};



		// Vars
		fixed4 _Color;
		float _Amount;

		uniform sampler2D _Noisemap;
		uniform sampler2D _DetailTex;
		uniform float4 _DetailTex_ST;

		// Vertex modifier function
		v2g vert(appdata_tan v) {

			v2g output = (v2g)0;



			float4 globalCoords = float4(v.tangent.xy, 0, 0);

			output.texcoordGlobal = v.tangent;
			output.pos = mul(unity_ObjectToWorld, v.vertex);

			return output;
		}


		uniform sampler2D _ForceMap;
		uniform float _MaxSize;
		uniform float _MinSize;
		uniform float _Size;

		g2f applyForce(g2f input) {
			g2f output = input;

			//Constantforce
			float3 force = 2 * tex2Dlod(_ForceMap, float4(input.texcoordGlobal.xy, 0, 0)).rgb - float3(1, 1, 1);

			//Windforce
			float3 wind;
			wind.x = 0.5 * cos(30 + input.posObject.x + 30*_Time) * sin(0.5*_Time + 2 * input.posObject.x);
			wind.z = 0.1 * sin(30 + input.posObject.z + 30*_Time) * cos(0.5*_Time + 2 * input.posObject.x);
			
			//normalize the force With Grass Size
			force *= _Size;
			wind *= _Size;

			//calculate the height to preserve Edge Length = Size
			force.y = -_Size + sqrt(_Size*_Size - force.x*force.x - force.z*force.z);
			wind.y = -_Size + sqrt(_Size*_Size - wind.x*wind.x - wind.z*wind.z);

			//normalize the force to texcoord.y
			force *= input.texcoord.y;
			wind *= input.texcoord.y;

			//appply forces
			output.pos += float4(force, 0);
			output.pos += float4(wind,0);


			//change normals;
			output.normal = wind + force;
			output.normal.y = _Size;
			output.normal = normalize(output.normal);

			return output;
		}

		uniform sampler2D _Heightmap;
		uniform float _Heightmap_Coeffizient;

		g2f createPoint(g2f input, float4 offset, float4 texcoord, float4x4 transformMatrix) {

			g2f output = input;

			float4 v = input.pos + offset * _Size;
			output.texcoordGlobal = float4(input.texcoordGlobal.xy + _Size * offset.xz * (1 / input.texcoordGlobal.zw),0,0);
			v.y = tex2Dlod(_Heightmap, float4(output.texcoordGlobal.xy, 0, 0)) * _Heightmap_Coeffizient + _Size*offset.y;
			output.texcoord = texcoord;
			output.pos = v;
			output = applyForce(output);
			output.pos = mul(transformMatrix, output.pos);

			return output;
		}
		
		uniform sampler2D _Densitymap;
		uniform float3 _Center;
		uniform float _Near;
		uniform float _Far;

		[maxvertexcount(12)]
		void geom_star(point v2g p[1], inout TriangleStream<g2f> triStream)
		{
			float4 noise = tex2Dlod(_Noisemap, float4(p[0].texcoordGlobal.xy, 0, 0));		
			_Size = (_MinSize + (_MaxSize - _MinSize) * noise.r);
			float distanceModifier = max(0, 1 - pow(length(_Center.xz - p[0].pos.xz) / _Far, 3));
			float densityHeight = length(tex2Dlod(_Densitymap, float4(p[0].texcoordGlobal.xy, 0, 0)).xyz);
			float Height = min(distanceModifier,densityHeight);
				

			if (Height >= 0.01) {
				float4 v;
				float4x4 vp = mul(UNITY_MATRIX_MVP, unity_WorldToObject);

				g2f pIn;
				pIn.posObject = p[0].pos;
				pIn.normal = float3(0, 1, 0); //lets assume the normal is going up.
				pIn.pos = float4(p[0].pos.xyz, 1);
				pIn.texcoord = float4(0, 0, 0, 0);
				pIn.texcoordGlobal = p[0].texcoordGlobal;


				g2f pOut;


				pOut = createPoint(pIn, float4(-0.5, Height, -0.25, 0), float4(0, 1, 0, 0), vp);
				triStream.Append(pOut);
				pOut = createPoint(pIn, float4(0.5, Height, -0.25, 0), float4(1, 1, 0, 0), vp);
				triStream.Append(pOut);
				pOut = createPoint(pIn, float4(-0.5, 0, -0.25, 0), float4(0, 0, 0, 0), vp);
				triStream.Append(pOut);
				pOut = createPoint(pIn, float4(0.5, 0, -0.25, 0), float4(1, 0, 0, 0), vp);
				triStream.Append(pOut);

				triStream.RestartStrip();



				pOut = createPoint(pIn, float4(0.4, Height, -0.5, 0), float4(0, 1, 0, 0), vp);
				triStream.Append(pOut);
				pOut = createPoint(pIn, float4(-0.1, Height, 0.5, 0), float4(1, 1, 0, 0), vp);
				triStream.Append(pOut);
				pOut = createPoint(pIn, float4(0.4, 0, -0.5, 0), float4(0, 0, 0, 0), vp);
				triStream.Append(pOut);
				pOut = createPoint(pIn, float4(-0.1, 0, 0.5, 0), float4(1, 0, 0, 0), vp);
				triStream.Append(pOut);

				triStream.RestartStrip();



				pOut = createPoint(pIn, float4(0.1, Height, 0.5, 0), float4(0, 1, 0, 0), vp);
				triStream.Append(pOut);
				pOut = createPoint(pIn, float4(-0.4, Height, -0.5, 0), float4(1, 1, 0, 0), vp);
				triStream.Append(pOut);
				pOut = createPoint(pIn, float4(0.1, 0, 0.5, 0), float4(0, 0, 0, 0), vp);
				triStream.Append(pOut);
				pOut = createPoint(pIn, float4(-0.4, 0, -0.5, 0), float4(1, 0, 0, 0), vp);
				triStream.Append(pOut);

				triStream.RestartStrip();
			}
		}

		struct lightInput {
			float attentuation;
			float3 normalDirection;
			float3 lightDirection;
			float3 viewDirection;
		};

		float3 getAmbientLighting() {
			float3 ambientLighting = _Color.a * _Color.rgb * UNITY_LIGHTMODEL_AMBIENT.rgb;
			return ambientLighting;
		}

		uniform float4 _DiffuseColor;

		float3 getDiffuseReflection(lightInput input) {
			float3 diffuseReflection = input.attentuation * _DiffuseColor.rgb * max(0.0, dot(input.normalDirection, input.lightDirection));
			diffuseReflection *= _DiffuseColor.a;
			return diffuseReflection;
		}

		uniform float _Shininess;
		uniform float4 _SpecularColor;

		float3 getSpecularReflection(lightInput input) {

			float3 specularReflection;

			if (dot(input.normalDirection, input.lightDirection) < 0.0) {
				specularReflection = float3(0, 0, 0);
			}
			else {
				specularReflection = input.attentuation * float3(1,1,1)
					* _SpecularColor.rgb * pow(max(0.0, dot(
						reflect(-input.lightDirection, input.normalDirection),
						input.viewDirection)), _Shininess);
			}

			specularReflection *= _SpecularColor.a;

			return specularReflection;
		}

		float getDisplacementShadow(lightInput input) {
			return (1 - length(cross(float3(0, 1, 0), input.normalDirection)));
		}

		sampler2D _MainTex;

		uniform sampler2D _Colormap;
		
		uniform float3 _CameraPos;
		uniform float3 _LightPos;

		fixed4 frag(g2f input) : COLOR{
			
			float4 textureColor = tex2D(_MainTex, input.texcoord.xy);
			if ((textureColor.r < 0.3 && textureColor.g < 0.3 && textureColor.b < 0.3)) {
				discard;
			}

			//float3 viewDirection = normalize(_CameraPos.xyz - input.posObject.xyz); //can be changed in script between directional and point light
			
			//float attentuation;
			//_LightPos *= 3.14159265359 / 180;
			//float3 lightDirection = float3(sin(_LightPos.x)*cos(_LightPos.z), sin(_LightPos.x)*sin(_LightPos.z), cos(_LightPos.x));
			float distance = length(_CameraPos.xyz - input.pos.xyz);
			/*
			if (_WorldSpaceLightPos0.w == 0.0) {
				attentuation = 1;//LIGHT_ATTENUATION(input);
				lightDirection = normalize(_WorldSpaceLightPos0.xyz);
			}
			else
			{
				float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - input.pos.xyz;	
				float distance = length(vertexToLightSource);
				attentuation = 1/distance;//LIGHT_ATTENUATION(input);
				lightDirection = normalize(vertexToLightSource);
			}

			

			lightInput lightIn;
			lightIn.attentuation = attentuation;
			lightIn.lightDirection = lightDirection;
			lightIn.viewDirection = viewDirection;
			lightIn.normalDirection = normalize(input.normal);

			float3 ambientLighting = getAmbientLighting();
			float3 diffuseReflection = getDiffuseReflection(lightIn);
			float3 specularReflection = getSpecularReflection(lightIn);
			*/


			float4 colorMapColor = tex2D(_Colormap, input.texcoordGlobal);
			float4 noise = tex2D(_Noisemap, input.texcoordGlobal) - float4(.5,.5,.5,.5);

			float4 resultColor = colorMapColor + 0.05* noise;

			//resultColor *= float4(diffuseReflection, 1);
			//resultColor += float4(ambientLighting, 0);
			resultColor.a = 1 / distance;

			return resultColor;

		}

		ENDCG


	}
		SubShader{
		Pass{
			Tags{ "RenderType" = "Opaque" }
			LOD 200
			Cull Off
			Blend OneMinusSrcAlpha SrcAlpha
			ZWrite On

			CGPROGRAM
			#pragma target 5.0
			//#pragma addshadow
			#pragma vertex vert
			#pragma geometry geom_star
			#pragma fragment frag

			ENDCG
		}
			/*
			Pass{
			Tags{ "LightMode" = "ShadowCaster" }
			LOD 200
			Cull Off
			//Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On

			CGPROGRAM
			#pragma target 5.0
			//#pragma addshadow
			#pragma vertex vert
			#pragma geometry geom_star
			#pragma fragment frag

			ENDCG
		}*/


	}

		FallBack "Diffuse"
}
Shader "GrassBlade/GrassGeometryShader" {
	Properties{

		_DetailMap("Detailmap (Grey)", 2D) = "grey" {}
		_ColorMap("Colormap", 2D) = "white" {}
		_NoiseMap("Noisemap", 2D) = "grey" {}
		_DensityMap("Densitymap", 2D) = "white" {}
		_ForceMap("Forcemap", 2D) = "grey" {}

		_MaxHeight("maximal height of grass", Float) = 1
		_MinHeight("minimal height of grass", Float) = 1
		
		_Width("Width of grass blade", Range(0.01,0.3)) = 0.1
		_MeshSize("Size of terrain mesh", Float) = 128
		
		_Tess("Tessellation", Range(1,100)) = 4

		_Stiffness("Stiffness", Range(0.3,2)) = 0.5
		_Far("Far distance", Float) = 20

		_CameraPos("Position of Main Camera", Vector) = (0,0,0,0)
		_LightPos("Position of Sun", Vector) = (0,1,0,0)
	}

		CGINCLUDE

		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"

				
		const float pi = 3.14159;

		struct appdata_vert {
			float3 vertex	:			POSITION;
			float2 worldPos	:			TEXCOORD0;
			float2 texcoord	:			TEXCOORD1;
		};

		struct appdata {
			float4 vertex	:			POSITION;
			float3 worldPos :			TEXCOORD0;
			float3 tangent	:			TANGENT;
			float3 normal	:			NORMAL;
			float3 texcoord :			TEXCOORD1;
			float2 texcoordGlobal	:	TEXCOORD2;		
			float3 viewDirWorld		:	TEXCOORD3;
			float3 bezierControl	:	TEXCOORD4;
		};

////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////   VERTEX   //////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

		float _Height;
		float _MaxHeight;
		float _MinHeight;


		sampler2D _DensityMap;
		sampler2D _NoiseMap;
		float4 _CameraPos;
		float _Far;

		//randomized displacement of grass blade
		void randomizedDisplacement(inout appdata v) {

			//remap position to (0,y,0)
			v.vertex.xyz -= v.worldPos;

			//read random Numbers from texture
			float4 noise = tex2Dlod(_NoiseMap, float4(v.texcoordGlobal, 0, 0));

			//change height
			
			_Height = (_MinHeight + (_MaxHeight - _MinHeight) * noise.r);
			float densityHeight = length(tex2Dlod(_DensityMap, float4(v.texcoordGlobal, 0, 0)).xyz);
			_Height *= densityHeight;

			v.vertex.y = (v.texcoord.y) * _Height;
			v.bezierControl *= (1 - v.texcoord.y) * _Height;

			//random rotation first around x-axis, then y-axis
			float a = (noise.r) * 8;
			float b = (noise.b);
			float3x3 rotMatX = float3x3(
				float3(cos(a),	0,	sin(a)),
				float3(0,		1,	-sin(b)),
				float3(-sin(a), 0,	cos(a)));
			float3x3 rotMatY = float3x3(
				float3(1,	0,		0),
				float3(0,	cos(b), -sin(b)),
				float3(0,	sin(b), cos(b)));

			float3x3 rotMat = mul(rotMatX, rotMatY);;
			float3x3 rotMatT = transpose(rotMat);

			v.vertex.xyz = mul(v.vertex.xyz, rotMatT);
			v.tangent = mul(v.tangent, rotMatT);
			v.normal = mul(v.normal, rotMatT);

			//restorePosition to worldSpace
			v.vertex.xyz += v.worldPos;

			//random displacement by 0.1 units to pos or neg
			v.vertex.xz += (noise.gb - float2(.5, .5));
			v.worldPos.xz += (noise.gb - float2(.5, .5));

		}

		uniform sampler2D _ForceMap;
		float _Stiffness;

		//apply forces to grass blade
		void applyForces(inout appdata v) {
			//remap position to (0,y,0)
			v.vertex.xyz -= v.worldPos;

			//Constantforce
			float3 force = 2 * tex2Dlod(_ForceMap, float4(v.texcoordGlobal.xy, 0, 0)).rgb - float3(1, 1, 1);

			//Windforce
			float3 wind;
			wind.x = 0.5 * cos(30 + v.worldPos.x + 30 * _Time) * sin(0.5*_Time + 2 * v.worldPos.x);
			wind.z = 0.1 * sin(30 + v.worldPos.z + 30 * _Time) * cos(0.5*_Time + 2 * v.worldPos.x);

			//normalize the force With Grass Height
			force *= _Height;
			wind *= _Height;

			//calculate the height to preserve Edge Length = Size
			force.y = -_Height + sqrt(_Height*_Height - force.x*force.x - force.z*force.z);
			wind.y = -_Height + sqrt(_Height*_Height - wind.x*wind.x - wind.z*wind.z);

			//normalize the force to texcoord.y
			wind *= v.texcoord.y;

			//appply forces
			
			//convert vector to euler
			float x = wind.x;
			float y = wind.y;
			float z = wind.z;

			float r = sqrt(x*x + y*y + z*z)*0.2;

			//create rotation matrix
			float3x3 rotMat = float3x3(
				float3(cos(r),	0,	-sin(r)),
				float3(0,		1,	0),
				float3(sin(r),	0,	cos(r))
				);
			float3x3 rotMatT = transpose(rotMat);

			v.vertex.xyz += float3(x, y, z);
			v.vertex.xyz = mul(v.vertex.xyz, rotMatT);


			v.bezierControl.xz += force.xz *(1 - v.texcoord.y);
			v.vertex.xyz += force * v.texcoord.y;
			
			//wobble
			r *= v.texcoord.y;
			rotMat = float3x3(
				float3(cos(r), 0, -sin(r)),
				float3(0, 1, 0),
				float3(sin(r), 0, cos(r))
				);
			rotMatT = transpose(rotMat);

			v.normal = mul(v.normal, rotMatT);
			v.tangent = mul(v.tangent, rotMatT);


			//restorePosition to worldSpace
			v.vertex.xyz += v.worldPos;
		}

		float _MeshSize;
		

		//standard vertex 
		appdata vert( appdata_vert input)
		{
			appdata v;

			float4x4 modelMatrix = unity_ObjectToWorld;
			float4x4 modelMatrixInverse = unity_WorldToObject;

			v.normal = normalize(
				mul(float3(0,0,1), modelMatrixInverse).xyz
			);
			v.tangent = normalize(
				mul(modelMatrix, float3(1,0,0)).xyz
			);


			v.worldPos = mul(modelMatrix, input.vertex);

			v.viewDirWorld = normalize(
				_WorldSpaceCameraPos.xyz - v.worldPos.xyz
			);

			v.texcoordGlobal = v.worldPos.xz / _MeshSize;

			v.bezierControl = float3(0, _Stiffness, 0) * (1-input.texcoord.x);

			v.vertex = float4(input.vertex,1);
			v.texcoord = float3(0.5,input.texcoord.x,0);
			
			randomizedDisplacement(v);
			applyForces(v);

			//missing: v.vertex = mul(UNITY_MATRIX_MVP, v.vertex) object will be moved to screen space after geometry stage
			return v;
		}
		

////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////   TESSELLATION   ///////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

		struct outputControlPoint {
			float3 position : BEZIERPOS;
		};

		struct outputPatchConstant {
			float edges[2]        : SV_TessFactor;
		};

		float _Tess;

		outputPatchConstant patchConstantThing(InputPatch <appdata, 2> v) {
			outputPatchConstant o;

			//add here some nice distance based Tessellation
			float3 midpoint = (v[0].vertex + v[1].vertex) / 2;
			o.edges[0] = 1;
			o.edges[1] = (1 + (_Tess / ((length(midpoint - _WorldSpaceCameraPos)/10))));

			return o;
		}

		// tessellation hull shader
		[domain("isoline")]
		[partitioning("pow2")]
		[outputtopology("line")]
		[patchconstantfunc("patchConstantThing")]
		[outputcontrolpoints(2)]
		appdata base(InputPatch<appdata, 2> v, uint id : SV_OutputControlPointID) {
			return v[id];
		}

		//evaluate the bezier curve
		float3 dispBezier(float3 v[4], float Coord)
		{
			float OneMinusCoord = 1 - Coord;
			float p0 = OneMinusCoord*OneMinusCoord*OneMinusCoord;
			float p1 = 3 * OneMinusCoord*OneMinusCoord*Coord;
			float p2 = 3 * OneMinusCoord*Coord*Coord;
			float p3 = Coord*Coord*Coord;

			float3 output = p0*v[0] + p1*v[1] + p2*v[2] + p3*v[3];

			return  output;
		}
			
		// tessellation domain shader
		[domain("isoline")]
		appdata domain(outputPatchConstant tessFactors, const OutputPatch<appdata, 2> vi, float2 bary : SV_DomainLocation) {
			appdata v;
			v = vi[0];
			v.vertex = vi[0].vertex*bary.x + vi[1].vertex*(1-bary.x);
			v.tangent = normalize(vi[0].tangent*bary.x + vi[1].tangent*(1 - bary.x));
			v.normal = normalize(vi[0].normal*bary.x + vi[1].normal*(1-bary.x));
			v.texcoord = 1-normalize(vi[0].texcoord*bary.x + vi[1].texcoord*(1 - bary.x));
			
			float3 bezierInput[4];
			bezierInput[3] = vi[0].vertex;
			bezierInput[2] = vi[0].bezierControl + vi[0].vertex;
			bezierInput[1] = vi[1].bezierControl + vi[1].vertex;
			bezierInput[0] = vi[1].vertex;
 			v.vertex = float4(dispBezier(bezierInput, v.texcoord.y),1);
			
			return v;
		}



		
			

////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////   GEOMETRY   /////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

		float _Width;

		//create grass blade surface from middleline
		[maxvertexcount(4)]
		void geom(line appdata p[2], inout TriangleStream<appdata> triStream)
		{
			appdata newPoint;
			newPoint = p[0];
			newPoint.vertex = p[0].vertex - float4(p[0].tangent * sin(p[0].texcoord.y) * _Width,0);
			newPoint.vertex = mul(UNITY_MATRIX_MVP, newPoint.vertex);
			newPoint.texcoord.x = 0;
			triStream.Append(newPoint);
			newPoint.vertex = p[0].vertex + float4(p[0].tangent * sin(p[0].texcoord.y) *_Width,0);
			newPoint.vertex = mul(UNITY_MATRIX_MVP, newPoint.vertex);
			newPoint.texcoord.x = 1;
			triStream.Append(newPoint);

			newPoint = p[1];
			newPoint.vertex = p[1].vertex - float4(p[1].tangent * sin(p[1].texcoord.y) * _Width,0);
			newPoint.vertex = mul(UNITY_MATRIX_MVP, newPoint.vertex);
			newPoint.texcoord.x = 0;
			triStream.Append(newPoint);
			newPoint.vertex = p[1].vertex + float4(p[1].tangent * sin(p[1].texcoord.y) * _Width,0);
			newPoint.vertex = mul(UNITY_MATRIX_MVP, newPoint.vertex);
			newPoint.texcoord.x = 1;
			triStream.Append(newPoint);

			triStream.RestartStrip();
		}

////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////   FRAGMENT   /////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

			struct lightInput {
				float attentuation;
				float3 normalDirection;
				float3 lightDirection;
				float3 viewDirection;
			};

			uniform float4 _Color;

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
					specularReflection = input.attentuation * float3(1, 1, 1)
						* _SpecularColor.rgb * pow(max(0.0, dot(
							reflect(-input.lightDirection, input.normalDirection),
							input.viewDirection)), _Shininess);
				}

				specularReflection *= _SpecularColor.a;

				return specularReflection;
			}


			uniform float3 _LightPos;

			uniform sampler2D _ColorMap;
			uniform sampler2D _DetailMap;

			//add color according to terrain
			fixed4 fragWithoutAmbient(in appdata v) : COLOR{


				//float3 viewDirection = normalize(_CameraPos.xyz - v.vertex.xyz); //can be changed in script between directional and point light

				//float attentuation;
				//float3 lightDirection = float3(sin(_LightPos.x)*cos(_LightPos.z), sin(_LightPos.x)*sin(_LightPos.z), cos(_LightPos.x));
				float distance = length(_CameraPos.xyz - v.vertex.xyz);
				/*
				if (_WorldSpaceLightPos0.w == 0.0) {
					attentuation = 1;//LIGHT_ATTENUATION(input);
					lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				}
				else
				{
					float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - v.vertex.xyz;
					float distance = length(vertexToLightSource);
					attentuation = 1 / distance;//LIGHT_ATTENUATION(input);
					lightDirection = normalize(vertexToLightSource);
				}



				lightInput lightIn;
				lightIn.attentuation = attentuation;
				lightIn.lightDirection = lightDirection;
				lightIn.viewDirection = viewDirection;
				lightIn.normalDirection = normalize(v.normal);

				float3 ambientLighting = getAmbientLighting();
				float3 diffuseReflection = getDiffuseReflection(lightIn);
				float3 specularReflection = getSpecularReflection(lightIn);


				*/
				float4 colorMapColor = tex2D(_ColorMap, v.texcoordGlobal);
				float4 noise = tex2D(_NoiseMap, v.texcoordGlobal) - float4(.5,.5,.5,.5);
				float4 detail = float4(.5, .5, .5, .5) + tex2D(_DetailMap, v.texcoord);

				float4 resultColor = (colorMapColor + 0.05* noise) * detail;

				return resultColor;

			}

			float4 fragWithAmbient(in appdata v) : COLOR
			{
				float4 color = fragWithoutAmbient(v);
				color += float4(getAmbientLighting(),0);
				return color;
			}

			float4 solidColor(in appdata v) : COLOR{
				float4 color = tex2D(_NoiseMap, float4(v.texcoordGlobal.xy,0,0));
				return color;
			}

				ENDCG

				SubShader {
				Pass{
					Tags{ //"LightMode" = "ForwardBase"
					"RenderType" = "Opaque"
				}
					// pass for ambient light and first light source
					LOD 300

					Cull Off

					CGPROGRAM
					#pragma multi_compile_fwdbase
					#pragma vertex vert
					#pragma fragmentoption ARB_precision_hint_fastest
					#pragma hull base
					#pragma domain domain
					#pragma geometry geom
					#pragma fragment fragWithoutAmbient
					#pragma target 5.0
					#pragma debug

					ENDCG
				}
			}
			Fallback "Specular"
}
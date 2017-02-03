
Shader "Custom/TerrainCreatorShader" {
	Properties{
		//_Offset("Offset", Range(1,10)) = 1
		//_Tess("Tessellation", Range(1,10)) = 2

		_HeightMap("Heightmap",2D) = "black" {}
		_NormalTex("Normal Texture", 2D) = "white" {}
		_TangentTex("Tangent Texture", 2D) = "white" {}

	_MainTex("Splat Map", 2D) = "white" {}

	_Texture1("Texture 1", 2D) = "white" {}
	_NormalTex1("Normal Map 1", 2D) = "bump" {}
	_ParallaxTex1("Heightmap 1", 2D) = "black" {}


	_Texture2("Texture 2", 2D) = "white" {}
	_NormalTex2("Normal Texture 2", 2D) = "bump" {}
	_ParallaxTex2("Heightmap 2", 2D) = "black" {}

	_Texture3("Texture 3", 2D) = "white" {}
	_NormalTex3("Normal Texture 3", 2D) = "bump" {}
	_ParallaxTex3("Heightmap 1", 2D) = "black" {}

	_Texture4("Texture 4", 2D) = "white" {}
	_NormalTex4("Normal Texture 4", 2D) = "bump" {}
	_ParallaxTex4("Heightmap 1", 2D) = "black" {}

	_Parallax("Max Height", Range(0, 0.1)) = 0.01
		_MaxTexCoordOffset("Max Texture Coordinate Offset", Range(0, 0.1)) = 0.01

		_Color("Diffuse Material Color", Color) = (1,1,1,1)
		_Lambertian("Lambertian of the Color", Float) = 1.0
		_SpecColor("Specular Material Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Float) = 10

		_scaleHeight("Scale factor for height (set by CPU)", Float) = 50


		_tessellationMap("Tessellation Map",2D) = "black" {}
		_userTessLevel("Tessellation level", Range(0,63)) = 1
		_userTessConstant("Constant tessellation Weight", Float) = 1
		_userTessNormal("Normal tessellation Weight", Float) = 1
		_userTessDistance("Distance tessellation Weight", Float) = 1
		_userTessMap("Tessellation map Weight", Float) = 1


	}


		CGINCLUDE
	#include "UnityCG.cginc"
	#include "Lighting.cginc"
	#include "AutoLight.cginc"

		//uniform float4 _LightColor0;

		// User-specified properties
		uniform float _Offset;
	uniform float _Tess;

	uniform sampler2D _NormalTex;
	uniform sampler2D _NormalTex_ST;

	uniform sampler2D _HeightMap;
	uniform sampler2D _HeightMap_ST;

	uniform sampler2D _MainTex;
	uniform float4 _MainTex_ST;

	uniform sampler2D _Texture1;
	uniform float4 _Texture1_ST;
	uniform sampler2D _NormalTex1;
	uniform float4 _NormalTex1_ST;
	uniform sampler2D _ParallaxTex1;
	uniform float4 _ParallaxTex1_ST;

	uniform sampler2D _Texture2;
	uniform float4 _Texture2_ST;
	uniform sampler2D _NormalTex2;
	uniform float4 _NormalTex2_ST;
	uniform sampler2D _ParallaxTex2;
	uniform float4 _ParallaxTex2_ST;

	uniform sampler2D _Texture3;
	uniform float4 _Texture3_ST;
	uniform sampler2D _NormalTex3;
	uniform float4 _NormalTex3_ST;
	uniform sampler2D _ParallaxTex3;
	uniform float4 _ParallaxTex3_ST;

	uniform sampler2D _Texture4;
	uniform float4 _Texture4_ST;
	uniform sampler2D _NormalTex4;
	uniform float4 _NormalTex4_ST;
	uniform sampler2D _ParallaxTex4;
	uniform float4 _ParallaxTex4_ST;

	uniform float _Parallax;
	uniform float _MaxTexCoordOffset;


	uniform float4 _Color;
	uniform float _Lambertian;
	uniform float _Shininess;

	uniform float _scaleHeight;

	uniform sampler2D _tessellationMap;
	uniform float _userTessLevel;

	uniform float _userTessConstant;
	uniform float _userTessNormal;
	uniform float _userTessDistance;
	uniform float _userTessMap;

	

	struct vertexInput {
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 tangent : TANGENT;
		float4 texCoord : TEXCOORD0;
	};
	struct vertexOutput {
		float4 pos : SV_POSITION;
		float4 posWorld : TEXCOORD0;
		float3 texCoord : TEXCOORD1;
		float3 normalWorld : TEXCOORD2;
		float3 tangentWorld : TEXCOORD3;
		float3 binormalWorld : TEXCOORD4;
		float3 viewDirWorld : TEXCOORD5;
		float3 viewDirInScaledSurfaceCoords : TEXCOORD6;
		LIGHTING_COORDS(7, 8)
	};

	struct lightInput {
		float attentuation;
		float3 normalDirection;
		float3 lightDirection;
		float3 viewDirection;
	};

	struct splatInput {
		sampler2D tex;
		float3 texCoord;
		float4 texST;
		float3 ambient;
		float3 diffuse;
		float3 specular;
		float alpha;
	};

	struct splatBlendInput {
		float3 color1;
		float alpha1;
		float height1;
		float3 color2;
		float alpha2;
		float height2;
		float3 color3;
		float alpha3;
		float height3;
		float3 color4;
		float alpha4;
		float height4;
	};

	struct normalInput {
		sampler2D tex;
		float3 texCoord;
		float4 texST;
		float3x3 local2WorldTranspose;
	};

	struct parallaxInput {
		sampler2D tex;
		float3 texCoord;
		float4 texST;
		float parallax;
		float3 viewDirInScaledSurfaceCoords;
		float maxTexCoordOffset;
	};

	struct parallaxOutput {
		float2 coordOffset;
		float height;
	};

	struct inputControlPoint {
		float4 pos : SV_POSITION;
		float4 posWorld : TEXCOORD0;
		float3 texCoord : TEXCOORD1;
		float3 normalWorld : TEXCOORD2;
		float3 tangentWorld : TEXCOORD3;
		float3 binormalWorld : TEXCOORD4;
		float3 viewDirWorld : TEXCOORD5;
		float3 viewDirInScaledSurfaceCoords : TEXCOORDS6;

	};

	struct outputControlPoint {
		float3 position : BEZIERPOS;
	};

	struct outputPatchConstant {
		float edges[3]        : SV_TessFactor;
		float inside : SV_InsideTessFactor;
	};
	

	outputPatchConstant patchConstantThing(InputPatch<inputControlPoint, 3> v) {
		outputPatchConstant o;

		//calculate the mid of the edge and the distance of the mid edge to the camera
		// to preserve two neighboring edges have the same tess level!
		float3 midPos = (v[0].pos + v[1].pos + v[2].pos) / 3;
		float3 midPos0 = (v[0].pos + v[1].pos) / 2;
		float3 midPos1 = (v[1].pos + v[2].pos) / 2;
		float3 midPos2 = (v[2].pos + v[0].pos) / 2;

		float distanceToCameraMid = 1 / length(midPos - _WorldSpaceCameraPos);
		float distanceToCameraMid0 = 1 / length(midPos0 - _WorldSpaceCameraPos);
		float distanceToCameraMid1 = 1 / length(midPos1 - _WorldSpaceCameraPos);
		float distanceToCameraMid2 = 1 / length(midPos2 - _WorldSpaceCameraPos);

		//lookup tesslevel on tessellationMap
		float tess = tex2Dlod( _tessellationMap, (float4(v[0].texCoord + v[1].texCoord + v[2].texCoord,0)) / 3).r;
		float tess0 = tex2Dlod(_tessellationMap, (float4(v[0].texCoord + v[1].texCoord,0)) / 2).r;
		float tess1 = tex2Dlod(_tessellationMap, (float4(v[1].texCoord + v[2].texCoord, 0)) / 2).r;
		float tess2 = tex2Dlod(_tessellationMap, (float4(v[0].texCoord + v[0].texCoord, 0)) / 2).r;

		//normal tessalletion
		float normalTess0 = length(cross(v[0].normalWorld, v[1].normalWorld));
		float normalTess1 = length(cross(v[1].normalWorld, v[2].normalWorld));
		float normalTess2 = length(cross(v[2].normalWorld, v[0].normalWorld));
		float normalTessMid = (normalTess0 + normalTess1 + normalTess2) / 3;

		//use a weighted formula to get the correct edge tessellation level
		float tessellationLevelInner = 1 + ((_userTessConstant + tess * _userTessMap + distanceToCameraMid * _userTessDistance + normalTessMid * _userTessNormal)
			/ (_userTessConstant + _userTessMap + _userTessDistance + _userTessNormal)) *_userTessLevel;
		float tessellationLevel0 = 1 + ((_userTessConstant + tess0 * _userTessMap + distanceToCameraMid0 * _userTessDistance + normalTess0 * _userTessNormal)
			/ (_userTessConstant + _userTessMap + _userTessDistance + _userTessNormal)) *_userTessLevel;
		float tessellationLevel1 = 1 + ((_userTessConstant + tess1 * _userTessMap + distanceToCameraMid1 * _userTessDistance + normalTess1 * _userTessNormal)
			/ (_userTessConstant + _userTessMap + _userTessDistance + _userTessNormal)) *_userTessLevel;
		float tessellationLevel2 = 1 + ((_userTessConstant + tess2 * _userTessMap + distanceToCameraMid2 * _userTessDistance + normalTess2 * _userTessNormal)
			/ (_userTessConstant + _userTessMap + _userTessDistance + _userTessNormal)) *_userTessLevel;

		o.edges[0] = tessellationLevel1;
		o.edges[1] = tessellationLevel2;
		o.edges[2] = tessellationLevel0;
		o.inside = tessellationLevelInner;

		return o;
	}

	// tessellation hull shader
	[domain("tri")]
	[partitioning("fractional_odd")]
	[outputtopology("triangle_cw")]
	[patchconstantfunc("patchConstantThing")]
	[outputcontrolpoints(3)]
	inputControlPoint base(InputPatch<inputControlPoint, 3> v, uint id : SV_OutputControlPointID) {
		return v[id];
	}

	vertexOutput displace(appdata_tan input) {
		vertexOutput output;

		float4x4 modelMatrix = unity_ObjectToWorld;
		float4x4 modelMatrixInverse = unity_WorldToObject;

		input.vertex.y = tex2Dlod(_HeightMap, float4(input.texcoord.xy, 0, 0)) * _scaleHeight;
		

		//need to create better normal textures, they should be generated while setting the 
		//vertexes on the CPU, this would work better, then having a fixed normal map.
		//input.normal = tex2Dlod(_NormalTex, float4(input.texCoord.x ,input.texCoord.y, 0, 0)).rgb;

		output.normalWorld = normalize(
			mul(float4(input.normal, 0.0), modelMatrixInverse).xyz
		);

		//need to create better tangents, they should be created together with normals
		//input.tangent = float4(normalize(cross(input.normal, float3(1,1,1))),0);

		output.tangentWorld = normalize(
			mul(modelMatrix, float4(input.tangent.xyz, 0.0)).xyz
		);
		output.binormalWorld = normalize(
			cross(output.normalWorld, output.tangentWorld)
			* input.tangent.w
		);

		float3 binormal = cross(input.normal, input.tangent.xyz) * input.tangent.w;

		float3 viewDirInObjectCoords = mul(
			modelMatrixInverse, float4(_WorldSpaceCameraPos, 1)).xyz
			- input.vertex.xyz;

		float3x3 localSurface2ScaledObjectT =
			float3x3(
				input.tangent.xyz,
				binormal,
				input.normal);

		output.viewDirInScaledSurfaceCoords =
			mul(localSurface2ScaledObjectT, viewDirInObjectCoords);

		output.posWorld = mul(modelMatrix, input.vertex);
		output.viewDirWorld = normalize(
			_WorldSpaceCameraPos - output.posWorld.xyz
		);
		output.texCoord = input.texcoord;
		output.pos = mul(UNITY_MATRIX_MVP, input.vertex);

		TRANSFER_VERTEX_TO_FRAGMENT(output);

		return output;
	}

	// tessellation domain shader
	[domain("tri")]
	vertexOutput domain(outputPatchConstant tessFactors, const OutputPatch<inputControlPoint, 3> vi, float3 bary : SV_DomainLocation) {
		appdata_tan v;
		v.vertex = vi[0].pos*bary.x + vi[1].pos*bary.y + vi[2].pos*bary.z;
		v.tangent = float4(vi[0].tangentWorld*bary.x + vi[1].tangentWorld*bary.y + vi[2].tangentWorld*bary.z,1);
		v.normal = vi[0].normalWorld*bary.x + vi[1].normalWorld*bary.y + vi[2].normalWorld*bary.z;
		v.texcoord = float4(vi[0].texCoord*bary.x + vi[1].texCoord*bary.y + vi[2].texCoord*bary.z,0);
		vertexOutput o = displace(v);
		return o;
	}

	float3 getAmbientLighting() {
		float3 ambientLighting = _Color.a * _Color.rgb * UNITY_LIGHTMODEL_AMBIENT.rgb;
		return ambientLighting;
	}

	float3 getDiffuseReflection(lightInput input) {
		float3 diffuseReflection = input.attentuation * _LightColor0.rgb * _Color.rgb * max(0.0, dot(input.normalDirection, input.lightDirection));
		return diffuseReflection;
	}

	float3 getSpecularReflection(lightInput input) {

		float3 specularReflection;

		if (dot(input.normalDirection, input.lightDirection) < 0.0) {
			specularReflection = float3(0, 0, 0);
		}
		else {
			specularReflection = input.attentuation * _LightColor0.rgb
				* _SpecColor.rgb * pow(max(0.0, dot(
					reflect(-input.lightDirection, input.normalDirection),
					input.viewDirection)), _Shininess);
		}

		specularReflection *= _SpecColor.a;

		return specularReflection;
	}

	float3 getSplatColor(splatInput input) {
		float3 color;

		color = tex2D(input.tex, input.texST.xy * input.texCoord.xy + input.texST.zw);
		color *= input.ambient.rgb + input.diffuse.rgb;
		color += input.specular.rgb;

		return color;
	}

	float3 getBlendedColor(splatBlendInput input) {
		//for test purposes modified to dismiss alpha chanell, becouse test splatmap does not use it!
		input.height1 += 0.5;
		input.height2 += 0.5;
		input.height3 += 0.5;
		input.height4 += 0.5;
		float3 colorMix = normalize(float3(input.alpha1 * input.height1, input.alpha2 * input.height2,
			input.alpha3 * input.height3));

		float3 outputColor = float3(0, 0, 0);

		outputColor += input.color1 * colorMix.r;
		outputColor += input.color2 * colorMix.g;
		outputColor += input.color3 * colorMix.b;

		return outputColor;
	}

	float3 computeFragNormal(normalInput input) {
		float4 encodedNormal = tex2D(input.tex,
			input.texST.xy * input.texCoord.xy + input.texST.zw);
		float3 localCoords =
			2.0 * encodedNormal.rgb - float3(1.0, 1.0, 1.0);
		float3 normalDirection = normalize(mul(localCoords, input.local2WorldTranspose));

		return normalDirection;
	}

	parallaxOutput computeParallaxOffset(parallaxInput input) {
		parallaxOutput output;
		output.height = input.parallax
			* (-0.5 + tex2D(input.tex,
				input.texST.xy * input.texCoord.xy + input.texST.zw).x);

		float2 texCoordOffset = clamp(output.height * input.viewDirInScaledSurfaceCoords.xy
			/ input.viewDirInScaledSurfaceCoords.z,
			-input.maxTexCoordOffset, input.maxTexCoordOffset);
		texCoordOffset /= 64;

		output.coordOffset = texCoordOffset;

		return output;
	}


	vertexOutput vert(vertexInput input)
	{
		vertexOutput output;

		float4x4 modelMatrix = unity_ObjectToWorld;
		float4x4 modelMatrixInverse = unity_WorldToObject;

		//need to create better normal textures, they should be generated while setting the 
		//vertexes on the CPU, this would work better, then having a fixed normal map.
		//input.normal = tex2Dlod(_NormalTex, float4(input.texCoord.x ,input.texCoord.y, 0, 0)).rgb;

		output.normalWorld = normalize(
			mul(float4(input.normal, 0.0), modelMatrixInverse).xyz
		);

		//need to create better tangents, they should be created together with normals
		//input.tangent = float4(normalize(cross(input.normal, float3(1,1,1))),0);

		output.tangentWorld = normalize(
			mul(modelMatrix, float4(input.tangent.xyz, 0.0)).xyz
		);
		output.binormalWorld = normalize(
			cross(output.normalWorld, output.tangentWorld)
			* input.tangent.w
		);

		float3 binormal = cross(input.normal, input.tangent.xyz) * input.tangent.w;

		float3 viewDirInObjectCoords = mul(
			modelMatrixInverse, float4(_WorldSpaceCameraPos, 1)).xyz
			- input.vertex.xyz;

		float3x3 localSurface2ScaledObjectT =
			float3x3(
				input.tangent.xyz,
				binormal,
				input.normal);

		output.viewDirInScaledSurfaceCoords =
			mul(localSurface2ScaledObjectT, viewDirInObjectCoords);

		output.posWorld = mul(modelMatrix, input.vertex);
		output.viewDirWorld = normalize(
			_WorldSpaceCameraPos - output.posWorld.xyz
		);
		output.texCoord = input.texCoord;
		output.pos = input.vertex;//mul(UNITY_MATRIX_MVP, input.vertex);

		TRANSFER_VERTEX_TO_FRAGMENT(output);

		return output;
	}




	float4 fragWithoutAmbient(vertexOutput input) : COLOR
	{

		parallaxOutput parallaxOut;
	parallaxInput parallaxIn;
	parallaxIn.texCoord = input.texCoord;
	parallaxIn.parallax = _Parallax;
	parallaxIn.viewDirInScaledSurfaceCoords = input.viewDirInScaledSurfaceCoords;
	parallaxIn.maxTexCoordOffset = _MaxTexCoordOffset;

	parallaxIn.tex = _ParallaxTex1;
	parallaxIn.texST = _ParallaxTex1_ST;
	parallaxOut = computeParallaxOffset(parallaxIn);
	float2 texCoordOffset1 = parallaxOut.coordOffset;
	float height1 = parallaxOut.height;

	parallaxIn.tex = _ParallaxTex2;
	parallaxIn.texST = _ParallaxTex2_ST;
	parallaxOut = computeParallaxOffset(parallaxIn);
	float2 texCoordOffset2 = parallaxOut.coordOffset;
	float height2 = parallaxOut.height;

	parallaxIn.tex = _ParallaxTex3;
	parallaxIn.texST = _ParallaxTex3_ST;
	parallaxOut = computeParallaxOffset(parallaxIn);
	float2 texCoordOffset3 = parallaxOut.coordOffset;
	float height3 = parallaxOut.height;

	parallaxIn.tex = _ParallaxTex4;
	parallaxIn.texST = _ParallaxTex4_ST;
	parallaxOut = computeParallaxOffset(parallaxIn);
	float2 texCoordOffset4 = parallaxOut.coordOffset;
	float height4 = parallaxOut.height;

	float3 binormalWorld = normalize(
		cross(input.normalWorld, input.tangentWorld)
	);

	float3x3 local2WorldTranspose = float3x3(
		input.tangentWorld,
		binormalWorld,
		input.normalWorld
		);

	normalInput normalIn;
	normalIn.local2WorldTranspose = local2WorldTranspose;

	normalIn.tex = _NormalTex1;
	normalIn.texST = _NormalTex1_ST;
	normalIn.texCoord = input.texCoord + float3(texCoordOffset1, 0);
	float3 normalDirection1 = computeFragNormal(normalIn);

	normalIn.tex = _NormalTex2;
	normalIn.texST = _NormalTex2_ST;
	normalIn.texCoord = input.texCoord + float3(texCoordOffset2, 0);
	float3 normalDirection2 = computeFragNormal(normalIn);

	normalIn.tex = _NormalTex3;
	normalIn.texST = _NormalTex3_ST;
	normalIn.texCoord = input.texCoord + float3(texCoordOffset3, 0);
	float3 normalDirection3 = computeFragNormal(normalIn);

	normalIn.tex = _NormalTex4;
	normalIn.texST = _NormalTex4_ST;
	normalIn.texCoord = input.texCoord + float3(texCoordOffset4, 0);
	float3 normalDirection4 = computeFragNormal(normalIn);



	float3 viewDirection = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
	float3 lightDirection;
	float attentuation;

	if (_WorldSpaceLightPos0.w == 0.0) {
		attentuation = LIGHT_ATTENUATION(input);
		lightDirection = normalize(_WorldSpaceLightPos0.xyz);
	}
	else
	{
		float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
		float distance = length(vertexToLightSource);
		attentuation = LIGHT_ATTENUATION(input);
		lightDirection = normalize(vertexToLightSource);
	}

	//no ambientLighting
	float3 ambientLighting = float3(0,0,0);

	lightInput lightIn;
	lightIn.attentuation = attentuation;
	lightIn.lightDirection = lightDirection;
	lightIn.viewDirection = viewDirection;

	lightIn.normalDirection = normalDirection1;
	float3 diffuseReflection1 = getDiffuseReflection(lightIn);
	float3 specularReflection1 = getSpecularReflection(lightIn);

	lightIn.normalDirection = normalDirection2;
	float3 diffuseReflection2 = getDiffuseReflection(lightIn);
	float3 specularReflection2 = getSpecularReflection(lightIn);

	lightIn.normalDirection = normalDirection3;
	float3 diffuseReflection3 = getDiffuseReflection(lightIn);
	float3 specularReflection3 = getSpecularReflection(lightIn);

	lightIn.normalDirection = normalDirection4;
	float3 diffuseReflection4 = getDiffuseReflection(lightIn);
	float3 specularReflection4 = getSpecularReflection(lightIn);



	float4 splatAlpha = normalize(tex2D(_MainTex, input.texCoord.xy));
	float sumAlpha = (dot(splatAlpha.rgb, float3(1, 1, 1)));
	splatAlpha.rgb = splatAlpha.rgb * (1 / sumAlpha);

	splatInput splatIn;
	splatIn.ambient = ambientLighting;

	splatIn.tex = _Texture1;
	splatIn.texST = _Texture1_ST;
	splatIn.texCoord = input.texCoord + float3(texCoordOffset1, 0);
	splatIn.diffuse = diffuseReflection1;
	splatIn.specular = specularReflection1;
	splatIn.alpha = splatAlpha.r;
	float3 color1 = getSplatColor(splatIn);

	splatIn.tex = _Texture2;
	splatIn.texST = _Texture2_ST;
	splatIn.texCoord = input.texCoord + float3(texCoordOffset2, 0);
	splatIn.diffuse = diffuseReflection2;
	splatIn.specular = specularReflection2;
	splatIn.alpha = splatAlpha.g;
	float3 color2 = getSplatColor(splatIn);

	splatIn.tex = _Texture3;
	splatIn.texST = _Texture3_ST;
	splatIn.texCoord = input.texCoord + float3(texCoordOffset3, 0);
	splatIn.diffuse = diffuseReflection3;
	splatIn.specular = specularReflection3;
	splatIn.alpha = splatAlpha.b;
	float3 color3 = getSplatColor(splatIn);

	splatIn.tex = _Texture4;
	splatIn.texST = _Texture4_ST;
	splatIn.texCoord = input.texCoord + float3(texCoordOffset4, 0);
	splatIn.diffuse = diffuseReflection4;
	splatIn.specular = specularReflection4;
	splatIn.alpha = splatAlpha.a;
	float3 color4 = getSplatColor(splatIn);

	splatBlendInput blendIn;

	blendIn.color1 = color1;
	blendIn.height1 = height1;
	blendIn.alpha1 = splatAlpha.r;

	blendIn.color2 = color2;
	blendIn.height2 = height2;
	blendIn.alpha2 = splatAlpha.g;

	blendIn.color3 = color3;
	blendIn.height3 = height3;
	blendIn.alpha3 = splatAlpha.b;

	blendIn.color4 = color4;
	blendIn.height4 = height4;
	blendIn.alpha4 = splatAlpha.a;


	float3 color = getBlendedColor(blendIn);

	return float4(color,0);
	}

		float4 fragWithAmbient(vertexOutput input) : COLOR
	{
		float4 color = fragWithoutAmbient(input);
		color += float4(getAmbientLighting(),0);
		return color;
	}

		ENDCG




		SubShader {
		Pass{
			Tags{ "LightMode" = "ForwardBase"
			"RenderType" = "Opaque" 
			}
			// pass for ambient light and first light source
			LOD 300

			Cull Off

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment fragWithAmbient
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma hull base
			#pragma domain domain
			#pragma target 5.0

			ENDCG

		}

			Pass{
			Tags{ "LightMode" = "ForwardAdd" }
			// pass for additional light sources
			Blend One One // additive blending 

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragWithoutAmbient

			ENDCG
		}
	}
	Fallback "Specular"

}
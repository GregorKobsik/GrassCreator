Shader "Instanced/GrassGeometryShader2" {
	Properties{
		_Tess("Tessellation", Range(1,32)) = 4
		_MainTex("Base (RGB)", 2D) = "white" {}
	_DispTex("Disp Texture", 2D) = "gray" {}
	_NormalMap("Normalmap", 2D) = "bump" {}

	_Displacement_z("Displacement_z", Range(-1, 1)) = 0.3
		_Displacement_x("Displacement_x", Range(-1, 1)) = 0.4

		_Width_X("Width X", Range(-0.07,0.1)) = 0
		_Width_Z("Width Z", Range(-0.07,0.1)) = 0

		_Height("Height", Range(0, 2)) = 1

		_Color("Color", color) = (1,1,1,0)
		_SpecColor("Spec color", color) = (0.5,0.5,0.5,0.5)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		// And generate the shadow pass with instancing support
		#pragma surface surf Standard fullforwardshadows vertex:disp tessellate:tessDistance addshadow nolightmap

		#pragma target 5.0
		#include "Tessellation.cginc"

		// Enable instancing for this shader
		//#pragma multi_compile_instancing

		// Config maxcount. See manual page.
		 #pragma instancing_options

		struct appdata {
		float4 vertex : POSITION;
		float4 tangent : TANGENT;
		float3 normal : NORMAL;
		float2 texcoord : TEXCOORD0;
	};

	float _Tess;

	float4 tessDistance(appdata v0, appdata v1, appdata v2) {
		float minDist = 1.0;
		float maxDist = 10.0;
		return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
	}

	float _Displacement_z;
	float _Displacement_x;
	float _Width_X;
	float _Width_Z;
	float _Height;

	void disp(inout appdata v)
	{
		v.vertex.x += v.texcoord.x * _Width_X;
		v.vertex.z += v.texcoord.x * _Width_Z;
		v.vertex.y += v.texcoord.y * _Height;

		float positionFactor = sin(v.texcoord.y);

		float transZ = (_Displacement_z)*positionFactor*v.texcoord.y - 0.3*(_Displacement_z)*positionFactor;
		float transX = (_Displacement_x)*positionFactor*v.texcoord.y - 0.3*_Displacement_x*positionFactor;
		float transY = -0.5*(abs(_Displacement_x) + abs(_Displacement_z))*positionFactor;

		float4x4 transformMatrix;
		transformMatrix[0] = float4(1, 0, 0, transX);
		transformMatrix[1] = float4(0, 1, 0, transY);
		transformMatrix[2] = float4(0, 0, 1, transZ);
		transformMatrix[3] = float4(0, 0, 0, 1);

		v.vertex.xyz = mul(transformMatrix, float4(v.vertex.xyz, 1)).xyz;

		v.tangent = mul(transformMatrix, v.tangent);

		float4x4 transformInverse;
		transformInverse[0] = float4(1, 0, 0, 0);
		transformInverse[1] = float4(0, 1, 0, 0);
		transformInverse[2] = float4(0, 0, 1, 0);
		transformInverse[3] = float4(transX, transY, transZ, 1);

		v.normal = mul(transformInverse, float4(v.normal, 1));

	}

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;

		// Declare instanced properties inside a cbuffer.
		// Each instanced property is an array of by default 500(D3D)/128(GL) elements. Since D3D and GL imposes a certain limitation
		// of 64KB and 16KB respectively on the size of a cubffer, the default array size thus allows two matrix arrays in one cbuffer.
		// Use maxcount option on #pragma instancing_options directive to specify array size other than default (divided by 4 when used
		// for GL).
		UNITY_INSTANCING_CBUFFER_START(Props)
			UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)	// Make _Color an instanced property (i.e. an array)
		UNITY_INSTANCING_CBUFFER_END

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * UNITY_ACCESS_INSTANCED_PROP(_Color);
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}

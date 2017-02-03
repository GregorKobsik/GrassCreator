
// This Shader is based on the Work done by Sean O'Neil. He came up with the
// idea to optimise the Approach from Nishita which used 2D-Lookup Tables by replacing
// these Lookup Tables with Equations which approximate the Values that were stored in these Tables.
// What Nishita basically did is precalculate the out-scattering value for each point P in the atmosphere
// where the x-Dimension represented the altitude of P and the y-Dimension represented the Angle to the Sun.
// Nishita thereby eliminated one of the hard to calculate Integrals in the Out-Scattering Equation.
// Sean O'Neils approach now approximates the x-Direction of the 2D Texture with exp(-4x). But the problem
// lies within the y-Direction. He came up with the idea to calculate a polynom which fits the values in the
// Table the best. This has the tramendous disadvantage, that if the properties of the planets atmosphere changes,
// the function needs to be recalculated. 
// I will use this precalculated Function called scale(float cos) because I was not able to figure out
// a polynom for our case. This means that I will also use an Atmosphere Size of 2.5% of the Skydomes Radius with 
// an average atmosphere density found at 25% height above the ground.
//
// Furthermore we assume that the camera is positioned on the ground (Or atleast not higher than 1 or 2 Units from Ground)
// This allows us to use the distance between the sample points as optical depth.
// The simulation is therfore not 100% accurate because the change of altitude does not have an impact
// on the calculation regarding the average density of the atmosphere.
Shader "Custom/SkyFromAtmosphereShader" {
	Properties{
		_CameraPosition("Camera Position",Vector) = (0,0,0,0)
		_LightDirection("Light Direction",Vector) = (0,0,0,0)
		_InvWaveLength("Inverse WaveLength",Color) = (0,0,0,0)
		_CameraHeight("Camera Height",Float) = 0
		_CameraHeight2("Camera Height2",Float) = 0
		_OuterRadius("Outer Radius",Float) = 0
		_InnerRadius("Inner Radius",Float) = 0
		_RayleighConstant("Rayleigh Scattering Constant", Float) = 0
		_MieConstant("Mie Scattering Constant", Float) = 0
		_ScaleDepth("Average Atmosphere Density Height",Float) = 0
		_NSamples("Samples",Float) = 0
		_SymmetryConstant("Symmetry Constant",Float) = 0

		_FewClouds("Texture for Few Clouds", 2D) = "white" {}
		_ManyClouds("Texture for Few Clouds", 2D) = "white" {}
		_LightDim("This will be our weather at some point", Float) = 1.0
		_GameTime("Time", Float) = 1.0
	}
		SubShader{
		Tags{ "Queue" = "Transparent"   "LightMode" = "ForwardBase" }

			Pass {

				ZWrite Off
				Cull Front
				Blend One One
	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		//#pragma enable_d3d11_debug_symbols
		#pragma target 5.0

		#include "UnityCG.cginc"
		#define M_PI 3.1415926535897932384626433832795

		uniform float4 _CameraPosition;	// 1 / pow(wavelength, 4) for the red, green, and blue channels
		uniform float4 _LightDirection;
		uniform float4 _InvWaveLength;
		uniform float _CameraHeight;
		uniform float _CameraHeight2;
		uniform float _OuterRadius;
		uniform float _InnerRadius;
		uniform float _RayleighConstant;
		uniform float _MieConstant;
		uniform float _SunBrightness;
		uniform float _ScaleDepth;
		uniform float _NSamples;
		uniform float _SymmetryConstant;

		// Simple CloudTextures
		// One for almost no clouds
		// And one for many clouds
		uniform sampler2D _FewClouds;
		uniform sampler2D _ManyClouds;

		// Lets the clouds fade out depending on day/night
		uniform float _CloudAlpha;
		// Dims the Light for a RainyMood and mixes the CloudTextures
		uniform float _LightDim;
		// Current GameTime slightly scaled to animate the clouds
		uniform float _GameTime;

		// The scale equation calculated by Sean O'Neil
		float scale(float fCos)
		{
			float x = 1.0 - fCos;

			return _ScaleDepth * exp(-0.00287 + x*(0.459 + x*(3.83 + x*(-6.80 + x*5.25))));
		}

		// Calculates the Rayleigh phase function
		//float getRayleighPhase(float fCos2)
		//{
		//	//return 1.0;
		//	return 0.75 + 0.75*fCos2;
		//}

		// Calculates the Mie phase function
		/*float getMiePhase(float fCos, float fCos2, float g, float g2)
		{
			return 1.5 * ((1.0 - g2) / (2.0 + g2)) * (1.0 + fCos2) / pow(1.0 + g2 - 2.0*g*fCos, 1.5);
		}*/

		// This is the Phase Function for both Ray and Mie Scattering
		// Normal Evaluation of this Function returns the Mie Scattering.
		// To get an approximation of the RayScattering set g=0
		float getPhaseForRayAndMieScattering(float cos, float g) 
		{
			float leftPart = (3.0 * (1.0 - g*g)) / (2.0 * (2 + g*g));
			float rightPart = (1 + cos*cos) / pow((1 + g*g - 2*g*cos),1.5);
			return leftPart * rightPart;
		}

		struct inputVertex {
			float4 vertex : POSITION;
		};

		struct inputFragment {
			float4 worldPos : SV_POSITION;
			float4 c0 : COLOR0;
			float4 c1 : COLOR1;
			float3 t0 : TEXCOORD0;
			float3 spherePos : TEXCOORD1;
		};

		inputFragment vert(inputVertex input) {

			// Position on our Sphere
			float3 v3Pos = mul(UNITY_MATRIX_M, input.vertex.xyz);

			// LightRay throug the Atmosphere
			float3 v3Ray = v3Pos - _CameraPosition.xyz;

			// Length of the LightRay
			float fFar = length(v3Ray);
			
			// Normalize the LightRay
			v3Ray = normalize(v3Ray);

			// Calculate the ray's starting position, then calculate its scattering offset

			// CameraPosition
			float3 v3Start = _CameraPosition.xyz;

			// CameraHeight?
			float fHeight = length(v3Start);

			// Optical Depth 
			float fStartAngle = dot(v3Ray, v3Start) / fHeight;
			float fStartOffset = scale(fStartAngle);

			// Initialize the scattering loop variables
			float fSampleLength = fFar / _NSamples;
			
			// SampleLength * _Scale
			float fScaledLength = fSampleLength * (1 / (_OuterRadius - _InnerRadius));
			float3 v3SampleRay = v3Ray * fSampleLength;
			float3 v3SamplePoint = v3Start + v3SampleRay;

			// Now loop through the sample rays
			float3 v3FrontColor = float3(0.0, 0.0, 0.0);
			for (int i = 0; i < _NSamples; i++)
			{
				float fHeight = length(v3SamplePoint);
				float fLightAngle = dot(_LightDirection.xyz, v3SamplePoint) / fHeight; // Light in WorldSPACE?
				float fCameraAngle = dot(v3Ray, v3SamplePoint) / fHeight;
				float fScatter = (fStartOffset + (scale(fLightAngle) - scale(fCameraAngle)));
				
				float rayleigh4PI = _RayleighConstant * M_PI * 4.0;
				float mie4PI = _MieConstant * M_PI * 4.0;

				float3 v3Attenuate = exp(-fScatter * (_InvWaveLength.xyz * rayleigh4PI + mie4PI));
				v3FrontColor += v3Attenuate * fScaledLength;
				v3SamplePoint += v3SampleRay;
			}

			inputFragment o;

			UNITY_INITIALIZE_OUTPUT(inputFragment, o);
			o.worldPos = mul(UNITY_MATRIX_MVP, input.vertex);
			o.c0.rgb = v3FrontColor * (_InvWaveLength.xyz * _RayleighConstant * _SunBrightness);
			o.c1.rgb = v3FrontColor * _MieConstant * _SunBrightness;
			o.t0 = _CameraPosition.xyz - v3Pos;
			o.spherePos = mul(UNITY_MATRIX_M, input.vertex);;

			return o;
		}

		float4 frag(inputFragment input) : COLOR{

			float cos = dot(_LightDirection.xyz, input.t0) / length(input.t0);
		//float cos2 = cos*cos;
		//float3 mixedColor = getRayleighPhase(fCos2) * input.c0 + getMiePhase(fCos, fCos2, _G, _G2) * input.c1;

		//float miePhase = 1.5 * ((1.0 - _G2) / (2.0 + _G2)) * (1.0 + cos2) / pow(1.0 + _G2 - 2.0*_G*cos, 1.5);
		//float rayleighPhase = 0.75 * (1.0 + cos2);

		//float4 fragColor = input.c0 * getRayleighPhase(cos2) + getMiePhase(cos, cos2, _G, _G2) * input.c1;

		//fragColor.a = 1;

			float4 scatteringColor = input.c0 * getPhaseForRayAndMieScattering(cos, 0) + getPhaseForRayAndMieScattering(cos, _SymmetryConstant) * input.c1;
			float4 finalColor = scatteringColor;

			// Draw the Clouds ontop of the calculated Light
			if (input.spherePos.y > _InnerRadius - 200) 
			{
				float uCloud = input.spherePos.x / 200;
				float vCloud = input.spherePos.z / 200;

				float3 cloudColor = _LightDim * float3(0.95, 0.95, 0.95);
				float fewClouds = tex2D(_FewClouds, float2(uCloud + _GameTime, vCloud)).x;
				float manyClouds = tex2D(_ManyClouds, float2(uCloud + _GameTime, vCloud)).x;
				float finalCloud = lerp(manyClouds, fewClouds, (_LightDim - 0.5)*2.0);

				finalColor = float4(lerp(_LightDim * scatteringColor.xyz, cloudColor, finalCloud * _CloudAlpha), 1);
			}

			return finalColor;
		}
		ENDCG
	}
	}
}

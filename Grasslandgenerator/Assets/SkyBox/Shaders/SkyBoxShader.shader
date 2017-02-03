Shader "Custom/SkyBoxShader" {
	Properties{
		_SkyWithSunTexture("Sky With Sun Texture", 2D) = "white" {}
		_SkyWithoutSunTexture("Sky Without Sun Texture", 2D) = "white" {}
		_SunTexture("Sun Texture", 2D) = "white" {}
		_CloudTexture("Cloud Texture", 2D) = "white" {}
		_LightDim("This will be our weather at some point", Float) = 1.0
		_GameTime("Time", Float) = 1.0 
		_SunSizeDay("Sunsize on Daylight", Float) = 0.05
		_SunSizeDawn("Sunsize on Dawn", Float) = 0.2
	}

	SubShader{
		Tags { "RenderType" = "Background" "Queue" = "Background"}

		Pass{

			Cull Off

			CGPROGRAM
			#pragma fragment frag
			#pragma vertex vert
			#pragma target 5.0

			#include "UnityCG.cginc"

			#define M_PI 3.1415926535897932384626433832795

			uniform sampler2D _SkyWithSunTexture;
			uniform sampler2D _SkyWithoutSunTexture;
			uniform sampler2D _SunTexture;
			uniform sampler2D _CloudTexture;
			uniform float _LightDim;
			uniform float _GameTime;
			uniform float _SkyBoxRadius;
			uniform float3 _SunPosition;
			uniform float _SunSizeDay;
			uniform float _SunSizeDawn;

			struct inputVertex {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct inputFragment {

				float4 worldPos : SV_POSITION;
				float4 pos : TEXCOORD1;
				float3 sunNormal : TEXCOORD2;
			};

			inputFragment vert(inputVertex input) {

				inputFragment o;
				o.worldPos = mul(UNITY_MATRIX_MVP, input.vertex);
				o.pos = mul(UNITY_MATRIX_M, input.vertex);
				o.sunNormal = normalize(_SunPosition);
				return o;
			}

			float3 frag(inputFragment input) : COLOR {

				float3 color;
				float3 posNormal = normalize(input.pos).xyz;

				// Calculate angle between the Sun and the position of the Vertex
				// We take this value to calculate the Color for the Sky depending
				// on the 2 Textures. One with Sun and one without the sun.
				float angle = dot(input.sunNormal, posNormal) * 0.5 + 0.5;

				// Calculate uv's
				float uSky = max(0.01, posNormal.y);
				float vSky = (input.sunNormal.y + 1.0) / 2.0;

				float4 colorWithSun = tex2D(_SkyWithSunTexture, float2(uSky, vSky));
				float4 colorWithoutSun = tex2D(_SkyWithoutSunTexture, float2(uSky, vSky));
				
				color = lerp(colorWithoutSun, colorWithSun, angle);

				// Dim the color according to the weather
				color = color * _LightDim;

				// I have no idea how this works yet. This is called Spherical Projection 
				// Found this solution on 
				// http://gamedev.stackexchange.com/questions/114412/how-to-get-uv-coordinates-for-sphere-cylindrical-projection
				float uCloud =  ( 0.5 + atan2(posNormal.x, posNormal.z) / (2*M_PI));
				float vCloud =  (-0.5 + asin(posNormal.y) / M_PI);
				
				// Calculate Cloudcolor dependend on Weather
				float3 cloudColor = _LightDim * float3(0.95, 0.95, 0.95);
				float cloud = tex2D(_CloudTexture, float2(uCloud + _GameTime, vCloud)).x;

				// Calculate the distance between the sun and the current position
				// if its smaller than our sunsize, draw the sun
				float radius = length(posNormal - input.sunNormal);
				float sunSize = clamp(-0.2*input.sunNormal.y + 0.15, _SunSizeDay, _SunSizeDawn);
				
				if (radius < sunSize && input.sunNormal.y > -0.2) {
				
					float uSun = radius / sunSize;
					float vSun = clamp(input.sunNormal.y, 0.00001, 1);
					float4 sunColor = tex2D(_SunTexture, float2(uSun, vSun));
					
					color = lerp(color, sunColor, sunColor.a);
				}

				// mix the final color including sun with the cloud color
				color = lerp(color, cloudColor, cloud);

				return color;;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}

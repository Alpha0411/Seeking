// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "GEffect/BH3"
{
	Properties
	{
		_MainTex ("Main", 2D) = "white" {}
		_LightMapTex ("LightMap", 2D) = "gray" {}
		//_BloomMaskTex ("BloomMask", 2D) = "white" {}
		
		_Color ("Color", Color) = (0.93,0.93,0.93,0.95)
		_LightArea ("LightArea", Range(0,1)) = 0.51
		_SecondShadow ("SecondShadow", Range(0,1)) = 0.51
		_FirstShadowMultColor ("FirstShadowMultColor", Color) = (.71,.67,.81,1)
		_SecondShadowMultColor ("SecondShadowMultColor", Color) = (.62,.53,.645,1)
		_Shininess ("Shininess", Range(0,10)) = 10
		_SpecMulti ("SpecMulti", Range(0,1)) = 0.2
		_LightSpecColor ("LightSpecColor", Color) = (1,1,1,1)
		_BloomFactor ("BloomFactor", Range(0,1)) = 1
		
		_Emission ("Emission", Range(0,5)) = 1
		_EmissionBloomFactor ("EmissionBloomFactor", Range(0,1)) = 1
		
		_OutlineColor ("OutlineColor", Color) = (0,0,0,1)
		_OutlineWidth ("OutlineWidth", Range(0,0.1)) = 0.05
		_MaxOutlineZOffset ("MaxOutlineZOffset", Range(0,1)) = 0
		_Scale ("Scale", Range(0,0.1)) = 0.01
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Name "FORWARD"
			Tags { "LIGHTMODE"="ForwardBase" "QUEUE"="Geometry" "SHADOWSUPPORT"="true" "RenderType"="Opaque" }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile __ _EMISSIVE_ALPHA
			//#define _EMISSIVE_ALPHA
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float4 uv : TEXCOORD0;
				half4 color : COLOR;
			};

			struct v2f
			{
				half4 oColor : COLOR;
				half2 uv : TEXCOORD0;
				half3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				half lum : TEXCOORD3;
				UNITY_FOG_COORDS(4)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _LightMapTex;
			//sampler2D _BloomMaskTex;
			//float4 _BloomMaskTex_ST;
			half4 _Color;
			float _LightArea;
			float _SecondShadow;
			half3 _FirstShadowMultColor;
			half3 _SecondShadowMultColor;
			float _Shininess;
			float _SpecMulti;
			half3 _LightSpecColor;
			float _BloomFactor;
			float _Emission;
			float _EmissionBloomFactor;
			
			v2f vert (appdata v)
			{
				v2f o = (v2f)0;
				o.oColor = v.color;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex );
				o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				half lum = dot(o.worldNormal,normalize(UnityWorldSpaceLightDir(o.worldPos)));
				o.lum = lum * 0.497500002 + 0.5;
				UNITY_TRANSFER_FOG(o,o.vertex);
				
				
			//half x = abs(dot(normalize(v.normal),normalize(v.tangent.xyz * v.tangent.w)));
			//	o.oColor = half4(x,x,x,1);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
			//return i.oColor;
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 illum = tex2D(_LightMapTex, i.uv);
				half lumOffset = i.oColor.x * illum.y;
				float xlat20 = lumOffset + 0.909999967;
				//xlat20 = floor(xlat20);
				//float xlat8 = max(xlat20,0.0);
				half lum = lumOffset + i.lum;
							
				lum = lum * 0.5 + (1 -_SecondShadow);
				//lum = floor(lum);
				//lum = max(lum, 0.0);
				
				half3 shadowColor = lerp(_FirstShadowMultColor.xyz, _SecondShadowMultColor, step(lum,1));
				
				lum = 1.5 -lumOffset;
				float2 lumoffset2 = lumOffset.xx * float2(1.20000005, 1.25) + float2(-0.100000001, -0.125);
				lumOffset = lerp(lumoffset2.x, lumoffset2.y, step(lum,1));
				lum = lumOffset + i.lum;
				lum = lum * 0.5 + 1 -_LightArea;
				half3 lightColor = lerp(1.0,_FirstShadowMultColor.xyz,step(lum,1));
				half3 color = lerp(lightColor,shadowColor,step(xlat20,1));
				color = color * col.rgb;
				
				half3 normalVec = normalize(i.worldNormal);
				half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
				half3 H = normalize(viewDir + _WorldSpaceLightPos0.xyz);
				half NdotH = dot(normalVec, H);
				NdotH = max(NdotH, 0.0);
				NdotH = log2(NdotH) * _Shininess;
				NdotH = exp2(NdotH);
				
				half spec = 2.0 - NdotH - illum.z;
				half3 specColor = _SpecMulti * _LightSpecColor * illum.x;
				specColor = specColor * step(spec, 1);
				color += specColor;
				color *= _LightColor0.xyz;
				
				
				half bloomFactor = _Color.w * _BloomFactor;
				#ifdef _EMISSIVE_ALPHA
					half3 emisColor = col.rgb * _Emission - color;
					color = emisColor * col.a + color;
					bloomFactor = lerp(bloomFactor,_EmissionBloomFactor,col.a);
				#endif
				
		
				UNITY_APPLY_FOG(i.fogCoord, color);
				return fixed4(color,1);
			}
			ENDCG
		}
		Pass
		{
			Name "OUTLINE"
			Tags {"QUEUE"="Geometry + 1" "RenderType"="Opaque" }
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 tangent : NORMAL; 
				float4 normal : NORMAL; 
				fixed4 color : COLOR;
			};

			struct v2f
			{
				half4 oColor : COLOR;
				
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			half _OutlineWidth;
			half4 _OutlineColor;
			half _MaxOutlineZOffset;
			half _Scale;
			half4 _Color;
			
			v2f vert (appdata v)
			{
				v2f o = (v2f)0;
				o.oColor = fixed4(_OutlineColor.xyz,1.0);
				float3 scaledir = mul((float3x3)UNITY_MATRIX_MV,normalize(v.tangent.xyz) * v.tangent.w);
				scaledir += 0.5;
				scaledir.z = 0.01;
				scaledir = normalize(scaledir);
				
				float4 position_cs = mul(UNITY_MATRIX_MV,v.vertex);
				position_cs /= position_cs.w;
				
				float3 viewDir = normalize(position_cs.xyz);
				float3 offset_pos_cs = position_cs.xyz + viewDir * _MaxOutlineZOffset * _Scale * (v.color.z - 0.5);
				
				float linewidth = -position_cs.z / (unity_CameraProjection[1].y * _Scale);
				linewidth = sqrt(linewidth) * _OutlineWidth * _Scale * v.color.w;
				position_cs.xy = offset_pos_cs.xy + scaledir.xy * linewidth;
				position_cs.z = offset_pos_cs.z;
				
				o.vertex = mul(UNITY_MATRIX_P,position_cs);
				
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(i.oColor.rgb * _LightColor0.rgb,1.0);
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "GBH3ShaderGUI"
}

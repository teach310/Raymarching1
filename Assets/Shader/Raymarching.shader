Shader "Raymarching/Test"
{
	Properties
	{
		//_MainTex("Main Texture", 2D) = ""{}
		_Color("Main Color", COLOR) = (1,1,1,1)
		_Scale("Scale", float) = 2.0
		_Scale2("Scale2", float) = 1.0
	}
	SubShader
	{
		//study DisableBathing
		Tags { "RenderType"="Opaque" "DisableBatching" = "True" "Queue" = "Geometry+10"}
		Cull Off

		CGINCLUDE
		#include "UnityCG.cginc"

		uniform float _Scale;
		uniform float _Scale2;




		float sphere(float3 pos, float radius)
		{
			return length(pos) - radius;
		}

		float roundBox(float3 pos, float3 size, float round)
		{
			return length(max(abs(pos) - size * 0.5, 0.0)) - round;
		}

		//四角形 sizeのxyzがそれぞれ四角形のxyzの長さになる．
		float sdBox(float3 pos, float3 size)
		{
			float3 d = abs(pos) - size;
			return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
		}

		//Union
		float opU(float d1, float d2)
		{
			return min(d1, d2);
		}

		// Substraction 失敗
		float opS(float d1, float d2)
		{
			return max(-d1, d2);
		}

		// Intersection 失敗
		float opI(float d1, float d2)
		{
			return max(d1, d2);
		}

		// 十字
		float crossShape(float3 pos, float len, float thick){
			return opU(sdBox(pos, float3(len, thick, thick)), sdBox(pos, float3(thick, len, thick)));
		}


		// 3次元十字

		float sdCross(float3 pos,float len,float thick)
		{
			float da = sdBox(pos, float3(len, thick, thick));
			float db = sdBox(pos, float3(thick, len, thick));
			float dc = sdBox(pos, float3(thick, thick, len));
			return min(da, min(db, dc));
		}

		// 失敗
		float map(float3 pos)
		{
			float d = sdBox(pos, float3(2.0, 2.0, 2.0));
			float c = sdCross(pos, 3, 1);
			//return opU(d,c);
			return opS(c, d);
		}

		float3 mod(float3 a, float3 b)
		{
			return frac(abs(a / b)) * abs(b);
		}

		// 繰り返し
		float3 repeat(float3 pos, float3 span)
		{
			return mod(pos, span) - span * 0.5;
		}

		float opScale(float3 pos, float scale)
		{
			//Box
			//return sdBox(pos/scale, float3(1.0, 1.0, 1.0))*scale;
			//roundBox
			return roundBox(pos/scale, 1,1) * scale;
		}

		float opScale2(float3 pos, float scale)
		{
			//Box
			//return sdBox(pos/scale, float3(1.0, 1.0, 1.0))*scale;
			//roundBox
			return opS(opScale(pos/scale, _Scale), roundBox(pos/scale, 1, 0.5)) * scale;
		}

		float RecursiveTetrahedron(float3 p)
		{
			p = repeat(p / 2, 3.0);
			//p = repeat(p / 2, _Span);
			const float3 a1 = float3(1.0, 1.0, 1.0);
			const float3 a2 = float3(-1.0, -1.0, 1.0);
			const float3 a3 = float3(1.0, -1.0, -1.0);
			const float3 a4 = float3(-1.0, 1.0, -1.0);

			const float scale = 2.0f;
			//const float scale = _Scale;
			float d;
			for(int n = 0; n < 20; n++){
				float3 c = a1;
				float minDist = length(p - a1);
				d = length(p - a2); if(d < minDist) {c = a2; minDist = d;}
				d = length(p - a3); if(d < minDist) {c = a3; minDist = d;}
				d = length(p - a4); if(d < minDist) {c = a4; minDist = d;}
				p = scale * p - c * (scale - 1.0);
			}

			return length(p) * pow(scale, float(-n));
		}

		//sphere tracing
		float DistanceFunc(float3 pos)
		{
			return sphere(pos, 1.0f);
			//return roundBox(pos - float3(1, 0, 0), 1, 1); 
			//return sdBox(pos, float3(1,0.5, 0.5)); 
			//return crossShape(pos, 3, 1);
			//return sdCross(pos, 3, 1);
			//return map(pos);
			//return opScale(pos, _Scale);
			return RecursiveTetrahedron(pos); 
			//return roundBox(repeat(pos, 2.0f), 1.0f, 0.2f);
			//return opU(sphere(pos, 1.0), sphere(pos - 0.5, 1.0));
			//return opS(sphere(pos - float3(1,0,0), 1.0), sphere(pos, 1.0));
			//return opI(sphere(pos - float3(1,0,0), 1.0), sphere(pos, 1.0));
			//四角形 - 角丸四角
			//return opScale2(pos, _Scale2);

		}

		//study それぞれ
		float3 GetCameraPosition()	 { return _WorldSpaceCameraPos;		}
		float3 GetCameraForward()	 { return -UNITY_MATRIX_V[2].xyz;	}
		float3 GetCameraUp()		 { return UNITY_MATRIX_V[1].xyz;	}
		float3 GetCameraRight()		 { return UNITY_MATRIX_V[0].xyz;	}
		float  GetCameraFocalLength(){ return abs(UNITY_MATRIX_P[1][1]);}
		float  GetCameraMaxDistance(){ return _ProjectionParams.z - _ProjectionParams.y;}

		// Raymarchingの結果得られたワールド空間での位置にView-Projection行列をかけ，カメラから見た座標へと変換する
		float GetDepth(float3 pos)
		{
			float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
		#if defined(SHADER_TARGET_GLSL)
			return(vpPos.z / vpPos.w) * 0.5 + 0.5;
		#else
			return vpPos.z / vpPos.w;
		#endif
		}

		// 偏微分
		float3 GetNormal(float3 pos)
		{
			const float d = 0.001;
			return 0.5 + 0.5 * normalize(float3(
				DistanceFunc(pos + float3(  d, 0.0, 0.0)) - DistanceFunc(pos + float3( -d, 0.0, 0.0)),
				DistanceFunc(pos + float3(0.0,   d, 0.0)) - DistanceFunc(pos + float3(0.0,  -d, 0.0)),
				DistanceFunc(pos + float3(0.0, 0.0,   d)) - DistanceFunc(pos + float3(0.0, 0.0,  -d))));
		}
		ENDCG

		Pass
		{
			Tags{"LifhtMode" = "Deferred"}

			Stencil
			{
				Comp Always
				Pass Replace
				Ref 128
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile ___ Unity_HDR_ON
			
			#include "UnityCG.cginc"
			//uniform sampler2D _MainTex;
			uniform fixed4 _Color;
			struct VertInput
			{
				float4 vertex : POSITION;
			};

			struct VertOutput
			{
				float4 vertex		: SV_POSITION;
				float4 screenPos	: TEXCOORD0;
			};

			struct GBufferOut
			{
				half4 diffuse	: SV_Target0; // rgb: diffuse,  a: occlusion
				half4 specular	: SV_Target1; // rgb: specular, a: smoothness
				half4 normal	: SV_Target2; // rgb: normal,   a: unused
				half4 emission	: SV_Target3; // rgb: emission, a: unused
				float depth		: SV_Depth;
			};

			VertOutput vert(VertInput v)
			{
				VertOutput o;
				o.vertex = v.vertex;
				o.screenPos = o.vertex;
				return o;
			}

			GBufferOut frag(VertOutput i)
			{

			//カメラの方向い対してレイを伸ばしている

				float4 screenPos = i.screenPos;
#if UNITY_UV_STARTS_AT_TOP
				screenPos.y *= -1.0;
#endif
				screenPos.x *= _ScreenParams.x / _ScreenParams.y;
				float3 camPos	= GetCameraPosition();
				float3 camDir	= GetCameraForward();
				float3 camUp	= GetCameraUp();
				float3 camSide	= GetCameraRight();
				float focalLen	= GetCameraFocalLength();
				float maxDistance = GetCameraMaxDistance();

				float3 rayDir = normalize(
					camSide * screenPos.x +
					camUp	* screenPos.y +
					camDir	* focalLen);


			// Raymarchingのループ
				float distance = 0.0;
				float len = 0.0;
				float3 pos = camPos + _ProjectionParams.y * rayDir;
				for(int i = 0;i<50;i++){
					distance = DistanceFunc(pos);
					len += distance;
					pos += rayDir * distance;
					if(distance < 0.001 || len > maxDistance) break;
				}

				if(distance > 0.001) discard;

				float depth = GetDepth(pos);
				float3 normal = GetNormal(pos);

				//study
				//float u = (1.0 - floor(fmod(pos.x, 2.0))) * 5;
				//float v = (1.0 - floor(fmod(pos.y, 2.0))) * 5;

				GBufferOut o;
				o.diffuse	= float4(1.0, 1.0, 1.0, 1.0);
				o.specular	= float4(0.5, 0.5, 0.5, 1.0);
				//o.emission 	= float4(0.3, 0.5, 0.5, 0.0) * 3;
				o.emission = (1 - _Color) * 3;
				o.depth	=depth;
				o.normal = float4(normal, 1.0);

#ifndef UNITY_HDR_ON
				o.emission = exp2(-o.emission);
				//o.emission = exp(o.emission);
#endif

				return o;
			}

			ENDCG
		}
	}
	Fallback Off
}

Shader "Raymarching/Test"
{
	Properties
	{
		//_MainTex("Main Texture", 2D) = ""{}
		_Color("Main Color", COLOR) = (1,1,1,1)
		_Value("Value", float) = 1.0
	}
	SubShader
	{
		//study DisableBathing
		Tags { "RenderType"="Opaque" "DisableBatching" = "True" "Queue" = "Geometry+10"}
		Cull Off

		CGINCLUDE
		#include "UnityCG.cginc"
		#include "Primitives.cginc"
		

		uniform float _Value;
		

		//sphere tracing
		float DistanceFunc(float3 pos)
		{
			//球体
			//return sphere(pos, 0.25);

			//繰り返し 球体
			//float3 repeatPos = repeat(pos, float3(_Value, _Value, _Value));
			//return sphere(repeatPos, 0.25);

			//中心からの繰り返し
			//float3 repeatPos = repeat2(pos, float3(2.0, 2.0, 2.0));
			//float3 r = 1.0 - abs(repeatPos);
			//return sphere(r, 0.1);

			//中心からの繰り返し　スケーリング
			//float scale = 1;
			//float3 repeatPos = repeat(pos*scale, float3(2.0, 2.0, 2.0));
			//float3 r = 1.0 - abs(repeatPos);
			//return sdBox(r, float3(_Value, _Value, _Value))/scale;
			
			// 繰り返し　立方体
			//float3 repeatPos = repeat(pos, float3(3.0, 3.0, 3.0));
			//return sdBox(repeatPos, float3(0.5, 0.5, 0.5));

			// 複製十字
			//float3 repeatPos = repeat(pos, float3(3.0, 3.0, 3.0));
			//return sdCross(repeatPos, 100, 0.1);

			// 十字空きBox -----
			//float d = sdBox(pos, float3(2.0, 2.0, 2.0));
			//float c = sdCross(pos, 3, 1);
			//return opS(c, d);
			//---------------------
			

			//Menger Sponge
			float holeDistanceRate = 2.0;  //最初穴と穴の距離は1/2
			float holeScaleRate = 3.0;
			float sr = holeScaleRate / holeDistanceRate; // srは一定
			float scale = 1.0 * holeDistanceRate;
			float d = sdBox(pos, float3(0.5, 0.5, 0.5));
			for (int i = 0; i < 4; i++)
			{
				//span2.0で真ん中から繰り返す。　scale分全体の大きさが変化する。
				float3 repeatPos = repeat(pos * scale, float3(2.0, 2.0, 2.0));
				float3 r = 1.0 - abs(repeatPos);
				float cross = sdCross(r * sr, 100, 0.5) /(scale*sr);
				d = opS(cross, d);
				scale *= 3.0; //穴と穴の距離と、穴の大きさは1/3になる。
			}
			return d;
			
			

			//return roundBox(pos - float3(1, 0, 0), 1, 1); 
			//return sdBox(pos, float3(1,0.5, 0.5)); 
			//return crossShape(pos, 3, 1);
			//return sdCross(pos, 3, 1);
			//return map(pos);
			//return opScale(pos, _Scale);
			//return RecursiveTetrahedron(pos); 
			//return roundBox(repeat(pos, 2.0f), 1.0f, 0.2f);
			//return opU(sphere(pos, 1.0), sphere(pos - 0.5, 1.0));
			//return opS(sphere(pos - float3(1,0,0), 1.0), sphere(pos, 1.0));
			//return opI(sphere(pos - float3(1,0,0), 1.0), sphere(pos, 1.0));

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
			#include "Raymarching.cginc"

			//uniform sampler2D _MainTex;
			uniform fixed4 _Color;
			
			

			GBufferOut frag(VertOutput i)
			{
				float3 rayDir = GetRayDirection(i.screenPos);
				float3 camPos = GetCameraPosition();
				float maxDist = GetCameraMaxDistance();


			// Raymarchingのループ
				float distance = 0.0;
				float len = 0.0;
				float3 pos = camPos + _ProjectionParams.y * rayDir;
				for(int i = 0;i<50;i++){
					distance = DistanceFunc(pos);
					len += distance;
					pos += rayDir * distance;
					if(distance < 0.001 || len > maxDist) break;
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

#ifndef primitives_h
#define primitives_h

#include "Foundation.cginc"

float sphere(float3 pos, float radius)
{
	//float3 q = frac(pos) *2.0 - 1.0;
	//float3 q = repeat(pos, float3(2.0, 2.0, 2.0));
	return length(pos) - radius;
}


float roundBox(float3 pos, float3 size, float round)
{
	return length(max(abs(pos) - size * 0.5, 0.0)) - round;
}

float box(float3 pos, float3 size)
{
	return roundBox(pos, size, 0);
}

float torus(float3 pos, float2 radius)
{
	float2 r = float2(length(pos.xy) - radius.x, pos.z);
	return length(r) - radius.y;
}

float floor(float3 pos)
{
	return dot(pos, float3(0.0, 1.0, 0.0)) + 1.0;
}

float cylinder(float3 pos, float2 r) {
	float2 d = abs(float2(length(pos.xy), pos.z)) - r;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - 0.1;
}

//四角形 sizeのxyzがそれぞれ四角形のxyzの半分の長さになる．
// size 0.5 なら　-0.5 to 0.5 で　長さは1
float sdBox(float3 pos, float3 size)
{
	float3 d = abs(pos) - size;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// 十字
float crossShape(float3 pos, float len, float thick) {
	return opU(sdBox(pos, float3(len, thick, thick)), sdBox(pos, float3(thick, len, thick)));
}


// 3次元十字

float sdCross(float3 pos, float len, float thick)
{
	float da = sdBox(pos, float3(len, thick, thick));
	float db = sdBox(pos, float3(thick, len, thick));
	float dc = sdBox(pos, float3(thick, thick, len));
	return min(da, min(db, dc));
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
	for (int n = 0; n < 20; n++) {
		float3 c = a1;
		float minDist = length(p - a1);
		d = length(p - a2); if (d < minDist) { c = a2; minDist = d; }
		d = length(p - a3); if (d < minDist) { c = a3; minDist = d; }
		d = length(p - a4); if (d < minDist) { c = a4; minDist = d; }
		p = scale * p - c * (scale - 1.0);
	}

	return length(p) * pow(scale, float(-n));
}

#endif
#ifndef foundation_h
#define foundation_h

float3 mod(float3 a, float3 b)
{
	//return frac(abs(a / b)) * abs(b);
	return a - b*floor(a / b);
}

// 繰り返し
float3 repeat(float3 pos, float3 span)
{
	return mod(pos, span) - span * 0.5;
}


//Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}

// Substraction
float opS(float d1, float d2)
{
	return max(-d1, d2);
}

// Intersection
float opI(float d1, float d2)
{
	return max(d1, d2);
}

//float opScale(float3 pos, float scale)
//{
//	//Box
//	//return sdBox(pos/scale, float3(1.0, 1.0, 1.0))*scale;
//	//roundBox
//	return roundBox(pos / scale, 1, 1) * scale;
//}

#endif
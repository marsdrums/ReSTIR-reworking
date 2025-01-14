//================================================================================
// 32-bits Octahedral normal packing from: https://www.shadertoy.com/view/llfcRl
vec2 msign( vec2 v )
{
    return vec2( (v.x>=0.0) ? 1.0 : -1.0, 
                 (v.y>=0.0) ? 1.0 : -1.0 );
}

float encode_octahedral_32( in vec3 nor )
{
    nor.xy /= ( abs( nor.x ) + abs( nor.y ) + abs( nor.z ) );
    nor.xy  = (nor.z >= 0.0) ? nor.xy : (1.0-abs(nor.yx))*msign(nor.xy);
    uvec2 d = uvec2(round(32767.5 + nor.xy*32767.5));  
    return uintBitsToFloat(d.x|(d.y<<16u));
}
vec3 decode_octahedral_32( in float f )
{
    uint data = floatBitsToUint(f);
    uvec2 iv = uvec2( data, data>>16u ) & 65535u; 
    vec2 v = vec2(iv)/32767.5 - 1.0;
    vec3 nor = vec3(v, 1.0 - abs(v.x) - abs(v.y)); // Rune Stubbe's version,
    float t = max(-nor.z,0.0);                     // much faster than original
    nor.x += (nor.x>0.0)?-t:t;                     // implementation of this
    nor.y += (nor.y>0.0)?-t:t;                     // technique
    return normalize( nor );
}
//================================================================================
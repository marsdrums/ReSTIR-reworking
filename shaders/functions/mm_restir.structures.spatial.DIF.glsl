in jit_PerVertex {
	smooth vec2 uv;
} jit_in;

uniform sampler2DRect colTex, norDepthTex, posTex, reservoirTex, p_hatTex, albTex, stbn_uvec2Tex, occTex;
uniform samplerCube environmentMap;
uniform int frame, num_samples;
uniform vec2 texDim, mapSize;
uniform mat4 prevMVP, invV, MV, MVP, VP, V, projmat, textureMatrix0;
uniform float farClip, radius;
uniform vec3 eye;

struct sample{
	vec3 col;
	vec3 nor;
	vec3 pos;
	float depth;
	float index;
	vec2 uv;
	//vec2 vel;
	vec3 alb;
	float id;
};
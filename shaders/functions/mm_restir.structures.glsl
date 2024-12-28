uniform sampler2DRect colTex, norDepthTex, velTex, posTex, prev_reservoirTex, prev_best_wposTex, albTex, environmentMap;
uniform int frame;
uniform vec2 texDim, mapSize;
uniform mat4 prevMVP, invV, MV, MVP, VP, V, projmat, textureMatrix0;
uniform float farClip;
uniform vec3 eye;
uniform int num_samples;

in jit_PerVertex {
	smooth vec2 uv;
	smooth vec3 dir;
} jit_in;

struct sample{
	vec3 col;
	vec3 nor;
	vec3 pos;
	float depth;
	float index;
	vec2 uv;
	vec2 vel;
	vec3 alb;
	float id;
	vec3 ref;
	vec3 view;
};
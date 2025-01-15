uniform sampler2DRect colTex, norDepthTex, velTex, posTex, prev_reservoirTex, prev_best_wposTex, albTex, roughMetalTex, depthsTex, prevPosTex, noiseTex;
uniform samplerCube environmentMap;
uniform int frame;
uniform vec2 texDim, mapSize;
uniform mat4 prevMVP, invV, MV, MVP, VP, V, projmat, textureMatrix0;
uniform float nearClip, farClip;
uniform vec3 eye;

in jit_PerVertex {
	smooth vec2 uv;
	smooth vec3 dir;
	flat vec3 U;
	flat vec3 D;
	flat vec3 L;
	flat vec3 R;
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
	float rou;
	float met;
};
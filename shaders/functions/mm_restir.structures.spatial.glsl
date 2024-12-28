in jit_PerVertex {
	smooth vec2 uv;
	smooth vec3 dir;
	flat vec4 plane_near;
	flat vec4 plane_far;
	flat vec4 plane_left;
	flat vec4 plane_right;
	flat vec4 plane_top;
	flat vec4 plane_bottom;
} jit_in;

uniform sampler2DRect colTex, norDepthTex, velTex, posTex, reservoirTex, p_hatTex, albTex, roughMetalTex, stbn_uvec2Tex;
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
	vec2 vel;
	vec3 alb;
	float id;
	vec3 ref;
	vec3 view;
	float rou;
	float met;
};

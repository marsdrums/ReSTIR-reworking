/*
float get_exit_distance(vec2 pos, vec2 dir){

	vec2 dist = vec2(9999999.0, 99999999.0);

    //Calculate the distance to each of the four boundaries
    if(dir.x > 0) dist.x = (texDim.x - pos.x) / dir.x;
    if(dir.x < 0) dist.x = -pos.x / dir.x;

    if(dir.y > 0) dist.y = (texDim.y - pos.y) / dir.y;
    if(dir.y < 0) dist.y = -pos.y / dir.y;

    //The minimum positive distance is the one at which the ray exits the screen
    return min(dist.x, dist.y);
}
*/

vec2 cartesianToUv(vec3 cartesian) {
    float theta = atan(cartesian.y, cartesian.x)/M_TAU; // azimuthal angle
    float phi = acos(cartesian.z)/M_PI; // polar angle
    return vec2(theta, phi);
}

/*
vec2 get_sample_uv_for_env(inout uint seed, in vec3 ref){

	vec3 rand_dir = normalize(ref + randomUnitVector3(seed)*this_s.rou);
	//rand_dir *= dot(rand_dir, nor) > 0.0 ? 1 : -1;
	vec2 uv = vec2(atan(rand_dir.z, rand_dir.x), asin(rand_dir.y));
    uv *= vec2(-1/(2*M_PI), 1/M_PI); //to invert atan
    uv += 0.5;
    uv *= mapSize;
    return uv;
	//return vec2(RandomFloat01(seed), RandomFloat01(seed))*mapSize;
	//vec3 wNor = (invV * vec4(nor,0)).xyz;
	//vec2 center = cartesianToUv(wNor) + 2;
	//vec2 randOffset = 0.5*(vec2(RandomFloat01(seed)-0.5, RandomFloat01(seed))-0.5);
	//return vec2(RandomFloat01(seed), RandomFloat01(seed))*mapSize;//mod(center + randOffset, vec2(1.0))*mapSize;
}
*/
bool valid_uv(in vec2 uv){
	return uv.x >= 0 && uv.y >= 0 && uv.x < texDim.x && uv.y < texDim.y;
}

int uv2index(in vec2 uv){
	//uv -= 0.5;
	uv = floor(uv);
	return int(uv.x + uv.y*texDim.x);
}

int uv2index_for_env(in vec2 uv){
	uv = floor(uv);
	return -int(uv.x + uv.y*mapSize.x); //negate the index to distinguish it from viewport samples
}

vec2 index2uv(in int i){
	return vec2( mod( float(i), texDim.x ), floor( float(i) / texDim.x ) ) + 0.5;
}

vec2 index2uv_for_env(in int i){
	return vec2( mod( float(-i), mapSize.x ), floor( float(-i) / mapSize.x ) )+0.5;
}

float luminance(vec3 x){
	//return dot(x, vec3(0.299, 0.587, 0.114));
	return length(x);
}

vec3 uv2dir(in vec2 uv){

	uv /= mapSize;

    // Convert the normalized UV coordinates to the range [-1, 1]
    float u = uv.x * 2.0 - 1.0;
    float v = uv.y * 2.0 - 1.0;

    // Calculate the longitude and latitude angles
    float longitude = u * M_PI;          // Longitude (-π to π)
    float latitude = v * M_PI * 0.5;     // Latitude (-π/2 to π/2)

    // Convert spherical coordinates to Cartesian coordinates
    float cos_latitude = cos(latitude);
    float x = cos_latitude * sin(longitude);
    float y = sin(latitude);
    float z = cos_latitude * cos(longitude);

    vec3 dir = vec3(x, y, z);
    return (V * vec4(dir, 0)).xyz;
}

sample get_sample_pos_col(int index){

	sample s;
	vec2 uv = index2uv(index);
	ivec2 iuv = ivec2(uv);
	vec4 lookup0 = texelFetch(colTex, iuv);
	vec4 lookup3 = texelFetch(posTex, iuv);

	s.col = lookup0.rgb;
	s.pos = lookup3.xyz;
	return s;
}

sample get_sample_pos_col_from_uv(vec2 uv){

	sample s;
	ivec2 iuv = ivec2(uv);
	vec4 lookup0 = texelFetch(colTex, iuv);
	vec4 lookup3 = texelFetch(posTex, iuv);

	s.col = lookup0.rgb;
	s.pos = lookup3.xyz;
	return s;
}
/*
sample get_sample_dir_col_for_env_jittered(int index, inout uint seed){

	sample s;
	s.uv = index2uv_for_env(index);
	ivec2 iuv = ivec2(s.uv);
	vec2 jitter_uv = s.uv;// + 2*vec2(RandomFloat01(seed)-0.5, RandomFloat01(seed)-0.5);
	s.col = texture(environmentMap, jitter_uv).rgb;
	s.nor = uv2dir(jitter_uv);
	s.pos = s.nor; //use the position variable to pass the direction for reprojection
	return s;
}
*/

sample get_environment_sample(in vec3 candidate_dir, inout uint seed, in float rou){
	sample s;
	s.col = textureLod(environmentMap, (invV * vec4(candidate_dir, 0)).xyz, rou*4).rgb;
	//s.col = textureLod(environmentMap, (invV * vec4(candidate_dir, 0)).xyz, 0.0).rgb;
	s.nor = candidate_dir;
	//s.pos = s.nor;
	return s;
}


//PBR functions
float saturate(in float x){ return clamp(x, 0.0, 1.0); }

vec3 simpleFresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (vec3(1.0) - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 	fresnelSchlickRoughness(float HdotV, vec3 F0, float rou){
	float 	x = saturate(1. - HdotV); //x^5
	float 	x2 = x*x;
			x2 *= x2;
			x *= x2;
    return F0 + (max(vec3(1.0 - rou), F0) - F0) * x;
} 
float 	DistributionGGX(float NdotH, float rou){

			rou *= rou; //Disney trick!
			rou *= rou; //roughness^4
     		NdotH *= NdotH; //square the dot product
    float 	denom = (NdotH * (rou - 1.0) + 1.0);
	
    return 	rou / (denom*denom*M_PI);
}
float 	GeometrySchlickGGX(float NdotV, float rou){
			rou += 1.;
    float 	k = (rou*rou) / 8.0; //Disney trick again...
    return NdotV / ( NdotV * (1.0 - k) + k );
}
float 	GeometrySmith(float NdotV, float NdotL, float rou){
    float ggx2  = GeometrySchlickGGX(NdotV, rou);
    float ggx1  = GeometrySchlickGGX(NdotL, rou);
	
    return ggx1 * ggx2;
} 

float Schlick_GGX(float cosine, float rou){
	float alpha = rou*rou;
    float k = rou * 0.5;
    return max(0.001, cosine) / ( cosine * (1.0 - k) + k );
}
float G_Smith(float NoV, float NoL, float rou){
    float ggx2  = Schlick_GGX(NoV, rou);
    float ggx1  = Schlick_GGX(NoL, rou);
    return ggx1 * ggx2;
} 

float D_GGX(float NoH, float rou){

	float alpha = rou*rou;
	float alpha2 = alpha*alpha;
	float NoH2 = NoH*NoH;
	float b = (NoH2 * (alpha2 - 1.0) + 1.0);	
	return alpha2 * (1/M_PI) / (b*b); //adding one to normalize the BRDF
}

// Like the GGX NDF, but scaled to peak at 1.0. Never _quite_ reaches zero.
float ggx_ndf_0_1(float cos_theta, float rou) {
		float alpha = rou*rou;
		float alpha2 = alpha*alpha;
    	float denom_sqrt = cos_theta * cos_theta * (alpha2 - 1.0) + 1.0;
    	return alpha2 * alpha2 / (denom_sqrt * denom_sqrt);
}

float ggx_ndf(float a2, float cos_theta) {
		float denom_sqrt = cos_theta * cos_theta * (a2 - 1.0) + 1.0;
		return a2 / (M_PI * denom_sqrt * denom_sqrt);
	}


float pdf_ggx(float a2, float cos_theta) {
		return ggx_ndf(a2, cos_theta) * cos_theta;
}

vec3 F_schlick(float HoV, vec3 F0){
	
	float x = clamp(1. - HoV,0,1); 
	float x2 = x*x;
	x2 *= x2; 
    return F0 + (vec3(1.0) - F0) * x * x2;
}

float D_GTR(float roughness, float NoH, float k) {
    float a2 = roughness*roughness;
    return a2 / (M_PI * pow((NoH*NoH)*(a2*a2-1.)+1., k));
}

float SmithG(float NoV, float roughness2)
{
    float a = roughness2*roughness2;
    float b = NoV*NoV;
    return (2.*NoV) / (NoV+sqrt(a + b - a * b));
}

float GGXVNDFPdf(float NoH, float NoV, float roughness)
{
 	float D = D_GTR(roughness, NoH, 2.);
    float G1 = SmithG(NoV, roughness*roughness);
    return (D * G1) / max(0.00001, 4.0f * NoV);
}
/*
vec3 get_specular_radiance(in sample this_s, in sample test_s){


	vec3 diff = test_s.pos - this_s.pos;
	float dist2 = dot(diff,diff);
	float dist = sqrt(dist2);

	vec3 F0 = mix(vec3(0.04), this_s.alb, vec3(this_s.met)); 

  	vec3 L = diff / dist;
 	vec3 V = -this_s.view;
	vec3 H = normalize(V + L); 

	float NoV = clamp(dot(this_s.nor, V), 0.001, 1.0);
	float NoL = clamp(dot(this_s.nor, L), 0.001, 1.0);

	float NoH = clamp(dot(this_s.nor, H), 0.001, 1.0);
	float HoV = clamp(dot(H, V), 0.001, 1.0);

	float G = G_Smith(NoV, NoL, this_s.rou);
	
	float D = D_GGX(NoH, this_s.rou);
	//float divisor = D_GGX(1, this_s.rou);
	
	//float D = ggx_ndf_0_1(NoH, this_s.rou);
	

	vec3 F = F_schlick(HoV, F0);

	vec3 spe = (F * D * G) / ( max(0.001, NoV) * max(0.001, NoL) * 4.0);


	//calc PDF (from https://www.shadertoy.com/view/Dtl3WS)
	float PDF = GGXVNDFPdf(NoH, NoV, this_s.rou);

	//return 0.3*spe*test_s.col / (PDF*this_s.rou*this_s.rou);
	return spe*test_s.col/PDF;
	//return spe*test_s.col;

	//return test_s.col*spe*(this_s.rou);

}
*/
vec3 get_specular_radiance(in sample this_s, in sample test_s){

	vec3 diff = test_s.pos - this_s.pos;
	float dist2 = dot(diff,diff);
	float dist = sqrt(dist2);

	vec3 F0 = mix(vec3(0.04), this_s.alb, vec3(this_s.met)); 

  	vec3 L = diff / dist;
 	vec3 V = -this_s.view;
	vec3 H = normalize(V + L); 

	float NoV = clamp(dot(this_s.nor, V), 0.001, 1.0);
	float NoL = clamp(dot(this_s.nor, L), 0.001, 1.0);

	float NoH = clamp(dot(this_s.nor, H), 0.001, 1.0);
	float HoV = clamp(dot(H, V), 0.001, 1.0);

    float alpha_sqr = this_s.rou * this_s.rou;

//Masking function
	float NoV_sqr = NoV*NoV;
	float lambdaV = (-1.0 + sqrt(alpha_sqr * (1.0 - NoV_sqr) / NoV_sqr + 1.0)) * 0.5;
	float G1 = 1.0 / (1.0 + lambdaV);

//Height Correlated Masking-shadowing function
	float NoL_sqr = NoL*NoL;
	float lambdaL = (-1.0 + sqrt(alpha_sqr * (1.0 - NoL_sqr) / NoL_sqr + 1.0)) * 0.5;
	float G2 = 1.0 / (1.0 + lambdaV + lambdaL);


//Fresnel
   	//float c2 = HoV * HoV;
   	//vec3 n2_k2 = this_s.nor * this_s.nor + F0 * F0;
   	//vec3 nc2 = 2.0 * this_s.nor * HoV;

   	//vec3 rs_a = n2_k2 + c2;
   	//vec3 rp_a = n2_k2 * c2 + 1.0;
   	//vec3 rs = (rs_a - nc2) / (rs_a + nc2); //spolarized
   	//vec3 rp = (rp_a - nc2) / (rp_a + nc2); //ppolarized

   	//vec3 F = 0.5 * (rs + rp);
   	vec3 F = F_schlick(HoV, F0);
    
    //Estimator
    //Fresnel * Shadowing
    //Much simpler than brdf * costheta / pdf heh
    vec3 estimator = F * (G2 / G1);

    //Output
    return estimator * test_s.col;
}


float get_pdf(in sample this_s, in sample test_s){

	return 1;
	vec3 diff = this_s.pos - test_s.pos;
	vec3 V = -this_s.view;
	vec3 L = normalize(diff);
	vec3 H = normalize(V + L);		//half vector

	float	HdotV = saturate(dot(H, V));
	float   NdotH = saturate(dot(this_s.nor, H));
	float   HdotL = saturate(dot(H, L)) + 0.001;

	vec3 F0 = mix(vec3(0.04), this_s.alb, vec3(this_s.met)); 
	float	NDF = DistributionGGX(NdotH, this_s.rou); //compute NDF term

	return 1 / ( NDF * NdotH / (4.0 * HdotV + 0.001));
}


vec3 get_radiance(in sample this_s, in sample test_s){

	vec3 diff = test_s.pos - this_s.pos;
	vec3 dir = -normalize(diff);//diff / dist;
	float lambert = max(0.0, dot(this_s.ref, dir));
	lambert = pow(lambert, 300)*300;
	return lambert * test_s.col;
}


vec3 get_radiance_for_env(in sample this_s, in sample test_s){

	vec3 F0 = mix(vec3(0.04), this_s.alb, vec3(this_s.met)); 

  	vec3 L = test_s.nor;
 	vec3 V = -this_s.view;
	vec3 H = normalize(V + L); 

	float NoV = clamp(dot(this_s.nor, V), 0.001, 1.0);
	float NoL = clamp(dot(this_s.nor, L), 0.001, 1.0);

	float NoH = clamp(dot(this_s.nor, H), 0.001, 1.0);
	float HoV = clamp(dot(H, V), 0.001, 1.0);

    float alpha_sqr = this_s.rou * this_s.rou;

//Masking function
	float NoV_sqr = NoV*NoV;
	float lambdaV = (-1.0 + sqrt(alpha_sqr * (1.0 - NoV_sqr) / NoV_sqr + 1.0)) * 0.5;
	float G1 = 1.0 / (1.0 + lambdaV);

//Height Correlated Masking-shadowing function
	float NoL_sqr = NoL*NoL;
	float lambdaL = (-1.0 + sqrt(alpha_sqr * (1.0 - NoL_sqr) / NoL_sqr + 1.0)) * 0.5;
	float G2 = 1.0 / (1.0 + lambdaV + lambdaL);


//Fresnel
   	//float c2 = HoV * HoV;
   	//vec3 n2_k2 = this_s.nor * this_s.nor + F0 * F0;
   	//vec3 nc2 = 2.0 * this_s.nor * HoV;

   	//vec3 rs_a = n2_k2 + c2;
   	//vec3 rp_a = n2_k2 * c2 + 1.0;
   	//vec3 rs = (rs_a - nc2) / (rs_a + nc2); //spolarized
   	//vec3 rp = (rp_a - nc2) / (rp_a + nc2); //ppolarized

   	//vec3 F = 0.5 * (rs + rp);
   	vec3 F = F_schlick(HoV, F0);
    
    //Estimator
    //Fresnel * Shadowing
    //Much simpler than brdf * costheta / pdf heh
    vec3 estimator = F * (G2 / G1);

    //Output
    return estimator * test_s.col;
}

vec4 updateReservoir(vec4 reservoir, float lightToSample, float weight, float c, uint seed, in vec3 candidate_dir, out vec3 best_dir)
{

	// Algorithm 2 of ReSTIR paper
	reservoir.x = reservoir.x + weight; // r.w_sum
	reservoir.z = reservoir.z + c; // r.M
	if (RandomFloat01(seed) < weight / reservoir.x) {

		if(lightToSample >= 0){ //If the sample comes from the viewport
			reservoir.y = lightToSample; // r.y
		} 		
		else{ //If the sample comes from the environment map
			reservoir.y = -1;
			best_dir = candidate_dir;
		}
	}	
	return reservoir;
}

bool background(in sample this_s){
	return this_s.pos.x == 1.0 && this_s.pos.y == 1.0 && this_s.pos.z == 1.0;
}

/*
vec2 pos2uv(in vec3 p){

	vec4 projP = projmat * vec4(p, 1);
	projP.xy = (projP.xy/projP.w) * 0.5 + 0.5;
	return floor( ( textureMatrix0 * vec4(projP.xy,1,1) ).xy ) + 0.5;// * texDim;

}
*/
/*
bool visible_env(in sample this_s, in sample test_s, inout uint seed){

	return true;

	float num_iterations = 25;
	float step = 0.01;//1 / num_iterations;
	float start = 0.0;//step * (RandomFloat01(seed) + 0.5);
	vec3 end_pos = this_s.pos + test_s.nor*10; 
	float end_depth = length(end_pos);
	vec2 end_uv = pos2uv(end_pos);
	for(float i = start; i < 1; i += step){ //make a better tracing
		vec2 test_uv = mix(this_s.uv, end_uv, vec2(i*i));
		if(test_uv.x < 0 || test_uv.y < 0 || test_uv.x >= texDim.x || test_uv.y >= texDim.y) return true;
		float expected_depth = (this_s.depth*farClip * test_s.depth) / mix(test_s.depth*farClip, this_s.depth, i*i);
		float sampled_depth = texture(norDepthTex, test_uv).w*farClip;
		if( expected_depth - sampled_depth > 0.01 ) return false;
	}
	return true;
}
*/

//http://orbit.dtu.dk/fedora/objects/orbit:113874/datastreams/file_75b66578-222e-4c7d-abdf-f7e255100209/content
void calc_orthonormal_basis(in vec3 n, out vec3 f, out vec3 r)
{

    if(n.z < -0.999999)
    {
        f = vec3(0 , -1, 0);
        r = vec3(-1, 0, 0);
    }
    else
    {
    	float a = 1./(1. + n.z);
    	float b = -n.x*n.y*a;
    	f = vec3(1. - n.x*n.x*a, b, -n.x);
    	r = vec3(b, 1. - n.y*n.y*a , -n.y);
    }
}
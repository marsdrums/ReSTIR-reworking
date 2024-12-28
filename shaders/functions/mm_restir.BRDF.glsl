//*********** SPECULAR **************//
/*
	functions from https://www.shadertoy.com/view/NscBWs
    GGX VNDF - Smith importance sampling.
        
    References:
        [R. Cook & K. Torrance, 1982] "A Reflectance Model for Computer Graphics"
        [B. Walter et al, 2007] "Microfacet Models for Refraction through Rough Surfaces"
        [E. Heitz, 2014] "Understanding the Masking-Shadowing Function in Microfacet-based BRDFs"  
        [E. Heitz, 2018] "Sampling the GGX Distribution of Visible Normals"
        [J. Dupuy & A. Benyoub, 2023] "Sampling Visible GGX Normals with Spherical Caps"        
*/


//Lambda used in G2-G1 functions
float Lambda_Smith(float NdotX, float alpha)
{    
    float alpha2 = alpha * alpha;
    float NdotX_sqr = NdotX * NdotX;
    return (-1.0 + sqrt(alpha2 * (1.0 - NdotX_sqr) / NdotX_sqr + 1.0)) * 0.5;
}

//Masking function
float G1_Smith(float NdotV, float alpha)
{
	return 1.0 / (1.0 + Lambda_Smith(NdotV, alpha));
}

//Height Correlated Masking-shadowing function
float G2_Smith(float NdotL, float NdotV, float alpha)
{
	float lambdaV = Lambda_Smith(NdotV, alpha);
	float lambdaL = Lambda_Smith(NdotL, alpha);
	return 1.0 / (1.0 + lambdaV + lambdaL);
}

//Fresnel
vec3 F_Conductor(vec3 n, vec3 k, float cos_theta)
{
   float c2 = cos_theta * cos_theta;
   vec3 n2_k2 = n * n + k * k;
   vec3 nc2 = 2.0 * n * cos_theta;

   vec3 rs_a = n2_k2 + c2;
   vec3 rp_a = rs_a + 1.0;
   vec3 rs = (rs_a - nc2) / (rs_a + nc2); //spolarized
   vec3 rp = (rp_a - nc2) / (rp_a + nc2); //ppolarized

   return 0.5 * (rs + rp);
}

//Returns microfacet visible normal with GGX distribution
vec3 sample_ggx_vndf(vec3 V_tangent, vec2 Xi, float alpha)
{
	//stretch the view direction
    vec3 V_tangent_stretched = normalize(vec3(V_tangent.xy * alpha, V_tangent.z));

	//sample a spherical cap in (-wi.z, 1]
    float phi = M_TAU * Xi.x;
    
	vec3 hemisphere = vec3(cos(phi), sin(phi), 0.0);

	//normalize (z)
	hemisphere.z = (1.0 - Xi.y) * (1.0 + V_tangent_stretched.z) + -V_tangent_stretched.z;	

	//normalize (hemi * sin theta)
	hemisphere.xy *= sqrt(clamp(1.0 - hemisphere.z * hemisphere.z, 0.0, 1.0));

	//halfway direction
	hemisphere += V_tangent_stretched;

	//unstretch and normalize
	return normalize(vec3(hemisphere.xy * alpha, hemisphere.z));
}

vec4 generate_ray_from_GGX_VNDF(in sample this_s){

    // -- Generate uniform random variables between 0 and 1
    uint seed = uint(jit_in.uv.x*2993) + uint(jit_in.uv.y*92241) + uint(11119);
    int randomOffset = int(RandomFloat01(seed) * 64);

    //read the current sample in the Halton sequence
    int i = (frame + randomOffset) % 64; //*** move to vertex stage
    vec2 Xi = vec2( fract(halton[i].x+RandomFloat01(seed)),
                    fract(halton[i].y+RandomFloat01(seed)));

    //Othronormal basis
    vec3 f, r;
    calc_orthonormal_basis(this_s.nor, f, r);
    mat3 TBN = mat3(r, this_s.nor, f);  
    mat3 invTBN = transpose(TBN);

    //calc view vector in tangent space
    vec3 view_tangent = invTBN * this_s.view;

    //sample the GGX_VNDF
    vec3 wm = sample_ggx_vndf(view_tangent, Xi, this_s.rou);

    float q = 1/(1 + this_s.nor.z);
    float noryq = this_s.nor.y*q;
    float h = -this_s.nor.x*noryq;
    vec3 front = vec3(1. - this_s.nor.x*this_s.nor.x*q, h, -this_s.nor.x);
    vec3 up = vec3(h, 1. - this_s.nor.y*noryq, -this_s.nor.y);
                    
    wm = wm.x*up + wm.y*front + wm.z*this_s.nor;

    // -- Calculate wi by reflecting wo about wm
    vec3 wi = reflect(this_s.view,wm);//2.0 * dot(wo, wm) * wm - wo;

    return vec4(wi, 1.0);
}

//Calculates VNDF estimator
vec3 ggx_vndf_estimator(in sample this_s, float NdotL, float NdotV, float VdotH)
{
    //Masking-shadowing
    float G2 = G2_Smith(NdotL, NdotV, this_s.rou);
    
    //Masking
    float G1 = G1_Smith(NdotV, this_s.rou);
    
    //Fresnel
    vec3 F = F_Conductor(this_s.nor, this_s.alb, VdotH);
    
    //Estimator
    //Fresnel * Shadowing
    //Much simpler than brdf * costheta / pdf heh
    vec3 estimator = F * (G2 / G1);

    //Output
    return estimator;
}





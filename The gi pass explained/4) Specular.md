# Indirect Specular

![](./images/reflections.png)

Reflections are computed similarly to indirect diffuse, but special attention is paid on the PDF from which candidate samples are drawn.

Reflections computation includes the following steps:
- Sample gathering (half-res)
- Spatial reuse of the reservoirs (half-res)
- ReSTIR resolve (full-res)
- Temporal filtering (full-res)

## Sample gathering (half-res)
( shader: restir.gather_samples_and_temporal_reuse_REF.jxs )

Samples are gathered differently than the diffuse pass - instead of picking random samples from the viewport and from the environment map, the gathering process is based on screen-space ray tracing. From the shaded point, a ray is generated in a direction determined by the microfacet NDF (more on that later). The ray tracing consists in marching along the ray in screen-space to find intersections with the visible geometry. If the ray intersects the geometry, a sample is taken from the viewport at the corresponding location; if no intersection is found (the ray exits the screen without intersecting anything), the environment map is sampled instead. 

>[!NOTE]
> Reflections are more directional than the lambertian component of the BRDF, therefore the most solid method i experimented to gather useful samples was to ray trace the scene. I'm currently gathering just one sample per frame because the ray tracing operation is quite costly.

>[!WARNING]
> Screen-space ray tracing is currently implemented as no-brainer. I'd like to experiment acceleration structures for speeding-up screen space tracing. More on that in the final section.

### The PDF for reflections

To determine the ray direction for reflections, i refer to microfacet theory. Here’s a quick recap:

From the perspective of microfacet theory, a pixel cannot be represented by a single surface orientation. Instead, it represents a "patch" of microscopic surfaces, each with its own unique orientation. The variation in these facet orientations is governed by a roughness parameter, which controls the divergence of their normals. Since individual facet normals cannot be computed analytically, they are represented statistically.

The distribution of facet orientations is described by a normal distribution function (NDF), which specifies the likelihood of a facet facing a particular direction. 

To generate coherent ray directions, i'm importance sampling the NDF of the microfacets. The NDF distribution model i'm using is the GGX distribution of Visible Normals (GGX VNDF). More on this topic here: https://jcgt.org/published/0007/04/01/paper.pdf, https://schuttejoe.github.io/post/ggximportancesamplingpart2/, https://www.youtube.com/watch?v=MkFS6lw6aEs. 

To maximize convergence time, the random sampling cycles through the first 64 elements of the quasi-random sequence Halton (2,3). For each pixel, the sequence starts from a different random index, and the sampling kernel is randomly rotated. If a ray generated within the BRDF NDF happens to be shot below the floor, it's generated again using a white noise RNG:

![](./images/invalid_ray.png)
Example of invalid ray direction

See the shader restir.BRDF.glsl to take a look at the functions used to sample the NDF.

Once a sample is found, it gets weighted. Weighting reflection samples is different than weighting diffuse samples. This is the function used for weighting (contained inside restir.common.glsl), which uses a pretty standard PBR shading model:

```glsl
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
   	vec3 F = F_schlick(HoV, F0);
    
    //Estimator
    //Fresnel * Shadowing
    //Much simpler than brdf * costheta / pdf 
    vec3 estimator = F * (G2 / G1);

    //Output
    return estimator * test_s.col;
}
```

After weighting, the sample is inserted into a reservoir.

No temporal reuse is employed.

>[!WARNING]
> It would be cool to exploit temporal reuse of the reservoirs, but unfortunately it's not that easy. The difficulty lies in the impossibility to construct relilable velocity vectors to back-project reflections (more on that in the final section). In the original formulation of the ReSTIR algorithm, raytracing in performed in world space, tracing through a BVH and storing the position of the intestected triangle as index in the reservoir. If the triangle moves from one frame to the next, it's very easy to query the new position of the hit point on the triangle, and estimate where it was reflected at the previous frame. Being in screen space, we're not that lucky. For this reason, no temporal reuse of the reservoirs is employed. 

## Spatial reuse of the reservoirs (half-res)
(shader: restir.spatial_reuse_ref.jxs)

The reservoirs are combined spatially. In this pass, samples are not drawn within a normal-oriented disk but instead are sampled using a spiral kernel. The spiral radius is affected by the distance of the sample from the shaded pixel, and by the material's roughness. 

>[!NOTE]
> I initially projected on screen the specular lobe, and gathered the neighboring reservoirs from within it. The spiral kernel seems to do a better job, gathering more contributing reservoirs on average.

The rejection criteria are the same as the diffuse spatial reuse pass (normals equality and distance).

## ReSTIR resolve (full-res)
(shader: restir.resolve_REF.jxs)

The resolution pass is very similar to the one used for the diffuse component. The differences are:
- The resolve pass for reflections uses 8 samples instead of 4.
- Occlusion is no longer taken into account.
- The radius for looking up samples into neighboring reservoirs is affected by roughness and pixel-sample distance.

>[!WARNING]
> Currently i'm always reading samples from 8 reservoirs. The number of averaged samples could be made proportional to spiral radius, with high-roughness materials needing more samples to average, and low-roughness material just a few or one.

The spiral kernel's radius is no longer affected by occlusion, but rather by roughness and the distance between the shaded pixel and the hit point.

Like with diffuse, the resulting color isn't modulated by albedo to optimize the next filtering stage. 

## Temporal filtering (full-res)

Temporal filtering is applied following the same exact algorithm as the diffuse component. The only difference regards velocity vectors. 

Velocity vectors are very useful to reproject the diffuse component, but less than ideal for temporally reproject reflections. I'm providing two distinc sets of velocity vectors to the temporal filtering pass - one coming from the render target, and one specifically crafted for reprojecting reflections. The method i've followed to implement reliable velocity vector for reflections is this:
https://sites.cs.ucsb.edu/~lingqi/publications/rtg2_ch25.pdf

>[!WARNING]
> The framework in which this method is applied is quite different from ours. I tried adapring the method to work in our context with mixed results. I'll go more into the details of what's not working in the final section.

In the temporal filter, i'm sampling color history using both sets of velocity vectors, and i'm blending colors according to local statistics (mean, and squared variance). This method is called "Dual-source reprojection", and has been used both in the "Pica Pica" game, and in the Kajiya renderer. See this video for an explanation of how dual-source reprojection has been implemented in Pica Pica: https://www.youtube.com/watch?v=YwV4GOBdFXo&ab_channel=SEED%E2%80%93ElectronicArts (min 19:39)

>[!WARNING]
> Once again, i'm getting mixed results with this kind of temporal reprojection. While it effectively improves temporal coherence for very smooth materials and very rough materials, it's unclear how to balance it with medium-roughness materials.

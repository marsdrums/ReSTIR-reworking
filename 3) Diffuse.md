# ReSTIR implemented in the "gi" pass FX

Indirect lighting computation is divided into two components: indirect diffuse and indirect specular. These components differ significantly due to the nature of their respective BRDF contributions—diffuse (Lambertian) and specular—exhibiting distinct characteristics. By separating the two, it becomes possible to define tailored sampling PDFs and adjust ReSTIR mechanics, including temporal filtering calibration, to suit each component.

Both branches—diffuse and specular—follow a similar processing pipeline, but certain steps are adjusted to optimize performance or enhance visual quality specific to their respective characteristics.

Direct lighting____________________
![](./images/direct.png)

Indirect diffuse + environment_____
![](./images/diffuse.png)

Indirect specular__________________
![](./images/reflections.png)

Composited frame___________________
![](./images/composite.png)


# Diffuse

The indirect diffuse computation follows these main steps:

- Sample gathering (half-res)
- Sample weighting and reservoir filling (half-res)
- Temporal reuse of the reservoirs (half-res)
- First spatial reuse of the reservoirs (half-res)
- Second spatial reuse of the reservoirs (half-res)
- ReSTIR resolve (full-res)
- Temporal filtering (full-res)

## Sample gathering (half-res)
( shader: restir.gather_samples_and_temporal_reuse_DIF.jxs )

The indirect diffuse computation starts by gathering color samples. The gathering is performed in three ways:

### 1) Gathering samples from the viewport

Random pixels are sampled from the Previous-frame composited image. The random distribution is uniform, and all pixels have the same propability of being sampled. If the sampled pixel is in the background, it's discarded.

>[!NOTE]
> We could ray-trace from the G-Buffer to find intersections with the on-screen geometry; since ReSTIR is all about postponing visibility checks, i'm currently collecting light samples from the texture directly, without worring about them being visible, and skipping costly ray-tracing operations. Visibility is checked only later on. Moreover, since the ray marching happens in screen space, visibility checks are performed by taking a limited number of steps along the ray, making the operation much lighter than world-space ray tracing.

### 2) Gathering samples from the a selection of the brightest pixels

To increase the chances of gathering significant (bright) samples, i'm performing a selection of the brightest pixels prior to sampling. The selection is performed by comparing four pixels within 2x2 tiles, and retrieving the brighntess and thexture coordinates of the brightest pixels. The output texture is then downscaled by a factor of 2. The process is repeated several times, ending with a selection of a handful of very bright pixels. 
( shaders: restir.calc_uv_and_luma.jxs, and restir.find_brightest_pixel.jxs )

>[!NOTE]
> We can't just use these bright pixels as sampling source because potentially they might be occluded, and therefore not contribute to illumination.

>[!NOTE]
> Pixel brightness is evaluated computing the length of the color vector. 

### 3) Gathering samples from the environment map

Random pixels are samples from an environment map. The samples are taken by shooting uniformely distributed rays within the normal-oriented hemisphere. Once again, no ray tracing operation is performed to compute occlusion, as visibility checks are postponed. The environment texture has been mipmapped prior to sampling, and the samples used for the indirect diffuse component are taken from the second mip level (LoD = 1). Althoug incorrect for rigorous path tracing, sampling from a higher mip level reduces variance significanly (hence noise), and speeds up convergence.

>[!NOTE]
> Sampling directions are uniformely distributed within the normal-oriented hemisphere and generated using a white noise. As the original ReSTIR paper suggests, i'm not importance-sampling directions (e.g. using cosine-weighted sampling). It may be worth trying other random generation strategies, such as blue noise or low-discrepancy sequences to see if convergence speed increases.

### Sample weighting and reservoir filling

Once a sample is taken, the first step consists in computing radiance (assuming the sample is visible from the shaded point). Radiance is computed considering samples's color and direction (with respect to surface normal), surface albedo, and the PDF choosen for sampling:

```glsl
// compute radiance for a sample taken from the viewport
vec3 get_radiance(in sample this_s, in sample test_s){

	//compute view-space light direction
	vec3 diff = test_s.pos - this_s.pos;
	vec3 dir = normalize(diff);

	//compute lambert
	float lambert = max(0.0, dot(this_s.nor, dir));
	float PDF = 1 / TWOPI;
	return this_s.alb * lambert * test_s.col / PDF;										
}

// compute radiance for a sample taken from the environment map
vec3 get_radiance_for_env(in sample this_s, in sample test_s){

	// test_s.nor holds the samplign direction in case of environment sampling
	float lambert = max(0.0, dot(this_s.nor, test_s.nor));
	float PDF = 1 / (2*M_PI);
	return this_s.alb * lambert * test_s.col / PDF;							
}
```

Once radiance has been computed, a weight is assigned the sample:

```glsl
[...]
//weight of the sample
p_hat = luminance( get_radiance(this_s, test_s) );
[...]
```
The weighting function (here called luminance) computes weighting as:

```glsl
float luminance(vec3 x){ return length(x); }
```

After weighting, the sample is inserted into the reservoir. Reservoirs contain 4 elements, and are stored as 4-component vectors. Mirroring the original ReSTIR paper, the elements in the reservoir vectors are the following:

- reservoir.x = sum of the weights; the weight of each sample is added to the total weight of the reservoir.
- reservoir.y = index of the selected sample; 
- reservoir.z = number of samples processed by the reservoir so far.
- reservoir.w = weight of the selected sample; 

Each sample must be identified by a single value to keep reservoirs packed into a vec4 for convenience. To make this happen, i'm using two utility funtions to transform texture coordinates into indexes and back:

```glsl
int uv2index(in vec2 uv){
	uv = floor(uv);
	return int(uv.x + uv.y*texDim.x);
}

vec2 index2uv(in int i){
	return vec2( mod( float(i), texDim.x ), floor( float(i) / texDim.x ) ) + 0.5;
}
```

At the beginning of the samples collecting phase, the reservoirs are initialized to vec4(0,0,0,0);

To add a new sample into the reservoir, the function "update_reservoir" is called. This function is used both to add single samples to the reservoir and for merging two reservoirs together:

```glsl
vec4 updateReservoir(	vec4 reservoir, /*reservoir to update*/
						float lightToSample, /*index of the sample to add to the reservoir*/
						float weight, /*sample's weight*/
						float c, /*length of the reservoir that's been merged with this reservoir (=1 in case of a single sample) */
						uint seed, /*RNG seed*/
						in vec3 candidate_dir, /*sample's direction (in case of samples from the environment) */
						out vec3 best_dir /*direction of the most significant sample (in case of samples from the environment) */
					)
{

	// Algorithm 2 of ReSTIR paper
	reservoir.x = reservoir.x + weight; // r.w_sum
	reservoir.z = reservoir.z + c; // r.M

	// change the favourite sample using a weighted probability
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
```
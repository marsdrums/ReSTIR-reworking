# The “gi” pass FX

The "gi" pass FX calculates global illumination by gathering light contributions in screen space using ray marching. It also supports material-aware lighting effects and utilizes environment maps for image-based lighting (IBL).

## Algorithm Overview

The "gi" pass computes indirect lighting and IBL using deferred rendering. Direct lighting is handled separately with jit.gl.pbr shading and shadow mapping, and this output is provided to the pass as a source for indirect illumination.

To gather light samples, the algorithm casts rays in screen space. Its primary objective is to compute global illumination while minimizing the number of samples required. This efficiency is achieved through ReSTIR (Reservoir-based Spatio-Temporal Importance Resampling), which reuses significant light paths across space and time. By leveraging ReSTIR, the algorithm reduces sample counts while maintaining a good (albeit biased) approximation of the rendering equation with fast convergence.

Indirect lighting is split into two components: diffuse and specular lighting. Each component processes independently using the ReSTIR framework and is combined later in the algorithm. During each frame, a single light bounce is computed, but the results are fed into subsequent frames, enabling multiple bounces to be calculated progressively over time.

The "gi" pass also considers the BRDF (Bidirectional Reflectance Distribution Function) of the illuminated surfaces. It integrates with jit.gl.pbr to access surface roughness and metalness values. These surface properties influence the lighting calculations, affecting both the light transport functions and the sampling distributions used for generating rays.

## Anatomy of the "gi" pass

![](./images/algorithm-scheme.png)

### "gi" pass inputs

The "gi" pass relies on many inputs; some of them are the render targets, wheter taken directly or after some processing, some others are the result of the previous frame reprojected onto the current one.

#### The render targets

- Color buffer: it contains the image as rendered in the forward phase. It includes direct illumination + shadows.
- Normals + depth: it contains view-space normals and normalized depth (= length(view-space-position)/far_clip ).
- Velocity buffer: it contains screen-space velocity vectors, encoded as red = horizontal_velocity, and green = vertical_velocity.
- Albedo buffer: it contains the albedo color as processed by jit.gl.pbr.
- Roughness and metalness buffer: it contains the roughness and metalness values as processed by jit.gl.pbr in the red and green channels respectively
- 4 layers of depth: it contains four layers of depth (view-space.z) obtained through depth peeling. R = closest front face depth; G = closest back face depth; B = second closest front face depth; A = second closest back face depth. Having 4 depth layers improves the accuracy of screen-space ray marching.

#### Velocity inflation and disocclusion weights

Velocity vectors are used to temporally reproject data from the previous frame onto the current frame. Temporal reprojection serves two key purposes: enabling the temporal reuse of reservoirs and supporting temporal filtering. 

Since velocity vectors are tied to the geometry that generates them, even minor inaccuracies can result in faulty reprojections at shape edges, leading to ghosting artifacts. To mitigate this, velocity vectors are "inflated," extending them over the shape they belong to. This inflation is achieved by examining 2x2 tiles and selecting the velocity vector of the closest fragment in the tile.

When objects move, new fragment may be disoccluded and appear on screen for the first time. To account for disoccluded fragments, a weight is assigned to each fragment representing how relieable is each velocity vector. Such computation is performed considering the fragment's velocity vectors, and the previous velocity vectors (the method is described in detail here: https://www.elopezr.com/temporal-aa-and-the-quest-for-the-holy-trail/).

```glsl
// Assume we store UV offsets
vec2 currentVelocityUV = texture(velocityTexture, uv).xy;
 
// Read previous velocity
vec2 previousVelocityUV = texture(previousVelocityTexture, uv + currentVelocityUV).xy;
 
// Compute length between vectors
float velocityLength = length(previousVelocityUV - currentVelocityUV);
 
// Adjust value
float weight = saturate((velocityLength - 0.001) * 10.0);
```

The weights are stored in the blu channel of the inflated velocity texture.
Weights are used to accept/reject temporal reprojections, and they're used both in the temporal reuse of the reservoirs and in temporal filtering.

#### Velocity vectors for reflections

Velocity vectors describe how a given fragment moves between frames. While they are ideal for temporally reprojection of reservoirs and colors (in the temporal filter) for the diffuse component, they are inadequate for reprojection of reflections. To compute reliable motion vectors for temporal reprojection of reflections, I’ve been exploring the method outlined in this paper -> https://sites.cs.ucsb.edu/~lingqi/publications/rtg2_ch25.pdf.

This approach requires retrieving the local transform for each reflected fragment, which is currently not feasible within the existing framework. I’ve been working to adapt or approximate the method to function without direct access to the local transform.

>[!WARNING]
> The solution I’ve devised appears to work to some extent, but there are still unresolved challenges in handling rough reflections and accounting for disocclusion weights. 

#### Downscaling

Each render target undergoes a downscaling process, reducing its texture size by half. These half-size render targets are utilized during sample collection and reservoir reuse. Downscaling is achieved by randomly selecting one pixel within a 2x2 tile. The same pixel is chosen across all render targets within the tile.

>[!NOTE]
> I experimented with several strategies for downsampling the render targets. Initially, I consistently chose the top-left pixel within each tile (and so it is in the currently released version of the pass FX). While functional, this resulted in noticeable jagged edges along shapes. Another approach involved averaging the pixel values within each tile (ensuring normal vectors were re-normalized), but this adversely affected ray-marching during depth comparisons. Randomly selecting a pixel within the 2x2 tile proved to be the most effective method. It enhances sample variance and acts as a form of "downscaled TAA" when the image undergoes temporal filtering.

#### Environment map

The "gi" pass can access the environment map provided via jit.gl.environment. When "gi" is instanciated, IBL computation gets disabled in jit.gl.pbr, and the light coming from the environment is computed in the pass instead.

#### Short-range AO

A short range ambient occlusion is computed ray marching through the 4 depth layers. Ambient occlusion is computed by taking 8 samples per frame within the hemisphere above the surface; Samples are distributed using spatio-temporal blue noise. The AO isn't applied directly to the rendered image; rather, it's used to control the reservoir spatial reuse, and the ReSTIR resolve pass. More about that in the dedicated sections.

#### Previous-frame composited image

The result of the previous frame is reprojected onto the current frame and used as source for indirect illumination; This process allows for computing multiple light bounces across frames. Only the diffuse component is reprojected at the next frame (because is not view-dependent). Reflections are fed back only if the surface is metallic.

>[!NOTE]
> Reprojecting reflections allows for inter-reflections. The result isn't physically accurate, because reflections are striclty view dependent. Still, with metallic objects, non-correct inter-reflections look better than no inter-reflection...

# ReSTIR

Direct lighting____________________
![](./images/direct.png)

Indirect diffuse___________________
![](./images/diffuse.png)

Indirect specular__________________
![](./images/reflections.png)

Composited frame___________________
![](./images/composite.png)



## Diffuse

The indirect diffuse computation follows these main steps:

- Sample gathering (half-res)
- Temporal reuse of the reservoirs (half-res)
- First spatial reuse of the reservoirs (half-res)
- Second spatial reuse of the reservoirs (half-res)
- ReSTIR resolve (full-res)
- Temporal filtering (full-res)

### Sample gathering (half-res)
( shader: restir.gather_samples_and_temporal_reuse_DIF.jxs )

The indirect diffuse computation starts by gathering color samples. The gathering is performed in three ways:

#### 1) Gathering samples from the viewport

Random pixels are sampled from the Previous-frame composited image. The random distribution is uniform, and all pixels have the same propability of being sampled. If the sampled pixel is in the background, it's discarded.

>[!NOTE]
> We could ray-trace from the G-Buffer using an NDF (hemisphere sampling or cosine-weighted) to find intersections with the on-screen geometry; since ReSTIR is all about postponing visibility checks, i'm currently collecting light samples from the texture directly, without worring about them being visible, and skipping costly ray-tracing operations. Visibility is checked only later on.

#### 2) Gathering samples from the a selection of the brightest pixels

To increase the chances of gathering significant (bright) samples, i'm performing a selection of the brightest pixels prior to sampling. The selection is performed by comparing four pixels within 2x2 tiles, and retrieving the brighntess and thexture coordinates of the brightest pixels. The output texture is then downscaled by a factor of 2. The process is repeated several times, ending with a selection of a handful of very bright pixels.
( shaders: restir.calc_uv_and_luma.jxs, and restir.find_brightest_pixel.jxs )

>[!NOTE]
> We can't just use these bright pixels as sampling source because potentially they might be occluded, and therefore not contribute to illumination.

>[!NOTE]
> Pixel brightness is evaluated computing the length of the color vector. 

#### 3) Gathering samples from the environment map

Random pixels are samples from an environment map. The samples are taken by shooting uniformely distributed rays within the normal-oriented hemisphere. Once again, no ray tracing operation is performed to compute occlusion, as visibility checks are postponed. The environment texture has been mipmapped prior to sampling, and the samples used for the indirect diffuse component are taken from the second mip level (LoD = 1). Althoug incorrect for rigorous path tracing, sampling from a higher mip level reduces noise significanly, and speeds up convergence.

>[!NOTE]
> Sampling directions are uniformely distributed within the normal-oriented hemisphere and generated using with noise. As the original ReSTIR paper suggests, i'm not importance-sampling directions (e.g. using cosine-weighted sampling). It may be worth trying other random generation strategies, such as blue noise or low-discrepancy sequences to see if convergence speed increases.

#### Sample weighting and reservoir filling

Once a sample is taked, the first step consists in computing radiance (assuming the sample is visible). Radiance is computed considering samples's intensity and direction (with respect to surface normal), surface albedo, and the PDF choosen for sampling:

```glsl
// compute radiance for a sample taken from the viewport
vec3 get_radiance(in sample this_s, in sample test_s){

	//compute view-space light direction
	vec3 diff = test_s.pos - this_s.pos;
	vec3 dir = normalize(diff);

	//compute lambert
	float lambert = max(0.0, dot(this_s.nor, dir));
	float PDF = 1 / (2*M_PI);
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
p_hat = luminance( get_radiance(this_s, test_s) );
[...]
```
The weighting function (here called luminance) computes weighting as:
```glsl
float luminance(vec3 x){ return length(x); }
```

After weighting, the sample is inserted into the reservoir. Reservoirs contain 4 elements, and are stored as 4-component vectors for simplicity:
- reservoir.x = sum of the weights; the weight of each sample is added to the total weight of the reservoir.
- reservoir.y = index of the best candidate sample; the reservoir holds the index of the most significant sample.
- reservoir.z = number of samples contained in the reservoir.
- reservoir.w = reservoir's; careful handling of this values makes math happy.

At the beginning of the samples collecting process, the reservoirs are initialized to vec4(0.0);
To add a new sample into the reservoir, the function "update_reservoir" is called. This function is used both to add single samples to the reservoir and for merging two reservoirs together:

```glsl
vec4 updateReservoir(	vec4 reservoir, /*reservoir to update*/
						float lightToSample, /*rindex of the sample to add to the reservoir*/
						float weight, /*sample's weight*/
						float c, /*length of the reservoir that's been merged with this reservoir*/
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



## Reflections

## Compositing


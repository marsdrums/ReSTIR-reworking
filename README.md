# The “gi” pass FX

The "gi" pass FX calculates global illumination by gathering light contributions in screen space using ray marching. It also supports material-aware lighting effects and utilizes environment maps for image-based lighting (IBL).

## Algorithm Overview

The "gi" pass computes indirect lighting and IBL using deferred rendering. Direct lighting is handled separately with jit.gl.pbr shading and shadow mapping, and this output is provided to the pass as a source for indirect illumination.

To gather light samples, the algorithm casts rays in screen space. Its primary objective is to compute global illumination while minimizing the number of samples required. This efficiency is achieved through ReSTIR (Reservoir-based Spatio-Temporal Importance Resampling), which reuses significant light paths across space and time. By leveraging ReSTIR, the algorithm reduces sample counts while maintaining a good (albeit biased) approximation of the rendering equation with fast convergence.

Indirect lighting is split into two components: diffuse and specular lighting. Each component processes independently using the ReSTIR framework and is combined later in the algorithm. During each frame, a single light bounce is computed, but the results are fed into subsequent frames, enabling multiple bounces to be calculated progressively over time.

The "gi" pass also considers the BRDF (Bidirectional Reflectance Distribution Function) of the illuminated surfaces. It integrates with jit.gl.pbr to access surface roughness and metalness values. These surface properties influence the lighting calculations, affecting both the light transport functions and the sampling distributions used for generating rays.

# Some necessary info and annoying math about importance resampling, reservoirs and ReSTIR

Here i'm collecting some concepts fundamental for understanding the ReSTIR algorithm and some useful links to go deeper into the subject. I try to keep it short, but i'm sure i'll fail.

## Importance sampling

We all know this guy:

$$
L_o(\mathbf{x}, \omega_o) = L_e(\mathbf{x}, \omega_o) + \int_{H^{2}} f_r(\mathbf{x}, \omega_o, \omega_i) L_i(\mathbf{x}, \omega_i) \cos(\theta_i) d\omega_i
$$

There's no computable solution to the rendering equation, but we can estimate its result. To estimate it, we can raytrace from a point on a surface in random directions and collect radiance samples - averaging the light contributions, we can estimate the solution to the rendering equation.
The problem with this approach, is that of all the taken samples, not all of them are "important", as many won't bring much light to the pixel being shaded. If we can afford few samples per frame, it would be better to make the best out of the available resources.

Importance sampling is about shooting rays where it really matters.

There are two ways to (statistichally) know if a certain light direction is important:
- the BRDF (or BSDF) of the surface being shaded
- The relative position of light sources with respect to the point being shaded.

### Importance sample the BxDF 

Given a certain BxDF, we know that the light direction affects the amount of light reflected by a surface. To make an example, consider the diffuse component computation in these two scenarios:

![](./images/lambert.png)

The point on the left reflects more light than the point on the right, because the cosine of the angle formed by the normal vector and the light direction is smaller. Knowing this, we could concentrate the random ray directions towards the aphex of the hemisphere where it is more likely to find important light sources. This is called cosine-weighted importance sampling.

![](./images/cosine.png)

When determining how to shoot rays, we rely on a PDF (probability density function). Examples of PDFs include uniform sampling and cosine-weighted sampling. The PDF defines the likelihood of shooting a ray in a specific direction.

When samples are drawn from a non-uniform PDF, rays tend to cluster, with some directions being sampled more frequently than others. To account for this bias, the radiance from any given direction must be divided by the likelihood of selecting that direction. For example, this is how the lambertian component is computed in a ray-traced context:

```glsl
// compute diffuse component for uniform PDF

float lambert = max(0.0, normal, light_direction)); //cosine N.L
float PDF = 1 / M_TWOPI; //Uniform sampling PDF weight
vec3 diffuse_radiance = albedo * lambert * light_color / PDF;										
```

```glsl
// compute diffuse component for cosine-weighted PDF

float cosine = max(0.0, normal, light_direction)); //cosine N.L
float PDF = cosine / M_PI; //cosine-weighted PDF weight
vec3 diffuse_radiance = albedo * cosine * light_color / PDF;										
```
>[!NOTE]
> Cosine-weighted PDF is cool also because the cosine term cancels out nicely, and can be rewritte like:
```glsl
// compute diffuse component for cosine-weighted PDF

//cosine = max(0.0, normal, light_direction)); //cosine N.L
//PDF = cosine / M_PI; //cosine-weighted PDF weight
//albedo * cosine * light_color / PDF;	
vec3 diffuse_radiance = M_PI * albedo * light_color;										
```

As long as we account for certain directions being sampled more often than others, any PDF covering the hemisphere makes the rendering equation converge. Still, some distriubutions make the render converge faster than others.

### Importance sampling light sources

If there’s a bright light source on the right and nothing on the left, shooting a ray to the left is essentially wasted effort. Importance sampling is not just about favoring directions that inherently carry more energy due to the BxDF; it’s also about directing rays more frequently toward significant light sources. However, this introduces additional challenges. To precisely identify the most relevant light sources, we would first need to solve the rendering equation—putting us back to square one. Simply ranking light sources by intensity isn’t sufficient either, as some light sources may be occluded or their contributions diminished by albedo modulation. There’s no universal way to determine which light sources are most important (e.g., an intense blue light source with values like (0,0,50) contributes nothing to a surface with an albedo of (1,1,0)).

Let’s revisit why importance sampling the BxDF works. Considering the diffuse component of the BRDF, we know that light sources directly above a surface contribute more to its illumination than those at shallow angles. This relationship is well-defined because there is an analytical function— 𝑁⋅𝐿 —that describes light intensity as a function of angle. To importance sample the diffuse BRDF, we can generate random samples proportional to this function. The target function is known, and the PDF we use for generating samples must mirror the shape of the target function (they must have the same profile when plotted). Therefore, importance sampling is most effective when the chosen PDF closely matches the target function, as in the case of using a cosine-weighted PDF for the diffuse BRDF.

![](./images/samples_from_PDF.png)

This is straightforward for the diffuse lobe, as it is known in advance. But what if we need to importance sample something less predictable, like light sources we know little to nothing about? In other words, how can we create a PDF that aligns with a target function we have no prior knowledge of?

This is where Resampled Importance Sampling (RIS) comes into play.

## Resampled Importance Sampling (RIS)

Resampled Importance Sampling (RIS) is a method for constructing a PDF to importance sample an unknown target function. It forms the basis of the ReSTIR algorithm.

The core concept is that, given a very large pool of low-quality samples, you can intelligently select a smaller subset from this pool to produce a set of higher-quality samples.

Algorithmically, this means:

1) First, use a cheap, or naive, algorithm to generate a large number of samples 𝑆𝑖
2) Second, pick a subset of 𝑆𝑖 to create a new set of samples 𝑅𝑗 assigning a weight to each of them to "score" how important they are
3) Use samples 𝑅𝑗 for your rendering.

This is called “resampling” because you pick your final samples 𝑅𝑗 by re-evaluating weights for your earlier samples 𝑆𝑖
 and picking a subset of them. (I.e., every 𝑅𝑗 is also a sample 𝑆𝑖)

Example:

Imagine you are rendering a scene with an LED strip, where each individual LED varies in intensity. Here’s how RIS would approach this problem:

![](./images/RIS1.png)

The graph above illustrates the intensity of the LEDs along the strip—most of the strip is dark, with only a bright region on the left.

To importance sample this target function, samples should be drawn in proportion to its intensity, resulting in a distribution that might look like this:

![](./images/RIS2.png)

where more samples are drawn where the function in high, fewer where it's low, none where it's zero. But we know the led strip intensity because we're omniscent; what if we don't know anything about it but still need to find a PDF that matches the target function? This is how to do it with RIS:

1) Start with a simple and uniform PDF. The goal is to turn this simple PDF into a more complex PDF that matches the target function. Start by generating uniformly distributed random samples from the simple PDF. Being uniform, the PDF from which we're drawing our samples has a weight of 1 everywhere. (Any initial PDF can be used; for the sake of simplicity, i'm using a uniform samples distribution in this example)

![](./images/RIS3.png)

2) Sample the scene, and assign a weight to each sample - weighting samples can be performed in a variety of ways, but let's say we simply compute the luminance of the samples, ending with a single value representing how bright a sample is. This brightness value is a weight assigned to the samples in the complex PDF.

![](./images/RIS4.png)

Here, spheres' radius is used to represent the sample's weight.

3) Divide the weight of the sample in the complex PDF by the weight of that sample in the simple PDF; being the simple PDF uniform, we divide the weight by 1, which leaves us with simply the weight of the sample in the complex PDF. Brighter samples will have higher weights than darker ones.

![](./images/RIS5.png)

4) Here starts the "rendering" part: Pick a random sample from the complex PDF - higher weighted samples are more likely to be choosen. A sample with weight = 3 is three times more likely to be choosen than a sample of weight = 1. 
5) The radiance emitted by the choosen sample must be divided by the weight that the sample has in the complex PDF. The division by weight compensates for some regions being sampled more often than others.
6) Lastly, we need to multiply radiance by the average weight of all the samples; this compensates for the fact that we're taking a limited number of samples, and makes the complex PDF coincide with the target function we're sampling.

Using math symbols:

1) $x_1, x_2, ..., x_m$ -> samples from the simple PDF (uniform)
2) $w(x) = \frac{complexPDF(x)}{simplePDF(x)}$ -> assign a weight to sample x
4) $y \sim w$ -> draw sample y proportional to w
5) $e = f(y)$ -> compute radiance e from sample y
6) $e_w = \frac{ \frac{1}{m} \sum_{i=1}^{m} w(x_i) }{complexPDF(x)}$ -> scale radiance by average samples' weight divided by this sample's weight in the complex PDF

Where does the performance advantage lie in generating many samples and then resampling them? If we need to generate many samples to estimate which matter the most, can't we render from these samples directly? The benefit comes from the ability to simplify certain aspects when assigning weights to the samples. For example, instead of factoring in visibility (which involves expensive ray-tracing operations), weights can be estimated based on the unshadowed contribution of the samples. RIS enables a "coarse" selection of the most promising candidates, allowing the rendering part of the algorithm to focus sampling efforts where it (should) matter the most.

(Refer to these links for a clearer in-depth explaination: 
https://www.youtube.com/watch?v=gsZiJeaMO48&t=416s , 
https://cwyman.org/blogs/introToReSTIR/introToRIS.md.html#:~:text=Resampled%20importance%20sampling%2C%20or%20RIS,thesis%20from%20Brigham%20Young%20University. )

With RIS, we can draw a bunch of random samples, compute a cheap estimate of their importance, and then resample these samples, with higher weighted samples being more likely to be selected. 
But how exaclty can we perform this weighted random selection efficiently?

## The Reservoirs

After the RIS process, we obtain a large set of weighted samples, and the next step is to perform a weighted random selection from them. However, storing such a large number of samples can be challenging. This is where reservoir sampling comes into play — a technique that allows for this type of selection without requiring significant memory or prior knowledge of the total number of samples.

Reservoir Sampling is a randomized algorithm for selecting a sample of 𝑘 items from a larger population of 𝑁 items, where 𝑁 is unknown or too large to fit into memory. Reservoir sampling allows you to stream a list of data and choose an item from the list as you go. This also works when you want to choose items in the list with different probabilities, which is key for importance sampling. 

A reservoir is a data structure used to perform this selection. You can throw any number of samples into a reservoir, and perform a weighted random selection on them. 

Please, refer to these links for an in-depth explanation of how reservoir sampling works:
https://www.youtube.com/watch?v=A1iwzSew5QY , 
https://blog.demofox.org/2022/03/01/picking-fairly-from-a-list-of-unknown-size-with-reservoir-sampling/ )

A reservoir contains 4 things:

- the sum of all the weights; when a new sample is thrown into a reservoir, its weight is added to the total weight.
- the index of the chosen sample; the reservoir holds the index of the selected sample.
- the number of samples contained in the reservoir; for every new sample added to the reservoir, this value is increased by 1.
- the weight of the current sample; This is needed to perform steps 5 and 6 of the RIS algorithm.

Here’s how reservoir sampling works:

- Start with an empty reservoir and insert the first sample into it.
- For each new sample, perform a weighted random selection between the sample currently in the reservoir and the new sample being added. The weights for this selection are determined by the weight of the new sample compared to the running sum of the weights of all samples processed so far.
- Flip a "coin" (based on the weighted probabilities) to decide whether to keep the current sample in the reservoir or replace it with the new one.
- Regardless of the outcome, add the weight of the new sample to the running total of weights.

Here’s a GLSL-like pseudo-code function to integrate new samples into the reservoir:

```glsl
void updateReservoir(inout vec4 reservoir, float newSampleIndex, float newSampleWeight)
{
	//reservoir.x = running sum of all the weights seen so far
	//reservoir.y = index of the current sample kept in the reservoir
	//reservoir.z = number of samples added so far
	//reservoir.w = weight of the current sample

	reservoir.x += newSampleWeight; //add the new sample's weight to the running total of weights 
	reservoir.z += 1; // add 1 to the number of samples thrown into the reservoir so far

	//perform the weighted random coin flip
	if (RandomFloat01() < newSampleWeight / reservoir.x) {
		reservoir.y = newSampleIndex; //substitute the old sample with the new one
		reservoir.w = newSampleWeight; //update the weight of the current sample
	}	
}									
```

Reservoirs also have a fantastic property: they can be combined! If you have two ore more reservoirs and you want to combine them, you don't have to put all the individual samples that got processed by the reservoirs we're combining; you just have to take the current sample in each reservoir, and add it to the combined reservoir, togheter with the length of the reservoirs we're combining.

```glsl
void combineReservoirs(inout vec4 reservoir, in vec4 reservoirToCombine)
{
	//reservoir.x = running sum of all the weights seen so far
	//reservoir.y = index of the current sample kept in the reservoir
	//reservoir.z = number of samples added so far
	//reservoir.w = weight of the current sample

	reservoir.x += reservoirToCombine.w * reservoirToCombine.z; //add the new sample's weight to the running total of weights scaled by how many samples are contained in reservoirToCombine
	reservoir.z += reservoirToCombine.z; // add the length of reservoirToCombine to the total number of samples thrown into the reservoir so far

	//perform the weighted random coin flip
	if (RandomFloat01() < reservoirToCombine.w * reservoirToCombine.z / reservoir.x) {
		reservoir.y = reservoirToCombine.y; //substitute the old sample with the new one
		reservoir.w = reservoirToCombine.w; //update the weight of the current sample
	}	
}								
```

This property of reservoirs is what makes ReSTIR possible.

## ReSTIR (Reservoir-based Spatio-Temporal Importance Resampling)

ReSTIR is an algorithm aimed at finding very quickly the most important light samples for each rendered pixel.

- "Importance Resampling" because it's based on RIS.
- "Reservoir-based" because it uses reservoir sampling to perform weighted random selection of the samples selected by RIS.
- "Spatio-Temporal" because it combines reservoirs from neighboring pixels (spatial) and from past frames (temporal) to select among a massive amount of candidate samples very quickly.

This is a breakdown of how ReSTIR works:

1) Gather a random sample - The sampling strategy depends on the context in which ReSTIR is used - in full fledgeg ray tracing rendering, samples are taken by raytracing the scene geometry. The PDF used for drawing these initial samples can be anything, althoug the original ReSTIR paper suggests using uniform sampling.

2) Assign a weight to the sample - The weighting is performed considering the BxDF of the shaded point, its albedo value, and the sample's color (in ReSTIR used for computing direct illumination, the squared distance from the shaded point to the sample is also taken into account). Wheighting is perfomed like this:

$$
	e = x_{alb} * f_r(\mathbf{x}, \omega_o, \omega_i) L_i(\mathbf{x}, \omega_i) \cos(\theta_i) / PDF
$$

$$
	e_w = \lVert e \rVert
$$

where $e$ is the radiance, $e_w$ is the samples's weight, $x$ is the shaded point, $x_{alb}$ is the albedo of the shaded point, $f_r(\mathbf{x}, \omega_o, \omega_i)$ is the BxDF of the shaded point, and $L_i(\mathbf{x}, \omega_i)$. The weight corresponds to the length of the radiance vector.

3) Once the weight has been computed, the sample is inserted into the a reservoir. Each pixel contains a reservoir storing the candidate samples. Repeat steps from 1 to 3 if you need to increase the initial pool of samples. Typically only one sample is taken because ray tracing operations are by far the most costly.

4) Temporal reuse of the reservoirs - the current reservoir is combined with the previous frame reservoir. Combining reservoirs temporally allows for iteratively refining the sampling PDF. Before combining the current and previous reservoir, the previous reservoir must be validated: a shadow ray is traced from the shaded point to the sample stored in the previous reservoir to check if it's still visible in the current frame. If it is, the reservoirs are combined, otherwise, the previous frame reservoir is discarded.

5) Spatial reuse of the reservoirs - neighboring reservoirs might contain just-as-good samples as the current reservoir; This reservoir is then combined with the neighboring reservoirs, under the assumption that given the closness of the reservoirs, the candidate samples stored by neighbors are visible from the shaded point.

6) Resolve the reservoir - The sample that "survided" reservoir sampling is used to render illumination for the shaded point.

The strength of ReSTIR lies in its ability to gather a large number of samples at the cost of just 2 ray tracing operations: one ray to gather the sample, one ray to validare the history samples. To put it into numbers:

- frame 1: gather 1 sample, no history available, add 8 (8x1) samples from neighbors = 9 samples
- frame 2: gather 1 sample, 9 samples available from history, add 80 (8x10) samples from neighbors = 90 samples
- frame 3: gather 1 sample, 90 samples available from history, add 728 (8x21) samples from neighbors = 819 samples
- frame 4: gather 1 sample, 819 samples available from history, add 6560 (8x820) samples from neighbors = 7380 samples

and so on... In the time span of just 4 frames, at the cost of 2 rays per pixel, we can actually select among 7380 importance sampled samples for rendering (CRAZY!!).

This is the origianl formulation of the ReSTIR algorithm. Many shortcuts are possible, and the Jitter implementation, as well as other implementations you can find online, cut some corners, especially concerning history validation. In the next paragraph i'll detail how ReSTIR has been implemented and adapted in the "gi" pass FX.

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



## Reflections

## Compositing


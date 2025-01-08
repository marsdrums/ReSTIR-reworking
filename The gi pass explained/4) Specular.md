# Indirect Specular

![](./images/reflections.png)

Reflections are computed similarly to indirect diffuse, but special attention is paid on the PDF from which candidate samples are drawn.

Reflections computation includes the following steps:
- Sample gathering (half-res)
- Temporal reuse of the reservoirs (half-res)
- Spatial reuse of the reservoirs (half-res)
- ReSTIR resolve (full-res)
- Temporal filtering (full-res)

## Sample gathering (half-res)
( shader: restir.gather_samples_and_temporal_reuse_REF.jxs )

Samples are gathered differently than the diffuse pass - instead of picking random samples from the viewport and from the environment map, the gathering process is based on screen-space ray tracing. From the shaded point, a ray is generated in a directions determined by the microfacet NDF (more on that later). The ray tracing consists in marching along the ray in screen-space to find intersections with the visible geometry. If the ray intersects the geometry, a sample is taken from the viewport at the corresponding location; if no intersection is found (the ray exits the screen without intersecting anything), the environment map is sampled instead.

>[!NOTE]
> Reflections are more directional than the lambertian component of the BRDF, therefore the most solid method i experimented to gather useful samples was to ray trace the scene.

### The PDF for reflections

To determine the ray direction for reflections, I refer to microfacet theory. Here’s a quick recap:

Microfacet theory is a widely used model in computer graphics that explains how light interacts with surfaces at a microscopic level. Instead of treating surfaces as perfectly smooth or uniformly rough, this theory assumes that a surface is made up of countless tiny planar facets, each acting like a mirror to reflect light.

From the perspective of microfacet theory, a pixel cannot be represented by a single surface orientation. Instead, it represents a "patch" of microscopic surfaces, each with its own unique orientation. The variation in these facet orientations is governed by a roughness parameter, which controls the divergence of their normals. Since individual facet normals cannot be computed analytically, they are represented statistically.

The distribution of facet orientations is described by a normal distribution function (NDF), which specifies the likelihood of a facet facing a particular direction. 

To generate coherent ray directions, i'm importance sampling the NDF of the microfacets. The NDF distribution model i'm using is the GGX distribution of Visible Normals (GGX VNDF). More on this topic here: https://jcgt.org/published/0007/04/01/paper.pdf, https://schuttejoe.github.io/post/ggximportancesamplingpart2/. 

To maximize convergence time, the random sampling cycles through the first 64 elements of the quasi-random sequence Halton (2,3). For each pixel, the sequence starts from a different random index, and the sampling kernel is randomly rotated.

Since the distribution isn't uniform, the PDF changes for each direction - along with the hit point (if the ray intersects the geometry) or the ray direction (if the ray doesn't intersect the geometry), also the PDF of the sampled direction is output from the ray tracing function to divide the weight of the sample.

>[!WARNING]
> I struggled making the division by PDF work, and to this day it doesn't look right. I might have implemented the PDF weight computation wrong.

## Temporal reuse of the reservoirs (half-res)



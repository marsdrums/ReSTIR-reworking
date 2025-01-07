# Indirect Specular

![](./images/reflections.png)

Reflections are computed similarly to indirect diffuse, but special attention is paid for the PDF from which candidate samples are drawn.

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
> Reflections are way more directional than the lambertian component of the BRDF, therefore the most solid method i experimented to gather useful samples was to ray trace the scene.

### The PDF for reflections

For determining useful ray direction, i'm referring to the microfacets theory. A quick recap:
Microfacet theory is a widely used model in computer graphics to describe the interaction of light with surfaces at a microscopic level. Instead of treating surfaces as perfectly smooth or uniformly rough, microfacet theory assumes that a surface is composed of countless tiny planar facets, each acting like a mirror that reflects light.

The surface is made up of small planar microfacets with varying orientations. The distribution of these orientations is described by a normal distribution function (NDF), which determines how likely a given facet is to face a particular direction. 

To generate coherent ray directions, i'm importance sampling the NDF of the microfacets. The NDF distribution model i'm using is the GGX distribution of Visible Normals (GGX VNDF). More on this topic here: https://jcgt.org/published/0007/04/01/paper.pdf, https://schuttejoe.github.io/post/ggximportancesamplingpart2/. 

To maximize convergence time, the random sampling cycles through the first 64 elements of the quasi-random sequence Halton (2,3). Each pixel starts from a different index of the sequence, and the sampling kernel is rotated randomly.

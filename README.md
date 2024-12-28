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
- Normals + depth: it contains view-space normals and normalized depth (= length(view-space-position)).
- Velocity buffer: it contains screen-space velocity vectors, encoded as red = horizontal_velocity, and green = vertical_velocity.
- Albedo buffer: it contains the albedo color as processed by jit.gl.pbr.
- Roughness and metalness buffer: it contains the roughness and metalness values as processed by jit.gl.pbr in the red and green channels respectively
- 4 layers of depth: it contains four layers of depth (view-space.z) obtained through depth peeling. R = closest front face depth; G = closest back face depth; B = second closest front face depth; A = second closest back face depth. Having 4 depth layers improves the accuracy of screen-space ray marching.

#### Velocity inflation and disocclusion weights

The velocity vectors are used to temporally reproject "stuff" from the previous frame onto the current. Temporal reprojection is used for reservoirs temporal reuse, and for temporal filtering. Sice velocity vectors are bound to the shape generating them, small imprecision can lead to faulty reprojections of the pixels at the edges of a shapes, producing ghosting effects. To account for this, the velocity vectors are "inflated", extending them over the shape to which they belong. The inflation is acchieved by considering 2x2 tiles and picking the velocity with the highest magnitude.

>[!NOTE]
> As an alternative, we could pick the velocity of the closest fragment (smallest depth value) within the tile.

When objects move, new fragment may be disoccluded and appear on screen for the first time. To account for disoccluded fragments, a weight is assigned to each fragment representing how relieable is each velocity vector. Such computation is performed considering the fragment's velocity vectors, and the previous velocity vectors (the method is described here https://www.elopezr.com/temporal-aa-and-the-quest-for-the-holy-trail/).

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

#### Downscaling

Each render target goes through a process of downscaling, to cut the texture size in half. Half-size render targets are used during the samples collecting process and during reservoirs reuse. The downscaling happens by randomly picking one pixel in a 2x2 tile. The chosen pixel within the tile is the same for all the render targets. 

>[!NOTE]
> I tried different strategies for downsampling the render targets: the first choice was to always pick the same pixel within the tile (top-left). This works, but leads to visible jaggyness along the shape edges. I also tried averaging the pixel values within each tile (making sure to re-normalize normals), but this negatively affects ray-marching when it comes to depth comparison. Randomly picking a pixel within the 2x2 tile seems to be the best choice, as it improves sample variance and works as a sort of "downscaled-TAA" when the image is temporally filtered.

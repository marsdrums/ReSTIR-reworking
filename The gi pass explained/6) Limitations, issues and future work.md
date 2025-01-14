# Limitations, issues and future work

The "gi" pass is far from being perfect, but there should be room for improvement. This is a list of the critical aspects of the current state of the algorithm, somewhat sorted by relevance (i'm importance sampling the issues...).

## Blackouts

The rendering occasionally becomes abruptly unstable, causing black areas to appear on the screen. The only way to resolve this is by re-instantiating the pass or quickly moving the camera around. After recent updates to the "gi" algorithm, these blackouts have become significantly less frequent, but they still occur unpredictably.

I do not yet have a precise understanding of the root cause, so I am unable to fully resolve the issue. However, I suspect the problem lies in the part of the algorithm responsible for computing reflections, as rendering only the diffuse component has never caused this artifact to appear. The nature of the artifact suggests a potential division by zero or faulty memory access somewhere in the code. Additionally, the spatio-temporal reservoir reuse mechanism seems to gradually "spread" the black areas across the rendered image.

To identify and address the problem, I will need to use an analysis tool for a more detailed investigation. The issue appears to be related to changes in lighting conditions, such as moving lights or modifying the albedo color of objects, which can trigger the blackouts.

Currently, this remains the most critical limitation of the "gi" pass, as it makes the algorithm unreliable for real-world use cases.

## Performance

This is not a single issue, but rather a collection of things that nagatively impact performance.

### Memory bandwidth

This seems to be the most significant performance bottleneck (as it quite always is with deferred rederers). The "gi" pass relies on multiple texture inputs, and passing large textures around put a lot of pressure on the GPU. Setting the bit depth of each individual texture and shader to the minimum acceptable value greatly speeds up the process. At the moment, i kept every input and shader at float32, willing to reduce the bit depth of each input and processing stage to see where we can save some memory.

Memory issues could be partially reduced by better packing render targets. Currently, we have some "free slots" in our render targets. This is the current setup:

![](./images/current_render_targets.png)

There are many unused channels in the G-buffer. By packing small bit depth data into larger bit depth container, we could remove two render targets, saving a total of 64 bits of memory per pixel:

![](./images/packed_render_targets.png)

Still, the cost of packing/unpacking data must considered.

Moreover, the DEPTHPEEL render targets is used for ray-tracing operations only, which happen at half-resolution - I'd like to try rendering such target at half-res directly, to cut it's memory footprint to a quarter.

On the same line, i'm storing the index of the samples from the environment as a direction. This consumes 3 channels of a texture and forces use to use another output other than the reservoir texture. I'd like to try using a different method to store such indexes. For example, i could transform cartesian coordinates into polar coordinates, and use a single wrapped value to store the direction; this comes at the additional cost of encoding/deconding operations and (propably) a precision loss. Still, it may be worth it anyway (in particular for the diffuse component, where directional precision is not necessary since we're fetching from LoD = 1).

There're many operations i keep repeating, such as orthonormal basis computation - i wonder if it may be worth to compute it once and pass it as textures.

### Raytracing improvements

At the moment, raytracing is employed in reservoir validation and in sample gathering for reflections. Screen space raytracing happens by marching along a ray while depth testing. I'm already trying to avoid under/over stepping, but i think the tracing operations could be greatly improved. I'd like to employ an acceleration structure to speed up the process, building a depth hierarchy storing the min and max depths into higher and higer texture mip levels. These are some resources that could help figuring out how to implement such an acceleration structure:
https://research.nvidia.com/sites/default/files/pubs/2015-08_An-Adaptive-Acceleration/AcceleratedSSRT_HPG15.pdf
https://selgrad.org/publications/2017_hpg_HBSS.pdf
https://sugulee.wordpress.com/2021/01/19/screen-space-reflections-implementation-and-optimization-part-2-hi-z-tracing-method/
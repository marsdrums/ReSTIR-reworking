
vec2 reproject(in vec3 p){
    vec4 proj = projmat * vec4(p,1);
    return (texDim-1) * (0.5*proj.xy/proj.w + 0.5);
}

float rayPlaneIntersectionUD(float t, vec3 ro, vec3 rd){

    vec3 N = rd.y > 0.0 ? jit_in.U : jit_in.D;
    return min(t, -dot(ro,N) / max(0.05, dot(rd,N)));
}

float rayPlaneIntersectionLR(float t, vec3 ro, vec3 rd){

    vec3 N = rd.x > 0.0 ? jit_in.R : jit_in.L;
    return min(t, -dot(ro,N) / max(0.05, dot(rd,N)));
}

float rayCapsIntersection(float t, vec3 ro, vec3 rd){

    float offset = rd.z > 0 ? nearClip : -farClip;
    float numerator = -ro.z*sign(rd.z) - offset;
    return min(t, numerator / max(0.05, rd.z) );
}

float rayFrustumIntersection(vec3 ro, vec3 rd){

    float t = 999999999;

    //ray intersection with the frustum planes
    t = rayPlaneIntersectionUD(t, ro, rd);
    t = rayPlaneIntersectionLR(t, ro, rd);

    //ray intersection with the frustum caps
    t = rayCapsIntersection(t, ro, rd);

    return t;
}

vec4 raytrace(vec3 ro, vec3 rd){

    vec3 endPos = ro + rd*rayFrustumIntersection(ro, rd);
    vec2 endFrag = reproject(endPos);

    // Use Manhattan distance
    vec2 fragDist = endFrag - jit_in.uv;
    float numSteps = abs(fragDist.x) + abs(fragDist.y);

    float coarse_step = 6;
    float step = coarse_step / numSteps;
    vec2 fragStep = fragDist * step;

    vec2 testFrag = jit_in.uv;
    float numerator = ro.z*endPos.z;
    float divisor = endPos.z;
    float divisorStep = (ro.z-endPos.z) * step;

    float expectedDepth;
    vec4 sampledDepth;

    //corase search
    for( float i = step; i < 0.9; i+=step ){

        //march on the ray
        testFrag += fragStep; 

        //couldn't avoid this...
        if( testFrag.x < 0.0 || 
            testFrag.y < 0.0 || 
            testFrag.x >= texDim.x || 
            testFrag.y >= texDim.y){

                //to sample from the environment map
                vec4(rd, -1);
            } 

        divisor += divisorStep;

        expectedDepth = numerator / divisor;

        //fetch depth
        sampledDepth = texelFetch(depthsTex, ivec2(testFrag)).z;

        if( (sampledDepth.x > expectedDepth && expectedDepth > sampledDepth.y) ||
            (sampledDepth.z > expectedDepth && expectedDepth > sampledDepth.w) ){

            testFrag -= fragStep; 
            divisor -= divisorStep;
            fragStep /= coarse_step;
            divisorStep /= coarse_step;

            for( float k = 0; k <= 1; k += 1 / coarse_step ){

                //march on the ray
                testFrag += fragStep; 
                divisor += divisorStep;

                expectedDepth = numerator / divisor; // Use perspective-aware division

                //fetch depth
                sampledDepth = texture(depthsTex, testFrag).z;

                if( (sampledDepth.x > expectedDepth && expectedDepth > sampledDepth.y) ||
                    (sampledDepth.z > expectedDepth && expectedDepth > sampledDepth.w) ){

                    vec4(testFrag,0,1);
                }       
            } 
        }
    }
}
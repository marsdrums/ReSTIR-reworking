bool shadowRay(in sample this_s, in sample test_s, inout uint seed){

    float num_iterations = min(10, length(test_s.uv - this_s.uv));
    float step = 1 / num_iterations;
    float start = step * (1 + RandomFloat01(seed) - 0.5);

    float numerator = this_s.pos.z * test_s.pos.z;
    float divisor_end = 1 / test_s.pos.z;
    float divisor_start = 1 / this_s.pos.z;

    float e;
    float expected_depth;
    vec2 test_uv;
    vec4 sampled_depth;

    for(float i = start; i < 1; i += step){ //make a better tracing

        //e = i*i;
        test_uv = mix(this_s.uv, test_s.uv, i);

        expected_depth = numerator * mix(divisor_end, divisor_start, i);

        sampled_depth = texture(depthsTex, test_uv);

        if (    (sampled_depth.r > expected_depth && expected_depth > sampled_depth.g) || 
                (sampled_depth.b > expected_depth && expected_depth > sampled_depth.a) ){
            return false;
        }
    }
    return true;
}

bool shadowRayForEnv(in sample this_s, in sample test_s){

    //return true;
    vec3 end_pos = this_s.pos + test_s.nor*20; 

    vec4 projP = projmat * vec4(end_pos, 1);
    vec2 end_uv = (texDim-1) * (0.5*projP.xy/projP.w + 0.5);//( textureMatrix * vec4(projP.xy,0,1) ).xy;

    float num_iterations = 30;//min(40, length(test_s.uv - end_uv) );
    float step = 1 / num_iterations;
    float start = 0.01;//step * (RandomFloat01(seed) + 0.5);
    float numerator = this_s.pos.z * end_pos.z;
    vec4 sampled_depth;
    float expected_depth;
    vec2 test_uv;
    float eps = 0.05;

    for(float i = start; i < 1; i += step){ //make a better tracing

        test_uv = mix(this_s.uv, end_uv, i);

        //if(test_uv.x < 0 || test_uv.y < 0 || test_uv.x >= texDim.x || test_uv.y >= texDim.y) return true;

        expected_depth = numerator / mix(end_pos.z, this_s.pos.z, i);

        if(expected_depth > 0) return true;

        sampled_depth = texelFetch(depthsTex, ivec2(test_uv));

        if (    (sampled_depth.r > expected_depth+eps && expected_depth > sampled_depth.g+eps) || 
                (sampled_depth.b > expected_depth+eps && expected_depth > sampled_depth.a+eps) ){
            return false;
        }
    }
    return true;
}


/*
//__________________________________________//
//         ray frustum intersection         //
//__________________________________________//

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

bool shadowRayForEnv(in sample this_s, in sample test_s){

    //Compute reflections
    vec3 endPos = this_s.pos + this_s.nor*rayFrustumIntersection(this_s.pos, this_s.nor);
    vec4 proj = projmat * vec4(endPos,1);
    vec2 endFrag = (texDim-1) * (0.5*proj.xy/proj.w + 0.5);

    // Use Manhattan distance
    vec2 fragDist = endFrag - jit_in.uv;
    float numSteps = abs(fragDist.x) + abs(fragDist.y);

    float coarse_step = 20;
    float step = coarse_step / numSteps;
    vec2 fragStep = fragDist * step;

    vec2 testFrag = jit_in.uv;
    float numerator = this_s.pos.z*endPos.z;
    float divisor = endPos.z;
    float divisorStep = (this_s.pos.z-endPos.z) * step;

    float expectedDepth;
    vec4 sampledDepth;

    testFrag += fragStep;
    divisor += divisorStep;

    //corase search
    for( float i = step; i < 1; i +=step ){

        //march on the ray
        testFrag += fragStep; 

        //couldn't avoid this...
        if( testFrag.x < 0.0 || 
            testFrag.y < 0.0 || 
            testFrag.x >= texDim.x || 
            testFrag.y >= texDim.y) return true;;

        divisor += divisorStep;
        expectedDepth = numerator / divisor;

        //fetch depth
        sampledDepth = texelFetch(depthsTex, ivec2(testFrag));

        if( (sampledDepth.x >= expectedDepth && expectedDepth >= sampledDepth.y) ||
            (sampledDepth.z >= expectedDepth && expectedDepth >= sampledDepth.w)){
            return false;
        }
    }
    return true;
}
*/

bool shadowRay(in sample this_s, in sample test_s, inout uint seed){

    float num_iterations = length(test_s.uv - this_s.uv);
    float step = 1 / num_iterations;
    float start = step * (1 + RandomFloat01(seed) - 0.5);

    for(float i = start; i < 1; i += step){ //make a better tracing

        vec2 test_uv = mix(this_s.uv, test_s.uv, i);

        float expected_depth = (this_s.pos.z * test_s.pos.z) / mix(test_s.pos.z, this_s.pos.z, i);

        vec4 sampled_depth = texture(depthsTex, test_uv);

        if (    (sampled_depth.r > expected_depth && expected_depth > sampled_depth.g) || 
                (sampled_depth.b > expected_depth && expected_depth > sampled_depth.a) ){
            return false;
        }
    }
    return true;
}

bool shadowRayForEnv(in sample this_s, in sample test_s, inout uint seed, in mat4 textureMatrix){

    //return false;

    vec3 end_pos = this_s.pos + test_s.nor*6; 

    vec4 projP = projmat * vec4(end_pos, 1);
    projP.xy = (projP.xy/projP.w) * 0.5 + 0.5;
    vec2 end_uv = ( textureMatrix * vec4(projP.xy,0,1) ).xy;
    float num_iterations = 200;//length(test_s.uv - end_uv);
    float step = 1 / num_iterations;
    float start = 0.02;//step;//RandomFloat01(seed)*0.01;//step * (RandomFloat01(seed) + 0.5);

    for(float i = start; i < 1; i += step){ //make a better tracing

        vec2 test_uv = mix(this_s.uv, end_uv, i);

        if(test_uv.x < 0 || test_uv.y < 0 || test_uv.x >= texDim.x || test_uv.y >= texDim.y) return true;

        float expected_depth = (this_s.pos.z * end_pos.z) / mix(end_pos.z, this_s.pos.z, i);

        vec4 sampled_depth = texelFetch(depthsTex, ivec2(test_uv));

        if (    (sampled_depth.r > expected_depth && expected_depth > sampled_depth.g) || 
                (sampled_depth.b > expected_depth && expected_depth > sampled_depth.a) ){
            return false;
        }
    }
    return true;
}
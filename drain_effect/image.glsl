const float STRENGTH = 0.3;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 target = iMouse.xy / iResolution.xy;
    
    //offset the uv (radial since we normalise the dir)
    vec2 dir = normalize(uv - target);
    uv += dir * STRENGTH * ((sin(iTime) + 1.0) / 2.0);
    
    //if outside the texture region, black out the texture
    if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
        fragColor = vec4(vec3(0.0), 1.0);
        return;
    }
    
    fragColor = texture(iChannel0, uv);
}
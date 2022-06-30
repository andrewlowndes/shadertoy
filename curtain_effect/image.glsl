const float NUM_PLEATS = 20.0;
const float MAX_SHADOW = 0.3;
const float PLEAT_HEIGHT = 4.0; // pixel wave amplitude
const float GRAB_AMOUNT = 0.5;

const float TAU = 6.2831852;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    vec2 grabPos = iMouse.xy / iResolution.xy;
    
    //move left and right
    uv.x = (uv.x - grabPos.x) / (1.0 - grabPos.x);
    
    //grab distance offset
    uv.x += abs(uv.y - grabPos.y) * (1.0 - uv.x) * GRAB_AMOUNT * grabPos.x;
    
    //pleats
    float pleatZ = (cos(uv.x * TAU * NUM_PLEATS) + 1.0) / 2.0;
    
    //pleat position offset
    uv.y += pleatZ * PLEAT_HEIGHT * grabPos.x / iResolution.y;
    
    //no texture hit
    if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
        fragColor = vec4(vec3(0.0), 1.0);
        return;
    }
    
    //pleat shadow
    vec3 shadow = vec3(pleatZ * MAX_SHADOW * clamp(grabPos.x * 2.0, 0.0, 1.0));
    shadow = mix(shadow, vec3(MAX_SHADOW), grabPos.x); //fade to solid colour to hide aliasing

    fragColor = texture(iChannel0, uv) - vec4(shadow, 0.0);
}
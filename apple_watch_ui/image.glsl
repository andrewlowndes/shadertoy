float circ(in float x) {
    return sqrt(1.0 - pow(x - 1.0, 2.0));
}

float circle(in vec2 pos, in float radius) {
    return smoothstep(0.0, fwidth(pos.y), pow(radius, 2.0) - (pow(pos.x - 0.5, 2.0) + pow(pos.y - 0.5, 2.0)));
}

vec2 repeat(in vec2 pos, in float count) {
    return mod(pos * count, 1.0);
}

const float PI = 3.14159;
const float numCircles = 10.0;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.y;
    vec2 offset = (length(iMouse.xy) > 0.0 ? iMouse.xy : (vec2(sin(iTime), cos(iTime)) * 100.0));
    vec2 pos = uv - offset/iResolution.xy;
    float aspect = iResolution.y / iResolution.x;

    //rather than use actual distance, keep the square shape to match the canvas size
    vec2 screenCenter = vec2(0.5 / aspect, 0.5);
    vec2 dir = (uv - screenCenter);
    float dist = max(abs(dir.x * aspect), abs(dir.y));
    
    float circleRadius = 0.5 * circ(0.5 - dist);
    
    //alternating pattern
    vec2 newPos = pos + vec2(floor(mod(pos.y * numCircles, 2.0)) * 0.5/numCircles, 0.0);
    
    float result = circle(repeat(newPos, numCircles), circleRadius);
    
    //associate a random colour to each circle
    vec3 col = texture(iChannel0, newPos / 64.0 * numCircles).rgb;
    
    fragColor = vec4(result * col, 1.0);
}

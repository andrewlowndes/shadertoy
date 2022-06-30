float pointRadius = 4.0;

vec2 project(in vec2 a, in vec2 b) {
    return b * (dot(a, b) / dot(b, b));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float scale = 1.0 / max(iResolution.x, iResolution.y);
    vec2 fragPos = fragCoord * scale;

    //arc from three points
    vec2 a = vec2(0.1);
    vec2 b = (length(iMouse.xy) > 0.0 ? iMouse.xy * scale : vec2(0.2, 0.3));
    vec2 c = (vec2(0.7, 0.2) + vec2(sin(iTime), cos(iTime)) * 0.1);
    
    //based on https://mathopenref.com/arcradius.html
    vec2 dir = c - a;
    vec2 mid = mix(a, c, 0.5);
    float width = length(dir);
    
    vec2 normal = normalize(b - (project(b - a, dir) + a));
    
    //could force the arc to be one way by basing the normal on the direction of the points
    //vec2 normal = normalize(vec2(-dir.y, dir.x));
    
    float height = length(mid - b);
    
    float radius = max(width/2.0, height/2.0 + (width*width) / (8.0*height));
    vec2 position = mid - (normal * (radius - height));
   
    //re-align b to match the arc top
    b = mid + normal * height;
    
    //draw points
    float distToPoint = min(min(length(fragPos - a), length(fragPos - b)), length(fragPos - c));
    float pointSize = pointRadius * scale;
    
    if (distToPoint < pointSize) {
        fragColor = vec4(vec3(0.0, 1.0, 1.0) * smoothstep(pointSize, pointSize - scale, distToPoint), 1.0);
        return;
    }
    
    //draw arc
    
    // - test point is on the correct side of the line
    if (determinant(mat2(fragPos - a, vec2(-normal.y, normal.x))) < 0.0) {
        fragColor = vec4(vec3(0.0), 1.0);
        return;
    }
    
    // - test the signed distance to the arc circle
    float dist = length(fragPos - position);
    fragColor = vec4(vec3(0.0, 0.0, 1.0) * smoothstep(radius, radius - scale, dist), 1.0);
}

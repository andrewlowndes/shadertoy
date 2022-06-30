/**
* A new method of rendering a quadratic bezier, inspired by the Loop/Blinn paper
* https://developer.nvidia.com/gpugems/gpugems3/part-iv-image-effects/chapter-25-rendering-vector-art-gpu
*
* Designed to be as fast as possible
* The space is transformed with a matrix so that an aligned quadratic (y=x^2) is rendered
*
* MIT License
*/
float pointRadius = 3.0;

#define AA //comment out for jaggies

//transform from 0->1 into -1->1 with inverted y so the per-pixel operation is as simple as possible
const mat3 normalisedSpace = mat3(
   2.0, 0.0, -1.0,
   0.0, -2.0, 1.0,
   0.0, 0.0, 1.0
);

bool sampleCurve(in vec2 pos, in mat3 transform) {
    vec3 uv = vec3(pos, 1.0) * transform;
    //uv.xy /= uv.z; //not needed since no z transform
    
    return uv.y <= 1.0 && uv.x*uv.x < uv.y;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float pixSize = 1.0 / max(iResolution.x, iResolution.y);
    float halfPixSize = pixSize / 2.0;
    
    vec2 fragPos = fragCoord * pixSize;
    
    //bezier curve
    vec2 a = vec2(100.0, 100.0) * pixSize;
    vec2 b = (length(iMouse.xy) > 0.0 ? iMouse.xy : vec2(200.0, 300.0)) * pixSize;
    vec2 c = vec2(400.0 + sin(iTime) * 100.0, 200.0 + cos(iTime) * 100.0) * pixSize;
    
    //determine the matrix vectors (only need to do once per curve not per-pixel)
    vec2 right = c - a;
    vec2 up = b - mix(a, c, 0.5);
    vec2 pos = a;

    mat3 transform = inverse(mat3(
        right.x, up.x, pos.x,
        right.y, up.y, pos.y,
        0.0, 0.0, 1.0
    )) * normalisedSpace;
    
    //draw points
    float distToPoint = min(min(length(fragPos - a), length(fragPos - b)), length(fragPos - c));
    
    if (distToPoint < pointRadius * pixSize) {
        fragColor = vec4(0.0, 0.0, 1.0, 1.0);
        return;
    }
    
    //draw our curve - per pixel
    #ifdef AA
        //antialiasing - prob cheaper to just take multiple samples than use a distance function
        float colour = (
            float(sampleCurve(fragPos, transform)) +
            float(sampleCurve(fragPos + vec2(0.0, halfPixSize), transform)) +
            float(sampleCurve(fragPos + vec2(halfPixSize, 0.0), transform)) +
            float(sampleCurve(fragPos + halfPixSize, transform))
        ) / 4.0;
    #else
        float colour = float(sampleCurve(fragPos, transform));
    #endif
    
    fragColor = vec4(colour, 0.0, 0.0, 1.0);
}

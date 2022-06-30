float sampleBuffer(in float t) {
    int channelWidth = int(iChannelResolution[0].x);

    int channelIndex = int(t) % 4;
    int pixIndex = int(t) / 4;
    ivec2 bufferIndex = ivec2(pixIndex % channelWidth, pixIndex / channelWidth);
    
    //could we interpolate the value in combination with linear filtering?
    return symmetricToNormalised(texelFetch(iChannel0, bufferIndex, 0)[channelIndex]);
}

//https://www.shadertoy.com/view/3tdSDj
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sampleCoverage(in float y, in float y2, in float actualY) {
    //get the shortest distance from a virtual center point to the line formed from y and y2
    vec2 from = vec2(0.0, y);
    vec2 to = vec2(1.0, y2);
    vec2 mid = vec2(0.5, actualY);
    
    return clamp(sdSegment(mid, from, to), 0.0, 1.0);
}

const int samples = 8;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float zoomAmount = sampleRate / iResolution.x; //fit one second on the screen
    
    //TODO: allow dragging and zooming using the mouse drag axis
    float t = fragCoord.x * zoomAmount;
    
    //split the pixel into slices for anti-aliasing (needs work - replace with some real integration)
    float pixStep = zoomAmount / float(samples);
    
    float col = 0.0;
    float prevY = sampleBuffer(t) * iResolution.y;
    float nextY;
    
    for (int i = 0; i < samples; i++) {
        t += pixStep;
        nextY = sampleBuffer(t) * iResolution.y;
        col += sampleCoverage(prevY, nextY, fragCoord.y);
        prevY = nextY;
    }
    
    col /= float(samples);
    
    
    fragColor = vec4(col, col, col, 1.0);
}

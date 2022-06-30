//compute our complex waveform here
float makeWaveform(float t) {
    float amplitude = sinWave(t, 40.0, 0.0, 1.0);
    
    amplitude *= expDecay(t, 2.0);
    
    return amplitude;
}

const float sampleStep = 1.0 / sampleRate;

//store the waveform in a buffer (matches the window size in shadertoy)
//640 x 360 x 4 channels gives ~ 20 seconds of samples at 44.1kHz in a single frame
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    //store the time across the whole buffer image (x and y)
    float t = (floor(fragCoord.x) + (floor(fragCoord.y) * iResolution.x)) * sampleStep * 4.0;
    
    //lets pack the time into each channel too (each channel is 32-bit float)
    fragColor = vec4(makeWaveform(t), makeWaveform(t+sampleStep), makeWaveform(t+sampleStep), makeWaveform(t+sampleStep));
}

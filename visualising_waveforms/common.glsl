const float PI2 = 6.28318530718;
const float E = 2.71828182845;

const float sampleRate = 44100.0;

float sinWave(in float t, in float frequency, in float phase, in float amplitude) {
    return sin(t * PI2 * frequency + phase) * amplitude;
}

float expDecay(in float t, in float k) {
    return pow(E, -k * t);
}

//ranges
// 0 -> 1, normalised
// -1 -> 1, symmetric

float normalisedToSymmetric(in float t) {
    return t * 2.0 - 1.0;
}

float symmetricToNormalised(in float t) {
    return (t + 1.0) / 2.0;
}

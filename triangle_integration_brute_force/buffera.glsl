//just evaluate the one triangle for now and put the pixel in a buffer so we can reuse across many pixels
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    Triangle tri = getTriangle(iMouse.xy);
    
    if (fragCoord.x < 1.0 && fragCoord.y < 1.0) {
       fragColor = triangleCoverage(tri, iChannel0);
    } else {
       fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
}

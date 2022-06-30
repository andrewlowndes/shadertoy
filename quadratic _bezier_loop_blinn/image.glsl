/**
* An example of rendering quadratic beziers via interpolation
* Not efficient doing the whole thing in a fragment shader, just for demo purposes
* 
* Barycentric code based on https://www.shadertoy.com/view/lsl3Wn by nuclear 
* Technique based on the Charles Loop and Jim Blinn solution from:
* https://developer.nvidia.com/gpugems/gpugems3/part-iv-image-effects/chapter-25-rendering-vector-art-gpu
*/

float circleDist = 3.0;
float EPSILON = 0.00001;
vec3 normal = vec3(0.0, 0.0, 1.0);

vec4 white = vec4(1.0, 1.0, 1.0, 1.0); //rgba
vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
vec4 blue = vec4(0.0, 0.0, 1.0, 1.0);

//interpolants at each triangle coord
vec2 d = vec2(0.0, 0.0);
vec2 e = vec2(0.5, 0.0);
vec2 f = vec2(1.0, 1.0);

//utils
vec3 barycentric(in vec3 v0, in vec3 v1, in vec3 v2, in vec3 p, in vec3 normal)
{
	float area = dot(cross(v1 - v0, v2 - v0), normal);

	if(abs(area) < EPSILON) {
		return vec3(0.0, 0.0, 0.0);
	}

	vec3 pv0 = v0 - p;
	vec3 pv1 = v1 - p;
	vec3 pv2 = v2 - p;
	
	vec3 asub = vec3(dot(cross(pv1, pv2), normal),
					 dot(cross(pv2, pv0), normal),
					 dot(cross(pv0, pv1), normal));
	return abs(asub) / abs(area);
}

//start
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 fragPos = vec3(fragCoord, 0.0);
    
    //triangle
    vec3 a = vec3(100.0, 100.0, 0.0);
    vec3 b = vec3(iMouse.xy, 0.0);
    vec3 c = vec3(400.0, 200.0, 0.0);
    
    //draw triangle points
    float insidePoint = step(circleDist, length(fragPos - a));
    insidePoint *= step(circleDist, length(fragPos - b));
    insidePoint *= step(circleDist, length(fragPos - c));
    
    if (insidePoint < EPSILON) {
        fragColor = black;
        return;
    }
    
    //barycentric coords in the triangle for using as weights
    vec3 bary = barycentric(a, b, c, fragPos, normal);
    
    float baryLength = bary.x + bary.y + bary.z;
    if (baryLength < EPSILON || baryLength - EPSILON > 1.0) {
        //outside triangle
        fragColor = white;
        return;
    }
    
    //interpolation
    vec2 uv = (d * bary.x) + (e * bary.y) + (f * bary.z);
    
    //antialiasing using derivatives
    vec2 px = dFdx(uv);   
    vec2 py = dFdy(uv);   

    //chain rule    
    float fx = (2.0*uv.x)*px.x - px.y;   
    float fy = (2.0*uv.x)*py.x - py.y;   

    //signed distance  
    float sd = (uv.x*uv.x - uv.y) / sqrt(fx*fx + fy*fy); 
    float alpha = 0.5 - sd;
    
    if (alpha < 0.0) {
        fragColor = white;
        return;
    }
    
    fragColor = mix(white, blue, alpha);
    return;
}
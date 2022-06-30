// Ray Tracing Quadric shapes (with box constraint)
// based on the paper: Ray Tracing Arbitrary Objects on the GPU, A. Wood et al
const mat4 cylinder = mat4(
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, -0.25
);

const mat4 sphere = mat4(
    4.0, 0.0, 0.0, 0.0,
    0.0, 4.0, 0.0, 0.0,
    0.0, 0.0, 4.0, 0.0,
    0.0, 0.0, 0.0, -1.0
);

const mat4 ellipticParaboloid = mat4(
    4.0, 0.0, 0.0, 0.0,
    0.0, 4.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0,
    0.0, 0.0, 1.0, 0.0
);

const mat4 hyperbolicParaboloid = mat4(
    4.0, 0.0, 0.0, 0.0,
    0.0, -4.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0,
    0.0, 0.0, 1.0, 0.0
);

const mat4 circularCone = mat4(
    4.0, 0.0, 0.0, 0.0,
    0.0, -4.0, 0.0, 0.0,
    0.0, 0.0, 4.0, 0.0,
    0.0, 0.0, 0.0, 0.0
);

const mat4 quadraticPlane = mat4(
    1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 1.0, 0.0, 0.0
);

const mat4 hyperbolicPlane = mat4(
    1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 2.0,
    0.0, 0.0, 0.0, 0.0,
    0.0, 2.0, 0.0, 0.0
);

const mat4 intersectingPlanes = mat4(
    0.0, 1.0, 0.0, 0.0,
    1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0
);

const float EPSILON = 0.000001;

const int samples = 4; //per x,y per fragment

bool getPointAtTime(in float t, in vec4 ro, in vec4 rd, out vec3 point) {
    if (t < 0.0) {
        return false;
    }

    point = ro.xyz + t * rd.xyz;
    
    //constrain to a box
    return all(greaterThanEqual(point, vec3(-0.5 - EPSILON))) && all(lessThanEqual(point, vec3(0.5 + EPSILON)));
}

//adapted from https://iquilezles.org/articles/intersectors
bool intersectBox(in vec4 ro, in vec4 rd, out vec4 outPos)
{
    vec3 m = 1.0/rd.xyz;
    vec3 n = m*ro.xyz;
    vec3 k = abs(m);
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.0) return false; // no intersection
    outPos = ro + rd * tN;
    return true;
}

bool intersectQuadric(in mat4 shape, in vec4 ro, in vec4 rd, out vec3 point) {
    vec4 rda = shape * rd;
    vec4 roa = shape * ro;
    
    //quadratic equation
    float a = dot(rd, rda);
    float b = dot(ro, rda) + dot(rd, roa);
    float c = dot(ro, roa);
    
    if (abs(a) < EPSILON) {
        if (abs(b) < EPSILON) {
            return getPointAtTime(c, ro, rd, point);
        }
        
        return getPointAtTime(-c/b, ro, rd, point);
    }

    float square = b*b - 4.0*a*c;

    if (square < EPSILON) {
        return false; //no hit
    }

    float temp = sqrt(square);
    float denom = 2.0 * a;

    float t1 = (-b - temp) / denom;
    float t2 = (-b + temp) / denom;
    
    //draw both sides but pick the closest point
    vec3 p1 = vec3(0.0);
    vec3 p2 = vec3(0.0);

    bool hasP1 = getPointAtTime(t1, ro, rd, p1);
    bool hasP2 = getPointAtTime(t2, ro, rd, p2);
    
    if (!hasP1) {
        point = p2;
        return hasP2;
    }
    
    if (!hasP2) {
        point = p1;
        return true;
    }

    if (t1 < t2) {
        point = p1;
    } else {
        point = p2;
    }

    return true;
}

vec3 drawQuadric(in mat4 shape, in vec4 ro, in vec4 rd) {
    vec3 collPoint = vec3(0.0);
    
    //intersect the bounding box first and use the intersected origin for solving the quadric
    //idea from mla: https://www.shadertoy.com/view/wdlBR2
    if (intersectBox(ro, rd, ro) && intersectQuadric(shape, ro, rd, collPoint)) {
        //some simple fake shading for now
        return normalize((shape * vec4(collPoint, 1.0)).xyz) / 2.0 + 0.5;
    } else {
        //otherwise return black for now
        return vec3(0.0);
    }
}

//utils
mat4 rotateX(in float rads) {
    return mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, cos(rads), -sin(rads), 0.0,
        0.0, sin(rads), cos(rads), 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 rotateY(in float rads) {
	return mat4(
        cos(rads), 0.0, sin(rads), 0.0,
        0.0, 1.0, 0.0, 0.0,
        -sin(rads), 0.0, cos(rads), 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    //camera
    float aspectRatio = iResolution.x / iResolution.y;
    vec3 rayTarget = vec3((fragCoord/iResolution.xy) * 2.0 - 1.0, 1.0);
    rayTarget.y /= aspectRatio;
    vec3 rayPosition = vec3(0.0, 0.0, -10.0);
    
    vec2 rayStep = (1.0 / iResolution.xy) / float(samples);
    
    //rotate all of the objects
    float rotAmount = iTime;
    mat4 rotMatrix = rotateX(rotAmount) * rotateY(rotAmount * 0.5);
    
    vec3 result = vec3(0.0);
    
    for (int y=0; y<samples; y++) {
        for (int x=0; x<samples; x++) {
            vec3 rayDir = normalize(rayTarget + vec3(rayStep * vec2(x, y), 0.0) - rayPosition);
            vec4 newDir = vec4(rayDir, 0.0) * rotMatrix;

            //quadrics
            vec3 pixel = vec3(0.0);

            pixel += drawQuadric(cylinder, vec4(rayPosition - vec3(-3.0, 1.0, 30.0), 1.0) * rotMatrix, newDir);
            pixel += drawQuadric(sphere, vec4(rayPosition - vec3(-1.5, 1.0, 30.0), 1.0) * rotMatrix, newDir);
            pixel += drawQuadric(ellipticParaboloid, vec4(rayPosition - vec3(0.0, 1.0, 30.0), 1.0) * rotMatrix, newDir);
            pixel += drawQuadric(hyperbolicParaboloid, vec4(rayPosition - vec3(1.5, 1.0, 30.0), 1.0) * rotMatrix, newDir);
            pixel += drawQuadric(circularCone, vec4(rayPosition - vec3(3.0, 1.0, 30.0), 1.0) * rotMatrix, newDir);
            pixel += drawQuadric(quadraticPlane, vec4(rayPosition - vec3(-2.0, -1.0, 30.0), 1.0) * rotMatrix, newDir);
            pixel += drawQuadric(hyperbolicPlane, vec4(rayPosition - vec3(0.0, -1.0, 30.0), 1.0) * rotMatrix, newDir);
            pixel += drawQuadric(intersectingPlanes, vec4(rayPosition - vec3(2.0, -1.0, 30.0), 1.0) * rotMatrix, newDir);
        
            result += clamp(pixel, 0.0, 1.0);
        }
    }
    
    fragColor = vec4(result / float(samples * samples), 1.0);
}

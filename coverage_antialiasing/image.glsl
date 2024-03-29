// from https://github.com/andrewlowndes/perfect-antialiasing
const float EPSILON = 0.0001;

vec4 sort(vec4 val) {
  float a = min(val.x, val.y);
  float b = max(val.x, val.y);
  float c = min(val.z, val.w);
  float d = max(val.z, val.w);

  float h = max(a, min(b, c));
  float i = min(d, max(b, c));

  return vec4(min(a, c), min(h, i), max(h, i), max(b, d));
}

float det2(vec2 p1, vec2 p2) {
  return (p1.x * p2.y) - (p1.y * p2.x);
}

float timeAtPos(float startPos, float dir, float newPos) {
  if (abs(dir) < EPSILON) {
      return 0.0;
  }

  return clamp((newPos - startPos) / dir, 0.0, 1.0);
}

bool squareInTriangle(vec2 minPos, vec2 maxPos, vec2 p1, vec2 p2, vec2 p3){
    vec2 a = p2 - p1;
    vec2 b = p3 - p1;
    float denom = det2(a, b);

    vec2 c = minPos - p1;
    float s = det2(c, b) / denom;   
    float t = -det2(c, a) / denom;
    
    if (s < 0.0 || t < 0.0 || (s+t) > 1.0) {
        return false;
    }

    c = maxPos - p1;
    s = det2(c, b) / denom;   
    t = -det2(c, a) / denom;
    
    if (s < 0.0 || t < 0.0 || (s+t) > 1.0) {
        return false;
    }
    
    c = vec2(maxPos.x, minPos.y) - p1;
    s = det2(c, b) / denom;   
    t = -det2(c, a) / denom;
    
    if (s < 0.0 || t < 0.0 || (s+t) > 1.0) {
        return false;
    }

    c = vec2(minPos.x, maxPos.y) - p1;
    s = det2(c, b) / denom;   
    t = -det2(c, a) / denom;
    
    if (s < 0.0 || t < 0.0 || (s+t) > 1.0) {
        return false;
    }

    return true;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //triangle coords
    vec2 vPrevPos = vec2(100.0, 100.0);
    vec2 vPos = vec2(360.0, 360.0);
    vec2 vNextPos = vec2(220.0, 120.0);

    //vPrevPos.x = (vPrevPos.x - iResolution.x/2.0) * sin(iTime) + iResolution.x/2.0;
    //vPrevPos.y = (vPrevPos.y - iResolution.y/2.0) * cos(iTime) + iResolution.y/2.0;

    vPos = iMouse.xy;

    vec4 bounds = vec4(
    min(min(vPrevPos, vPos), vNextPos),
    max(max(vPrevPos, vPos), vNextPos)
    );

    //outside triangle aabb
    if (fragCoord.x < bounds.x || fragCoord.y < bounds.y || fragCoord.x > bounds.z || fragCoord.y > bounds.w) {
      fragColor = vec4(0.0, 0.0, 0.0, 1.0);
      return;
    }

    //check if the pixel is fully enclosed
    vec2 pixelMin = floor(fragCoord.xy);
    vec2 pixelMax = pixelMin + 1.0;

    if (squareInTriangle(pixelMin, pixelMax, vPos, vPrevPos, vNextPos)) {
        fragColor = vec4(1.0, 0.0, 0.0, 1.0);
        return;
    }
   
    //intersect the triangle with the pixel bounds
    vec2 e1 = vPos - vPrevPos;
    vec2 e2 = vNextPos - vPos;
    vec2 e3 = vPrevPos - vNextPos;

    vec4 firstLineTs = sort(vec4(
        timeAtPos(vPrevPos.x, e1.x, pixelMin.x),
        timeAtPos(vPrevPos.x, e1.x, pixelMax.x),
        timeAtPos(vPrevPos.y, e1.y, pixelMin.y),
        timeAtPos(vPrevPos.y, e1.y, pixelMax.y)
    ));

    vec2 p1 = clamp(vPrevPos + e1 * firstLineTs.x, pixelMin, pixelMax);
    vec2 p2 = clamp(vPrevPos + e1 * firstLineTs.y, pixelMin, pixelMax);
    vec2 p3 = clamp(vPrevPos + e1 * firstLineTs.z, pixelMin, pixelMax);
    vec2 p4 = clamp(vPrevPos + e1 * firstLineTs.w, pixelMin, pixelMax);

    vec4 secondLineTs = sort(vec4(
        timeAtPos(vPos.x, e2.x, pixelMin.x),
        timeAtPos(vPos.x, e2.x, pixelMax.x),
        timeAtPos(vPos.y, e2.y, pixelMin.y),
        timeAtPos(vPos.y, e2.y, pixelMax.y)
    ));

    vec2 p5 = clamp(vPos + e2 * secondLineTs.x, pixelMin, pixelMax);
    vec2 p6 = clamp(vPos + e2 * secondLineTs.y, pixelMin, pixelMax);
    vec2 p7 = clamp(vPos + e2 * secondLineTs.z, pixelMin, pixelMax);
    vec2 p8 = clamp(vPos + e2 * secondLineTs.w, pixelMin, pixelMax);

    vec4 thirdLineTs = sort(vec4(
        timeAtPos(vNextPos.x, e3.x, pixelMin.x),
        timeAtPos(vNextPos.x, e3.x, pixelMax.x),
        timeAtPos(vNextPos.y, e3.y, pixelMin.y),
        timeAtPos(vNextPos.y, e3.y, pixelMax.y)
    ));

    vec2 p9  = clamp(vNextPos + e3 * thirdLineTs.x, pixelMin, pixelMax);
    vec2 p10 = clamp(vNextPos + e3 * thirdLineTs.y, pixelMin, pixelMax);
    vec2 p11 = clamp(vNextPos + e3 * thirdLineTs.z, pixelMin, pixelMax);
    vec2 p12 = clamp(vNextPos + e3 * thirdLineTs.w, pixelMin, pixelMax);

    //compute the area under the formed polygon
    float polygonArea = (
        det2(p1, p2) + det2(p2, p3) + det2(p3, p4) + det2(p4, p5) +
        det2(p5, p6) + det2(p6, p7) + det2(p7, p8) + det2(p8, p9) + 
        det2(p9, p10) + det2(p10, p11) + det2(p11, p12) + det2(p12, p1)
    ) / 2.0;

    float contribution = clamp(abs(polygonArea), 0.0, 1.0);
    fragColor = vec4(contribution, 0.0, 0.0, 0.0);
}
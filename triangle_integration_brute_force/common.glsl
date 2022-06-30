struct Triangle {
    vec2 p1;
    vec2 p2;
    vec2 p3;
};

Triangle getTriangle(vec2 mouse) {
    return Triangle(vec2(20.0, 20.0), mouse, vec2(450.0, 50.0));
}

struct Aabb {
    vec2 minPos;
    vec2 maxPos;
};

struct LineEquation {
    float gradient;
    float intersect;
};

struct Line {
    vec2 p1;
    vec2 p2;
};

struct LineRange {
    vec2 pStart;
    vec2 pEnd;
    vec2 xRange;
    LineEquation equation;
};

const float epsilon = 0.00001;

float vec2Determinant(vec2 p1, vec2 p2) {
    return (p1.x * p2.y) - (p1.y * p2.x);
}

float inverseLerp(float a, float diff, float val) {
    return clamp((val - a) / diff, 0.0, 1.0);
}

vec4 intersectLineSquare(vec2 pos, vec2 dir, Aabb bounds) {
    return vec4(
        inverseLerp(pos.x, dir.x, bounds.minPos.x),
        inverseLerp(pos.x, dir.x, bounds.maxPos.x),
        inverseLerp(pos.y, dir.y, bounds.minPos.y),
        inverseLerp(pos.y, dir.y, bounds.maxPos.y)
    );
}

vec4 sort(vec4 nums) {
    float a = min(nums.x, nums.y);
    float b = max(nums.x, nums.y);
    float c = min(nums.z, nums.w);
    float d = max(nums.z, nums.w);
    float e = min(b, c);
    float f = max(b, c);
    float h = max(a, e);
    float i = min(f, d);

    return vec4(min(a, e), min(h, i), max(h, i), max(f, d));
}

LineEquation getLineEquation(Line line) {
    vec2 direction = line.p2 - line.p1;

    float gradient = direction.y / direction.x;
    float intersect = line.p1.y - line.p1.x * gradient;

    return LineEquation(gradient, intersect);
}

vec2[12] intersectTriangleSquare(Triangle triangle, Triangle edges, Aabb bounds) {
    vec4 t1s = sort(intersectLineSquare(triangle.p1, edges.p1, bounds));
    vec4 t2s = sort(intersectLineSquare(triangle.p2, edges.p2, bounds));
    vec4 t3s = sort(intersectLineSquare(triangle.p3, edges.p3, bounds));
    
    return vec2[12](
        clamp(triangle.p1 + edges.p1 * t1s.x, bounds.minPos, bounds.maxPos),
        clamp(triangle.p1 + edges.p1 * t1s.y, bounds.minPos, bounds.maxPos),
        clamp(triangle.p1 + edges.p1 * t1s.z, bounds.minPos, bounds.maxPos),
        clamp(triangle.p1 + edges.p1 * t1s.w, bounds.minPos, bounds.maxPos),

        clamp(triangle.p2 + edges.p2 * t2s.x, bounds.minPos, bounds.maxPos),
        clamp(triangle.p2 + edges.p2 * t2s.y, bounds.minPos, bounds.maxPos),
        clamp(triangle.p2 + edges.p2 * t2s.z, bounds.minPos, bounds.maxPos),
        clamp(triangle.p2 + edges.p2 * t2s.w, bounds.minPos, bounds.maxPos),
        
        clamp(triangle.p3 + edges.p3 * t3s.x, bounds.minPos, bounds.maxPos),
        clamp(triangle.p3 + edges.p3 * t3s.y, bounds.minPos, bounds.maxPos),
        clamp(triangle.p3 + edges.p3 * t3s.z, bounds.minPos, bounds.maxPos),
        clamp(triangle.p3 + edges.p3 * t3s.w, bounds.minPos, bounds.maxPos)
    );
}

void sum_line(in uvec3 range, in bool isInside, inout vec4 colour, inout int numPixels, in sampler2D texture, in Triangle triangle, in Triangle edges) {
    if (isInside) {
        for (uint x=range.x; x<range.y; x++) {
            colour += texelFetch(texture, ivec2(x, range.z), 0);
        }
    } else {
        //process each outer pixel separately so we have per-pixel shading
        uint yMax = range.z + uint(1);

        for (uint x=range.x; x<range.y; x++) {
            Aabb bounds = Aabb(vec2(x, range.z), vec2(x + uint(1), yMax));

            //as a test, determine the coverage of the triangle in outside cells and use as antialiasing
            vec2[12] polygon = intersectTriangleSquare(triangle, edges, bounds);
            
            float percentCoverage = clamp(abs((
                vec2Determinant(polygon[0], polygon[1]) +
                vec2Determinant(polygon[1], polygon[2]) +
                vec2Determinant(polygon[2], polygon[3]) +
                vec2Determinant(polygon[3], polygon[4]) +
                vec2Determinant(polygon[4], polygon[5]) +
                vec2Determinant(polygon[5], polygon[6]) +
                vec2Determinant(polygon[6], polygon[7]) +
                vec2Determinant(polygon[7], polygon[8]) +
                vec2Determinant(polygon[8], polygon[9]) +
                vec2Determinant(polygon[9], polygon[10]) +
                vec2Determinant(polygon[10], polygon[11]) +
                vec2Determinant(polygon[11], polygon[0])
            ) / 2.0), 0.0, 1.0);

            colour += texelFetch(texture, ivec2(x, range.z), 0) * percentCoverage;
        }
    }
}

float solveLineX(LineEquation equation, float y) {
    if (abs(equation.gradient) > epsilon) {
        return (y - equation.intersect) / equation.gradient;
    } else {
        return -1.0;
    }
}

LineRange getLineRange(Line line) {
    vec2 pStart;
    vec2 pEnd;
    
    //TODO: make a branchless version
    if (line.p1.y < line.p2.y) {
        pStart = line.p1;
        pEnd = line.p2;
    } else if (line.p1.y > line.p2.y) {
        pStart = line.p2;
        pEnd = line.p1;
    } else if (line.p1.x < line.p2.x) {
        pStart = line.p1;
        pEnd = line.p2;
    } else {
        pStart = line.p2;
        pEnd = line.p1;
    }

    return LineRange(
        pStart,
        pEnd,
        vec2(min(line.p1.x, line.p2.x), max(line.p1.x, line.p2.x)),
        getLineEquation(line)
    );
}

vec2 triangleMax(Triangle triangle) {
    return max(max(triangle.p1, triangle.p2), triangle.p3);
}


vec2 triangleMin(Triangle triangle) {
    return min(min(triangle.p1, triangle.p2), triangle.p3);
}

void sum_triangle(in Triangle triangle, inout vec4 colour, inout int numPixels, in sampler2D tex, in Triangle edges) {
    vec2 minPos = triangleMin(triangle);
    vec2 maxPos = triangleMax(triangle);

    Line[3] lines = Line[3](
        Line(triangle.p1, triangle.p2),
        Line(triangle.p2, triangle.p3),
        Line(triangle.p3, triangle.p1)
    );

    LineRange[3] lineRanges = LineRange[3](
        getLineRange(lines[0]),
        getLineRange(lines[1]), 
        getLineRange(lines[2])
    );

    int maxY = int(ceil(maxPos.y));
    int prevY = int(minPos.y);

    if (maxY - prevY < 1) {
        sum_line(uvec3(minPos.x, maxPos.x, prevY), false, colour, numPixels, tex, triangle, edges);
        return;
    }

    for (int y=prevY+1; y<=maxY; y++) {
        //we just need to get four numbers, the outer min and max and inner min and max values
        ivec4 range = ivec4(-1);

        for (int i=0; i<3; i++) {
            LineRange line = lineRanges[i];

            if (line.pEnd.y >= float(prevY) && line.pStart.y < float(y)) {
                float fromX = solveLineX(line.equation, float(prevY));

                if (fromX > -1.0) {
                    fromX = clamp(fromX, line.xRange.x, line.xRange.y);
                } else {
                    fromX = line.pStart.x;
                }

                float toX = solveLineX(line.equation, float(y));

                if (toX > -1.0) {
                    toX = clamp(toX, line.xRange.x, line.xRange.y);
                } else {
                    toX = line.pEnd.x;
                }

                ivec2 xRange = ivec2(min(fromX, toX), max(fromX, toX));

                if (range.x < 0) {
                    //first entry
                    range.xy = xRange;
                } else if ((xRange.x <= range.y + 1 && xRange.x >= range.x - 1) || (xRange.y <= range.y + 1 && xRange.y >= range.x - 1)) {
                    //extends the first entry
                    range.xy = ivec2(min(range.x, xRange.x), max(range.y, xRange.y));
                } else if (range.z < 0) {
                    //must be a new second range, determine if we need to swap or not to keep them ordered
                    if (xRange.x > range.y) {
                        range.zw = xRange;
                    } else {
                        range = ivec4(xRange, range.xy);
                    } 
                } else {
                    //extends the second range
                    range.zw = ivec2(min(range.z, xRange.x), max(range.w, xRange.y));
                }
            }
        }

        //we have an inside
        if (range.z > range.y) {
            sum_line(uvec3(range.x, range.y, prevY), false, colour, numPixels, tex, triangle, edges);
            sum_line(uvec3(range.y + 1, range.z - 1, prevY), true, colour, numPixels, tex, triangle, edges);
            sum_line(uvec3(range.z, range.w, prevY), false, colour, numPixels, tex, triangle, edges);
        } else {
            sum_line(uvec3(range.x, max(range.y, range.w), prevY), false, colour, numPixels, tex, triangle, edges);
        }

        prevY = y;
    }
}

float triangleArea(Triangle triangle) {
    return abs((
        vec2Determinant(triangle.p1, triangle.p2) +
        vec2Determinant(triangle.p2, triangle.p3) +
        vec2Determinant(triangle.p3, triangle.p1)
    ) / 2.0);
}

vec4 triangleCoverage(Triangle triangle, sampler2D tex) {
    float area = triangleArea(triangle);

    Triangle edges = Triangle(triangle.p2 - triangle.p1, triangle.p3 - triangle.p2, triangle.p1 - triangle.p3);

    vec4 colour = vec4(0.0);
    int numPixels = 0;

    sum_triangle(triangle, colour, numPixels, tex, edges);
    return colour / area;
}

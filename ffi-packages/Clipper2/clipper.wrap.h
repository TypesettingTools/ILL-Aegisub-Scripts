#include <iostream>
#include <stdio.h>
#include <vector>
#include <string>
#include <cmath>
#include "clipper2/clipper.h"

using namespace std;
using namespace Clipper2Lib;

int roundDouble(double n) {
    return (int)floor(n + 0.5);
}

double getPointHypto(PointD p) {
    if (p.x == 0 && p.y == 0)
        return 0;
    p.x = fabs(p.x);
    p.y = fabs(p.y);
    double px = max(p.x, p.y);
    double py = min(p.x, p.y);
    return px * sqrt(1 + pow(py / px, 2));
}

double getLineDistance(PointD a, PointD b) {
    double x = pow(b.x - a.x, 2);
    double y = pow(b.y - a.y, 2);
    return sqrt(x + y);
}

PointD getPointAtT(double t, PointD a, PointD b) {
    double x = (1 - t) * a.x + t * b.x;
    double y = (1 - t) * a.y + t * b.y;
    return PointD(x, y);
}

PointD getPointAtT(double t, PointD a, PointD b, PointD c, PointD d) {
    double x = pow(1 - t, 3) * a.x + 3 * t * pow(1 - t, 2) * b.x + 3 * pow(t, 2) * (1 - t) * c.x + pow(t, 3) * d.x;
    double y = pow(1 - t, 3) * a.y + 3 * t * pow(1 - t, 2) * b.y + 3 * pow(t, 2) * (1 - t) * c.y + pow(t, 3) * d.y;
    return PointD(x, y);
}

PathD getBezierCoefficient(PointD a, PointD b, PointD c, PointD d) {
    PathD points;
    points.push_back(PointD(d.x - a.x + 3 * (b.x - c.x), d.y - a.y + 3 * (b.y - c.y)));
    points.push_back(PointD(3 * a.x - 6 * b.x + 3 * c.x, 3 * a.y - 6 * b.y + 3 * c.y));
    points.push_back(PointD(3 * (b.x - a.x), 3 * (b.y - a.y)));
    points.push_back(PointD(a.x, a.y));
    return points;
}

PointD getBezierDerivative(double t, PathD coeff) {
    double x = coeff[2].x + t * (2 * coeff[1].x + 3 * coeff[0].x * t);
    double y = coeff[2].y + t * (2 * coeff[1].y + 3 * coeff[0].y * t);
    return PointD(x, y);
}

double getLength(PointD a, PointD b, double t = 1.0) {
    return getLineDistance(a, b) * t;
}

double getLength(PointD a, PointD b, PointD c, PointD d, double t = 1.0) {
    int i;
    double n, u, Z;
    PointD q;
    PathD coeff;

    double abscissas[] = {
        -0.0640568928626056299791002857091370970011, 0.0640568928626056299791002857091370970011,
        -0.1911188674736163106704367464772076345980, 0.1911188674736163106704367464772076345980,
        -0.3150426796961633968408023065421730279922, 0.3150426796961633968408023065421730279922,
        -0.4337935076260451272567308933503227308393, 0.4337935076260451272567308933503227308393,
        -0.5454214713888395626995020393223967403173, 0.5454214713888395626995020393223967403173,
        -0.6480936519369755455244330732966773211956, 0.6480936519369755455244330732966773211956,
        -0.7401241915785543579175964623573236167431, 0.7401241915785543579175964623573236167431,
        -0.8200019859739029470802051946520805358887, 0.8200019859739029470802051946520805358887,
        -0.8864155270044010714869386902137193828821, 0.8864155270044010714869386902137193828821,
        -0.9382745520027327978951348086411599069834, 0.9382745520027327978951348086411599069834,
        -0.9747285559713094738043537290650419890881, 0.9747285559713094738043537290650419890881,
        -0.9951872199970213106468008845695294439793, 0.9951872199970213106468008845695294439793
    };

    double weights[] = {
        0.1279381953467521593204025975865079089999, 0.1279381953467521593204025975865079089999,
        0.1258374563468283025002847352880053222179, 0.1258374563468283025002847352880053222179,
        0.1216704729278033914052770114722079597414, 0.1216704729278033914052770114722079597414,
        0.1155056680537255991980671865348995197564, 0.1155056680537255991980671865348995197564,
        0.1074442701159656343712356374453520402312, 0.1074442701159656343712356374453520402312,
        0.0976186521041138843823858906034729443491, 0.0976186521041138843823858906034729443491,
        0.0861901615319532743431096832864568568766, 0.0861901615319532743431096832864568568766,
        0.0733464814110802998392557583429152145982, 0.0733464814110802998392557583429152145982,
        0.0592985849154367833380163688161701429635, 0.0592985849154367833380163688161701429635,
        0.0442774388174198077483545432642131345347, 0.0442774388174198077483545432642131345347,
        0.0285313886289336633705904233693217975087, 0.0285313886289336633705904233693217975087,
        0.0123412297999872001830201639904771582223, 0.0123412297999872001830201639904771582223
    };

    n = 0;
    Z = t / 2;
    coeff = getBezierCoefficient(a, b, c, d);
    for (i = 0; i < 24; i++) {
        u = Z * abscissas[i] + Z;
        q = getBezierDerivative(u, coeff);
        n += weights[i] * getPointHypto(q);
    }
    n *= Z;

    return n;
}

vector<double> getArcLengths(PointD a, PointD b, PointD c, PointD d, int steps = 100) {
    int i;
    double z, sum;
    PointD o, v, p;

    vector<double> lengths;

    sum = 0;
    z = 1.0 / (double)steps;

    lengths.push_back(0.0);
    o = getPointAtT(0, a, b, c, d);
    for (i = 1; i <= steps; i++) {
        p = getPointAtT(i * z, a, b, c, d);
        v.x = o.x - p.x;
        v.y = o.y - p.y;
        o.x = p.x;
        o.y = p.y;
        sum += sqrt(v.x * v.x + v.y * v.y);
        lengths.push_back(sum);
    }

    return lengths;
}

double uniformTime(double t, vector<double> lengths, int steps = 100) {
    int index, low, high;
    double targetLength, lengthBefore;
    targetLength = t * lengths[steps];
    low = 0;
    high = steps;
    index = 0;
    while (low < high) {
        index = low + (((high - low) / 2) | 0);
        if (lengths[index] < targetLength) {
            low = index + 1;
        } else {
            high = index;
        }
    }
    if (lengths[index] > targetLength) {
        index--;
    }
    lengthBefore = lengths[index];
    if (lengthBefore == targetLength) {
        return index / steps;
    } else {
        return (index + (targetLength - lengthBefore) / (lengths[index + 1] - lengthBefore)) / steps;
    }
}

PathD getPoints(PointD a, PointD b, int reduce = 1, double steps = 100.0) {
    int i, len;
    PathD points;
    len = roundDouble(steps / reduce);
    for (i = 1; i < len; i++) {
        points.push_back(getPointAtT((double)i / len, a, b));
    }
    points.push_back(getPointAtT(1, a, b));
    return points;
}

PathD getPoints(PointD a, PointD b, PointD c, PointD d, int reduce = 1, double steps = 100.0) {
    int i, len;
    PathD points;
    len = roundDouble(steps / reduce);
    vector<double> lengths = getArcLengths(a, b, c, d);
    for (i = 1; i < len; i++) {
        points.push_back(getPointAtT(uniformTime((double)i / len, lengths), a, b, c, d));
    }
    points.push_back(getPointAtT(1, a, b, c, d));
    return points;
}

void flattenSegment(PathD& path, PointD a, PointD b, int reduce = 1) {
    PathD points = getPoints(a, b, reduce, getLength(a, b));
    for (int i = 0; i < (int)points.size(); i++) {
        path.push_back(points.at(i));
    }
}

void flattenSegment(PathD& path, PointD a, PointD b, PointD c, PointD d, int reduce = 1) {
    PathD points = getPoints(a, b, c, d, reduce, getLength(a, b, c, d));
    for (int i = 0; i < (int)points.size(); i++) {
        path.push_back(points.at(i));
    }
}

void flattenPath(PathD path, PathD& new_path, int reduce = 1) {
    PointD a, b;
    for (int i = 0; i < (int)path.size() - 1; i++) {
        a = path.at(i);
        b = path.at(i + 1);
        flattenSegment(new_path, a, b, reduce);
    }
}

void flattenPaths(PathsD paths, PathsD& new_paths, int reduce = 1) {
    for (int i = 0; i < (int)paths.size(); i++) {
        PathD new_path;
        flattenPath(paths.at(i), new_path, reduce);
        new_paths.push_back(new_path);
    }
}
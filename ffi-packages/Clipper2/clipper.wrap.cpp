#include <stdio.h>
#include "clipper.wrap.h"

#ifdef _WIN32
	#define EXPORT extern "C" __declspec(dllexport)
#else
	#define EXPORT extern "C" __attribute__((visibility("default")))
#endif

string errMsg;
int PRECISION = 3;

EXPORT const char *version() {
    return CLIPPER2_VERSION;
}

EXPORT const char *errVal() {
    return errMsg.c_str();
}

EXPORT void setPrecision(int newPrecision) {
    PRECISION = newPrecision;
}

// PATH
EXPORT PathD *NewPath() {
    return new PathD();
}

EXPORT void PathFree(PathD *path) {
    delete path;
}

EXPORT bool PathAddPoint(PathD *path, double x, double y) {
    try {
        path->push_back(PointD(x, y));
    } catch (Clipper2Exception &e) {
        errMsg = e.what();
        return false;
    }
    return true;
}

EXPORT int PathLen(PathD *path) {
    return (int)path->size();
}

EXPORT PointD *PathGet(PathD *path, int i) {
    return &((*path)[i]);
}

EXPORT void PathSet(PathD *path, int i, double x, double y) {
    path->at(i) = PointD(x, y);
}

EXPORT PathD *PathMove(PathD *path, double dx, double dy) {
    return new PathD(TranslatePath(*path, dx, dy));
}

EXPORT bool PathFlattenLine(PathD *path, int reduce, double x1, double y1, double x2, double y2) {
    try {
        PointD a, b;
        a = PointD(x1, y1);
        b = PointD(x2, y2);
        flattenSegment(*path, a, b, reduce);
    } catch (Clipper2Exception &e) {
        errMsg = e.what();
        return false;
    }
    return true;
}

EXPORT bool PathFlattenBezier(PathD *path, int reduce, double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4) {
    try {
        PointD a, b, c, d;
        a = PointD(x1, y1);
        b = PointD(x2, y2);
        c = PointD(x3, y3);
        d = PointD(x4, y4);
        flattenSegment(*path, a, b, c, d, reduce);
    } catch (Clipper2Exception &e) {
        errMsg = e.what();
        return false;
    }
    return true;
}

EXPORT PathD *PathFlatten(PathD *path, int reduce) {
    PathD *newPath = new PathD();
    try {
        flattenPath(*path, *newPath, reduce);
    } catch (Clipper2Exception &e) {
        delete newPath;
		errMsg = e.what();
        return NULL;
    }
    return newPath;
}

// PATHS
EXPORT PathsD *NewPaths() {
    return new PathsD();
}

EXPORT void PathsFree(PathsD *paths) {
    delete paths;
}

EXPORT bool PathsAdd(PathsD *paths, PathD *path) {
    try {
        paths->push_back(*path);
    } catch (Clipper2Exception &e) {
        errMsg = e.what();
        return false;
    }
    return true;
}

EXPORT int PathsLen(PathsD *paths) {
    return (int)paths->size();
}

EXPORT PathD *PathsGet(PathsD *paths, int i) {
    return &((*paths)[i]);
}

EXPORT void PathsSet(PathsD *paths, int i, PathD *path) {
    paths->at(i) = *path;
}

EXPORT PathsD *PathsMove(PathsD *paths, double dx, double dy) {
    return new PathsD(TranslatePaths(*paths, dx, dy));
}

EXPORT PathsD *PathsFlatten(PathsD *paths, int reduce) {
    PathsD *newPaths = new PathsD();
    try {
        flattenPaths(*paths, *newPaths, reduce);
    } catch (Clipper2Exception &e) {
        delete newPaths;
		errMsg = e.what();
        return NULL;
    }
    return newPaths;
}

EXPORT PathsD *PathsInflate(PathsD *paths, double delta, JoinType jt, EndType et, double mt, double at) {
    PathsD *newPaths = nullptr;
    try {
        newPaths = new PathsD(InflatePaths(*paths, delta, jt, et, mt, PRECISION, at));
    } catch (Clipper2Exception &e) {
		errMsg = e.what();
        return nullptr;
    }
    return newPaths;
}

PathsD *PathsBoolOp(int mode, PathsD *sbj, PathsD *clp, FillRule fr) {
    PathsD *newPaths = nullptr;
    try {
        switch (mode) {
            case 1:
                newPaths = new PathsD(Intersect(*sbj, *clp, fr, PRECISION));
                break;
            case 2:
                newPaths = new PathsD(Union(*sbj, *clp, fr, PRECISION));
                break;
            case 3:
                newPaths = new PathsD(Difference(*sbj, *clp, fr, PRECISION));
                break;
            case 4:
                newPaths = new PathsD(Xor(*sbj, *clp, fr, PRECISION));
                break;
            default:
                break;
        }
    } catch (Clipper2Exception &e) {
		errMsg = e.what();
        return nullptr;
    }
    return newPaths;
}

EXPORT PathsD *PathsIntersect(PathsD *sbj, PathsD *clp, FillRule fr) {
    return PathsBoolOp(1, sbj, clp, fr);
}

EXPORT PathsD *PathsUnion(PathsD *sbj, PathsD *clp, FillRule fr) {
    return PathsBoolOp(2, sbj, clp, fr);
}

EXPORT PathsD *PathsDifference(PathsD *sbj, PathsD *clp, FillRule fr) {
    return PathsBoolOp(3, sbj, clp, fr);
}

EXPORT PathsD *PathsXor(PathsD *sbj, PathsD *clp, FillRule fr) {
    return PathsBoolOp(4, sbj, clp, fr);
}
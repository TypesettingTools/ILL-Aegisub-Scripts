# ILL Geometry Module Reference

## What This Module Does

The geometry layer is what lets `ILL` stop thinking in terms of raw ASS drawing strings and start thinking in terms of points, segments, curves, and paths.

## Conventions

```moon
ILL = require "ILL.ILL"
{:Point, :Segment, :Curve, :Path} = ILL
```

## `Point`

`Point` is the atomic coordinate object used throughout the geometry stack.

### `Point(x = 0, y = 0, id = "l")`

Arguments:

- `x`: x coordinate.
- `y`: y coordinate.
- `id`: internal point kind used in ASS path commands, usually `"l"` or `"b"`.

Example:

```moon
p = Point 100, 50
```

### `point\clone()`

Returns an independent copy.

### `point\move(dx, dy)`

Translates the point in place.

Arguments:

- `dx`: horizontal offset.
- `dy`: vertical offset.

### `point\rotate(angle, origin = Point(0, 0))`

Rotates the point around an origin in mathematical radians.

Arguments:

- `angle`: rotation angle in radians.
- `origin`: pivot point.

### `point\rotatefrz(angle)`

Rotates the point using ASS `\frz` semantics.

Arguments:

- `angle`: ASS `\frz` angle in degrees.

### `point\scale(hor, ver)`

Scales the point using ASS-style percentages.

Arguments:

- `hor`: horizontal scale in ASS percent units.
- `ver`: vertical scale in ASS percent units.

### `point\round(dec = 3)`

Rounds the coordinates in place.

Arguments:

- `dec`: decimal precision.

### `point\lerp(other, t)`

Interpolates from the current point to another point.

Arguments:

- `other`: destination point.
- `t`: interpolation factor.

### `point\distance(other)` and `point\sqDistance(other)`

Return the Euclidean or squared distance to another point.

Arguments:

- `other`: point to compare against.

### `point\angle(other = Point(0, 0))`

Returns the angle from the current point to another point.

Arguments:

- `other`: target point used to measure the angle.

## `Segment`

`Segment` represents one straight edge between two `Point`s.

### `Segment(a, b)`

Arguments:

- `a`: start point.
- `b`: end point.

### `segment\getPTatTime(t)`

Evaluates one point along the segment.

Arguments:

- `t`: normalized position on the segment.

### `segment\flatten(len = segment\getLength(), reduce = 1)`

Returns sampled points along the segment.

Arguments:

- `len`: sampling length hint.
- `reduce`: density divisor. Larger values produce fewer points.

### `segment\split(t = 0.5)`

Splits the segment into two smaller segments.

Arguments:

- `t`: split position in normalized segment time.

### `segment\splitAtInterval(t = 0, u = 1)`

Extracts one interval from the segment and also returns tangent metadata for both ends.

Arguments:

- `t`: interval start.
- `u`: interval end.

### `segment\getNormalized(t, inverse = false)`

Returns a normalized tangent and point for one position on the segment.

Arguments:

- `t`: normalized segment time.
- `inverse`: flips the tangent direction.

### `segment\getLength(t = 1)`

Returns the segment length, optionally only up to time `t`.

Arguments:

- `t`: optional normalized end time.

### `segment\lineToBezier()`

Converts the segment into four bezier-compatible points so later code can treat straight and curved segments uniformly.

## `Curve`

`Curve` represents one cubic bezier.

### `Curve(a, b, c, d)`

Arguments:

- `a`: start point.
- `b`: first control point.
- `c`: second control point.
- `d`: end point.

### `curve\getPTatTime(t)`

Evaluates one point on the bezier.

Arguments:

- `t`: normalized bezier parameter.

### `curve\flatten(len = curve\getLength(), reduce = 1)`

Returns sampled points along the curve.

Arguments:

- `len`: sampling length hint.
- `reduce`: density divisor.

### `curve\pointIsInCurve(point, tolerance = 2, precision = 100)`

Tests whether a point lies close enough to the curve and returns the approximate time when it does.

Arguments:

- `point`: point to test.
- `tolerance`: max distance from the curve.
- `precision`: sampling resolution.

### `curve\split(t)`

Splits the bezier into two curves.

Arguments:

- `t`: split time on the bezier.

### `curve\splitAtInterval(t, u)`

Extracts one interval from the bezier and returns tangent metadata for the interval endpoints.

Arguments:

- `t`: interval start.
- `u`: interval end.

### `curve\getDerivative(t, coefficients = curve\getCoefficient())`

Returns the derivative vector at one bezier time.

Arguments:

- `t`: normalized bezier time.
- `coefficients`: optional cached polynomial coefficients.

### `curve\getNormalized(t, inverse = false)`

Returns the normalized tangent and point for one path-progress value.

Arguments:

- `t`: normalized path progress.
- `inverse`: flips the tangent direction.

### `curve\getLength(t = 1)`

Returns the curve length, optionally only up to time `t`.

Arguments:

- `t`: optional normalized end time.

### `curve\getArcLengths(precision = 100)`

Builds the cumulative arc-length table used for more uniform sampling.

Arguments:

- `precision`: number of samples used to approximate cumulative arc length.

### `Curve.uniformTime(lengths, len, u)`

Maps normalized arc progress back into bezier parameter space.

Arguments:

- `lengths`: cumulative arc-length table.
- `len`: sampling resolution that produced `lengths`.
- `u`: normalized arc progress to map back into bezier time.

## `Path`

`Path` is the main geometry object of the library. It can hold one or more contours and is the bridge between ASS drawing syntax and the geometry tools used by the macros.

### `Path(path = "")`

Creates a geometry object from an ASS drawing string, a rectangle table, or another path-like table.

Arguments:

- `path`: ASS shape string, `{l, t, r, b}` rectangle-like numeric table, or a path/path-like table.

Example:

```moon
path = Path "m 0 0 l 100 0 100 50 0 50"
```

### `path\export(decimal = 2)`

Serializes the path back into ASS drawing syntax.

Arguments:

- `decimal`: decimal precision used during export.

### `path\clone()`

Returns an independent copy.

### `path\boundingBox()`

Returns `l`, `t`, `r`, `b`, `width`, `height`, `origin`, `center`, and a rectangle `assDraw`.

This is the main way to query geometry extents before alignment or deformation operations.

### `path\flatten(distance = nil, flattenStraight = nil, customLen = nil)`

Converts the path into a denser point-based form.

Arguments:

- `distance`: density/reduction control.
- `flattenStraight`: when `true`, also subdivides straight segments.
- `customLen`: custom sampling length hint.

### `path\simplify(tolerance = 0.5, filterNoise = true, recreateBezier = true, angleThreshold = 170)`

Reduces point count while trying to preserve the visible contour.

Arguments:

- `tolerance`: simplification tolerance.
- `filterNoise`: enables extra cleanup before rebuilding curves.
- `recreateBezier`: rebuilds simplified contours as beziers.
- `angleThreshold`: corner preservation threshold.

### `path\move(px, py)`

Translates the path in place.

Arguments:

- `px`: horizontal offset.
- `py`: vertical offset.

### `path\rotatefrz(angle)`

Rotates the path using ASS `\frz` semantics.

Arguments:

- `angle`: ASS-style Z rotation in degrees.

### `path\rotate(angle, origin)`

Rotates the path in mathematical radians.

Arguments:

- `angle`: rotation angle in radians.
- `origin`: pivot point.

### `path\scale(hor, ver)`

Scales the path using ASS-style percentages.

Arguments:

- `hor`: horizontal scale in ASS percent units.
- `ver`: vertical scale in ASS percent units.

### `path\toOrigin()` and `path\toCenter()`

Move the path so its bounding box starts at the origin or is centered at the origin.

### `path\reallocate(an, box = nil, rev = false, x = 0, y = 0)`

Repositions the path relative to an ASS alignment anchor.

Arguments:

- `an`: ASS alignment.
- `box`: optional `{width, height}` box. If omitted, the path bounding box is used.
- `rev`: reverses the reallocation offset.
- `x`: extra x offset.
- `y`: extra y offset.

This is heavily used when text-derived shapes are moved between ASS alignments.

### `path\perspective(mesh, real = nil, mode = nil)`

Applies a quadrilateral-based perspective warp.

Arguments:

- `mesh`: target quadrilateral points.
- `real`: source quadrilateral. If omitted, the current bounding box corners are used.
- `mode`: `"warping"` uses `mesh` as the source path for the warp calculation.

### `path\envelopeGrid(numRows, numCols, isBezier = false)`

Builds a mesh grid over the path bounds.

Arguments:

- `numRows`: row count.
- `numCols`: column count.
- `isBezier`: when `true`, emits a bezier-friendly grid.

### `path\envelopeDistort(gridMesh, gridReal, ep = 0.1)`

Distorts the path from one grid to another.

Arguments:

- `gridMesh`: target grid.
- `gridReal`: source grid.
- `ep`: epsilon used in polygon hit-testing.

### `path\allCurve()`

Converts straight edges into cubic bezier-compatible segments.

### `path\getLength()`

Returns total path length.

### `path\getNormalized(t = 0.5, returnPath = false)`

Returns the tangent, point, time, and leading partial path at normalized distance `t`.

Arguments:

- `t`: normalized path progress.
- `returnPath`: when `true`, returns only the leading partial path.

### `path\getNormalizedInterval(u, v)`

Extracts one normalized interval from the full path.

Arguments:

- `u`: interval start.
- `v`: interval end.

This is useful for trim or reveal effects that need only one portion of a contour.

### `path\shadow(xshad, yshad, shadowType = "3D")`

Builds 3D-like or inner-shadow geometry.

Arguments:

- `xshad`: horizontal shadow offset.
- `yshad`: vertical shadow offset.
- `shadowType`: `"3D"` or `"inner"`.

### `path\morph(other, t = 0.5)`

Interpolates this path into another path.

Arguments:

- `other`: destination `Path`.
- `t`: interpolation factor.

### `path\convertToClipper(reduce = 1, flattenStraight = nil)` and `Path.convertFromClipper(cppPaths)`

Convert between `Path` and the Clipper2 representation.

Arguments for `convertToClipper`:

- `reduce`: flatten density divisor before export.
- `flattenStraight`: whether straight segments are also flattened.

Arguments for `convertFromClipper`:

- `cppPaths`: Clipper2 path collection.

### `path\unite(other)`, `path\difference(other)`, `path\intersect(other)`, and `path\exclude(other)`

Boolean operations between paths.

Arguments:

- `other`: clip path.

Example:

```moon
result = pathA\difference pathB
```

### `path\offset(delta, joinType, endType, miterLimit, arcTolerance, preserveCollinear, reverseSolution)`

Inflates or deflates the path using Clipper2.

Arguments:

- `delta`: offset distance.
- `joinType`: join style such as `"round"`, `"miter"`, or `"square"`.
- `endType`: end style such as `"polygon"`.
- `miterLimit`: miter limit for miter joins.
- `arcTolerance`: tolerance for round joins.
- `preserveCollinear`: Clipper flag for collinear edges.
- `reverseSolution`: Clipper flag for output orientation.

### `Path.RoundingPath(path, radius, inverted = false, cornerStyle = "Rounded", rounding = "Absolute")`

Creates rounded, spiked, or chamfered corners.

Arguments:

- `path`: source `Path` or ASS shape string.
- `radius`: rounding radius.
- `inverted`: enables inward rounding behavior.
- `cornerStyle`: `"Rounded"`, `"Spike"`, or `"Chamfer"`.
- `rounding`: `"Absolute"` or `"Relative"`.

Example:

```moon
rounded = Path.RoundingPath path, 8, false, "Rounded", "Absolute"
```

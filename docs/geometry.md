# ILL Geometry Module Reference

## What This Module Does

The geometry layer is what lets `ILL` stop thinking in terms of raw ASS drawing strings and start thinking in terms of points, segments, curves, and paths.

This is the module family used most heavily by `Shapery` and `Envelope Distort`, and it is also the bridge between text-derived shapes and boolean operations powered by Clipper2.

## Conventions

```moon
ILL = require "ILL.ILL"
{:Point, :Segment, :Curve, :Path} = ILL
```

When this page shows `Point(...)`, `Segment(...)`, `Curve(...)`, or `Path(...)`, it is using the constructor form seen from library code.

## `Point`

`Point` is the atomic coordinate object used throughout the geometry stack.

### `Point(x = 0, y = 0)`

Creates a point.

```moon
p = Point 100, 50
```

### `point\clone()`

Returns an independent copy.

### `point\move(dx, dy)`

Translates the point.

```moon
p\move 20, -10
```

### `point\rotate(angle, origin = Point(0, 0))`

Rotates the point around an origin.

### `point\rotatefrz(angle, origin = Point(0, 0))`

Rotation helper aligned with the ASS `\frz` convention.

### `point\scale(sx, sy = sx, origin = Point(0, 0))`

Scales the point relative to an origin.

### `point\lerp(other, t)`

Interpolates toward another point.

This is useful in morphing, path trimming, and curve evaluation flows.

### `point\distance(other)`

Returns the Euclidean distance to another point.

### `point\angle(other)`

Returns the angle from the current point to another point.

## `Segment`

`Segment` represents a straight geometric segment between two points.

### `Segment(p1, p2)`

Creates a straight segment.

### `segment\getPTatTime(t)`

Returns one point along the segment for `0 <= t <= 1`.

### `segment\flatten(reduce = 1)`

Returns a discretized representation of the segment.

### `segment\split(t)`

Splits the segment into two smaller segments.

### `segment\lineToBezier()`

Returns a cubic-bezier equivalent of the straight segment.

This is useful when later stages expect a unified curve representation.

## `Curve`

`Curve` represents a cubic bezier.

### `Curve(p1, p2, p3, p4)`

Creates a cubic curve.

### `curve\getPTatTime(t)`

Evaluates one point on the curve.

### `curve\flatten(reduce = 2)`

Discretizes the curve into sampled points.

This is one of the core operations behind exporting curves into point-based backends.

### `curve\split(t)`

Splits the curve into two curves at parameter `t`.

### `curve\getLength(reduce = 2)`

Returns an estimated curve length.

### `Curve.uniformTime(curve, n, reduce = 2)`

Builds a more uniform parameter distribution for sampling.

This matters when equal visual spacing is more important than raw bezier parameter spacing.

## `Path`

`Path` is the main high-level geometry object in the library.

It can represent a whole ASS drawing, including multiple contours, and exposes the operations used by the shape macros.

### `Path(shape = "")`

Parses ASS drawing data into a geometry object.

```moon
path = Path l.text
```

### `path\export()`

Serializes the geometry back into ASS drawing syntax.

```moon
l.text = path\export!
```

### `path\clone()`

Returns an independent copy of the full path.

### `path\boundingBox()`

Returns the path bounding box.

This is what powers operations such as `Shape bounding box`.

### `path\move(dx, dy)`

Translates the path.

### `path\scale(sx, sy = sx, origin = nil)`

Scales the path.

### `path\rotatefrz(angle, origin = nil)`

Rotates the path in ASS-friendly screen space.

### `path\toOrigin()`, `path\toCenter()`, and related recentering helpers

Recenters the drawing relative to its own bounds.

These are the operations behind helper macros such as `Shape to origin` and `Shape to center`.

### `path\reallocate(pos)`

Moves the geometry to a new logical anchor position.

### `path\flatten(reduce = 2, simplify = nil, area = nil)`

Converts curves into denser point sequences.

Use it before backends or workflows that expect mostly linearized geometry.

### `path\simplify(...)`

Reduces redundant geometry.

This is one of the main operations exposed through the `Manipulate` dialog.

### `path\reverse()`

Reverses contour point order.

This is the behavior used by the `Reverse points` helper macro.

### `path\withoutHoles()`

Drops inner contours and keeps only outer shells.

This is the behavior exposed as `Shape without holes`.

### `path\allCurve()`

Promotes line-based structures toward curve-compatible form.

### `path\getLength(reduce = 2)`

Returns path length.

This is useful for trimming, progressive reveals, and evenly spaced sampling.

### `path\getNormalized()` and `path\getNormalizedInterval(a, b)`

Return normalized geometric intervals suitable for trimming or progressive extraction.

These are the kinds of helpers used by partial-path workflows such as `Shape trim`.

### `path\perspective(meshSource, meshTarget)`

Applies a perspective-based warp.

This is part of the machinery used by `Envelope Distort` when the mesh can be interpreted as a perspective mapping.

### `path\envelopeGrid(...)` and `path\envelopeDistort(mesh, realMesh, tolerance)`

Apply grid-driven deformation to the path.

These are the core mesh-warp operations behind `Envelope Distort`.

### `path\shadow(...)`

Creates geometry derived from shadow displacement.

This powers the geometry-style shadow tools in `Shapery`.

### `path\morph(other, t)`

Interpolates one path toward another.

This is the geometric foundation behind `Shape morph` and related blending workflows.

### `path\convertToClipper()` and `Path.convertFromClipper(paths)`

Convert between the library's `Path` representation and the native Clipper2 representation.

This is the bridge between the friendly geometry layer and the low-level boolean backend.

### `path\unite(other)`, `path\difference(other)`, `path\intersect(other)`, and `path\exclude(other)`

Perform boolean operations between paths.

These are the core operations used by `Shapery/Pathfinder`, `Cut Contour`, and several helper macros.

```moon
result = path\difference clipPath
```

### `path\offset(delta, joinType = "round", endType = "polygon", miterLimit = 2, arcTolerance = 0)`

Builds expanded or contracted geometry around the path.

This is the implementation-level basis for `Shapery/Offsetting` and `Shape expand`.

```moon
outline = path\offset 4, "round", "polygon", 2, 0.25
```

### `Path.RoundingPath(path, radius, reduce = 2)`

Returns a rounded-corner version of a path.

This is the kind of operation used by the `Utilities` dialog when smoothing corners.

## Typical Workflow

The normal shape workflow in this library looks like this:

1. parse a drawing or clip into `Path`
2. transform, trim, offset, merge, or warp it
3. optionally send it through Clipper2-backed boolean operations
4. export it back to ASS drawing syntax

That is why `Path` is the real center of the geometry layer, while `Point`, `Segment`, and `Curve` are the building blocks it depends on.

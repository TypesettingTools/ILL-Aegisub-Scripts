# Clipper2 Module Reference

## What This Module Is

`clipper2.clipper2` is the low-level native geometry backend used by `ILL.Path` for boolean operations and offsetting.

Most macro code should stay at the `Path` level, but this module is useful when you want direct access to the native containers that power clipping and inflation.

## Conventions

```moon
CPP = require "clipper2.clipper2"
```

The wrapper exposes constructor helpers as `CPP.path.new!` and `CPP.paths.new!`.

## Module Surface

### `CPP.version`

Lua-side wrapper version string.

### `CPP.ffiversion()`

Returns the native Clipper2 version string from the loaded library.

### `CPP.viewError()`

Returns the last native error message reported by the backend.

### `CPP.setPrecision(n = 3)`

Sets the global numeric precision used by the native binding.

Arguments:

- `n`: number of decimal digits preserved by the backend.

## Enums

The wrapper accepts either the numeric enum value or the string name.

### `FillRule`

- `"even_odd"` = `0`
- `"non_zero"` = `1`
- `"positive"` = `2`
- `"negative"` = `3`

### `JoinType`

- `"square"` = `0`
- `"round"` = `1`
- `"miter"` = `2`

### `EndType`

- `"polygon"` = `0`
- `"joined"` = `1`
- `"butt"` = `2`
- `"square"` = `3`
- `"round"` = `4`

## `CPP.path`

`CPP.path` is one native path, meaning one ordered point list.

### `CPP.path.new()`

Creates an empty native path.

### `path\add(mode = "line", ...)`

Adds geometry to the path.

Accepted call shapes:

- `path\add "line", x, y`
- `path\add "line", reduce, x1, y1, x2, y2`
- `path\add "bezier", reduce, x1, y1, x2, y2, x3, y3, x4, y4`

Argument meaning:

- `mode`: `"line"` adds either one point or one flattened line segment, and `"bezier"` adds one flattened cubic bezier.
- `reduce`: flatten density passed to the native line/bezier flattener. Larger values reduce point count.
- `x`, `y`: point coordinates for the single-point form.
- `x1`, `y1`: line or bezier start point.
- `x2`, `y2`: line end point or first bezier control point.
- `x3`, `y3`: second bezier control point.
- `x4`, `y4`: bezier end point.

### `path\push(...)`

Appends one or more point-like tables.

Arguments:

- `...`: tables exposing `x` and `y`, such as `{x: 0, y: 0}` or `Point` objects from `ILL`.

### `path\len()`

Returns the number of stored points.

### `path\get(i = 1)`

Returns one native point.

Arguments:

- `i`: 1-based point index. Values below `1` are clamped to the first point.

### `path\set(i = 1, x, y)`

Replaces one point in place.

Arguments:

- `i`: 1-based point index.
- `x`: new x coordinate.
- `y`: new y coordinate.

### `path\move(dx, dy)`

Returns a translated copy of the path.

Arguments:

- `dx`: horizontal offset.
- `dy`: vertical offset.

### `path\flatten(reduce = 2)`

Returns a flattened copy of the path.

Arguments:

- `reduce`: density divisor used by the native flattening routine.

### `path\map(fn)`

Maps every point through a callback and mutates the path in place.

Arguments:

- `fn`: callback receiving `(x, y)` and optionally returning replacement `(x, y)`.

## `CPP.paths`

`CPP.paths` is a collection of native paths. This is the container used by the boolean engine.

### `CPP.paths.new()`

Creates an empty path collection.

### `paths\add(path)`

Adds one native path to the collection.

Arguments:

- `path`: `CPP.path` instance to append.

### `paths\push(...)`

Adds one or more native paths.

Arguments:

- `...`: `CPP.path` instances.

### `paths\len()`

Returns the number of contained paths.

### `paths\get(i = 1)`

Returns one contained path.

Arguments:

- `i`: 1-based path index. Values below `1` are clamped to the first path.

### `paths\set(i = 1, path)`

Replaces one contained path.

Arguments:

- `i`: 1-based path index.
- `path`: replacement `CPP.path` instance.

### `paths\move(dx, dy)`

Returns a translated copy of the full collection.

Arguments:

- `dx`: horizontal offset.
- `dy`: vertical offset.

### `paths\flatten(reduce = 2)`

Returns a flattened copy of every contained path.

Arguments:

- `reduce`: density divisor used while flattening.

### `paths\map(fn)`

Applies a point-mapping callback to every contained path.

Arguments:

- `fn`: callback receiving `(x, y)` and optionally returning replacement `(x, y)`.

## Boolean And Offset Operations

These are the backend equivalents of the higher-level `Path` methods.

### `paths\inflate(delta, jt = 0, et = 0, mt = 2, at = 0)`

Offsets the path collection and returns a new `CPP.paths`.

Arguments:

- `delta`: offset distance. Positive expands and negative contracts.
- `jt`: join type as numeric enum or string name.
- `et`: end type as numeric enum or string name.
- `mt`: miter limit used when `jt` is miter.
- `at`: arc tolerance used for round joins.

### `paths\intersection(paths, fr = 1)`

Returns the overlap between two path collections.

Arguments:

- `paths`: clip collection.
- `fr`: fill rule as numeric enum or string name.

### `paths\union(paths, fr = 1)`

Returns the merged area of two path collections.

Arguments:

- `paths`: second collection to merge with the subject.
- `fr`: fill rule as numeric enum or string name.

### `paths\difference(paths, fr = 1)`

Subtracts the second collection from the first.

Arguments:

- `paths`: clip collection subtracted from the subject.
- `fr`: fill rule as numeric enum or string name.

### `paths\xor(paths, fr = 1)`

Returns the non-overlapping parts of both collections.

Arguments:

- `paths`: second collection.
- `fr`: fill rule as numeric enum or string name.

## Example Workflow

```moon
CPP = require "clipper2.clipper2"

subject = CPP.paths.new!
clip = CPP.paths.new!

base = CPP.path.new!
base\push {x: 0, y: 0}, {x: 120, y: 0}, {x: 120, y: 80}, {x: 0, y: 80}

hole = CPP.path.new!
hole\push {x: 40, y: 20}, {x: 100, y: 20}, {x: 100, y: 60}, {x: 40, y: 60}

subject\add base
clip\add hole

cut = subject\difference clip, "non_zero"
outline = cut\inflate 3, "round", "polygon", 2, 0.25
```

## When To Stay At The `Path` Level Instead

Prefer `ILL.Path` unless you specifically need the native containers or want to work directly with the backend enum and memory model. `clipper2.clipper2` is the engine underneath the higher-level geometry API, not the most ergonomic public entry point.

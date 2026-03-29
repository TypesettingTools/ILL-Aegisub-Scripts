# Clipper2 Module Reference

## What This Module Is

`clipper2.clipper2` is the low-level native geometry backend used by `Path` for boolean operations and offsetting.

Most users of the library do not need to call it directly. In normal macro code, you usually stay at the `Path` level:

```moon
result = shapePath\unite otherPath
outline = shapePath\offset 3
```

This page matters when you want to understand what `Path` is doing internally or when you need to work directly with the native path containers.

## Conventions

```moon
CPP = require "clipper2.clipper2"
```

When this page shows `CPP.path()` or `CPP.paths()`, it is using the constructor form seen from MoonScript user code.

## Module Surface

The module exposes:

- `CPP.version`
- `CPP.ffiversion()`
- `CPP.viewError()`
- `CPP.setPrecision(n = 3)`
- `CPP.path(...)`
- `CPP.paths(...)`

### `CPP.version`

Version string for the Lua-side wrapper.

### `CPP.ffiversion()`

Returns the native Clipper2 version.

### `CPP.viewError()`

Returns the last native error message.

Use this when a boolean or offset operation fails.

### `CPP.setPrecision(n = 3)`

Sets the global numeric precision used by the binding.

## Enums

String names are accepted for the native enums.

### `FillRule`

- `"even_odd"`
- `"non_zero"`
- `"positive"`
- `"negative"`

### `JoinType`

- `"square"`
- `"round"`
- `"miter"`

### `EndType`

- `"polygon"`
- `"joined"`
- `"butt"`
- `"square"`
- `"round"`

## `CPP.path`

`CPP.path` is one native path, that is, one ordered point list.

### `CPP.path()`

Creates an empty native path.

```moon
p = CPP.path!
```

### `path\add(mode = "line", ...)`

Adds geometry to the path.

Accepted forms:

- `"line", x, y`
- `"line", reduce, x1, y1, x2, y2`
- `"bezier", reduce, x1, y1, x2, y2, x3, y3, x4, y4`

### `path\push(...)`

Appends one or more point tables in `{x: ..., y: ...}` form.

```moon
p\push {x: 0, y: 0}, {x: 100, y: 0}, {x: 100, y: 100}, {x: 0, y: 100}
```

### `path\len()`

Returns the number of points.

### `path\get(i = 1)`

Returns one point from the native path.

### `path\set(i = 1, x, y)`

Replaces one point.

### `path\move(x, y)`

Returns a translated copy.

### `path\flatten(reduce = 2)`

Returns a discretized copy.

### `path\map(fn)`

Maps each point through a callback.

## `CPP.paths`

`CPP.paths` is a collection of native paths. This is the object shape used by the boolean engine.

### `CPP.paths()`

Creates an empty path collection.

```moon
subject = CPP.paths!
clip = CPP.paths!
```

### `paths\add(path)` and `paths\push(...)`

Add one or more native paths to the collection.

### `paths\len()`, `paths\get(i = 1)`, and `paths\set(i = 1, path)`

Inspect or replace paths in the collection.

### `paths\move(x, y)` and `paths\flatten(reduce = 2)`

Return transformed copies of the full collection.

### `paths\map(fn)`

Applies point remapping to every contained path.

## Boolean And Offset Operations

These methods are the low-level equivalents of the higher-level `Path` operations.

### `paths\inflate(delta, jt = 0, et = 0, mt = 2, at = 0)`

Offsets the path collection and returns a new collection.

This is the native operation behind `Path\offset`.

```moon
outline = subject\inflate 4, "round", "polygon", 2, 0.25
```

### `paths\intersection(paths, fr = 1)`

Returns the overlap between two path collections.

### `paths\union(paths, fr = 1)`

Returns the merged area of two path collections.

### `paths\difference(paths, fr = 1)`

Subtracts the second collection from the first.

### `paths\xor(paths, fr = 1)`

Returns the non-overlapping parts of both collections.

## Example Workflow

```moon
CPP = require "clipper2.clipper2"

subject = CPP.paths!
clip = CPP.paths!

base = CPP.path!
base\push {x: 0, y: 0}, {x: 120, y: 0}, {x: 120, y: 80}, {x: 0, y: 80}

hole = CPP.path!
hole\push {x: 40, y: 20}, {x: 100, y: 20}, {x: 100, y: 60}, {x: 40, y: 60}

subject\add base
clip\add hole

cut = subject\difference clip, "non_zero"
outline = cut\inflate 3, "round", "polygon", 2, 0.25
```

## When To Stay At The `Path` Level Instead

Prefer `Path` unless you specifically need native containers or backend-level control. `Path` is the intended public geometry layer of the library; `clipper2.clipper2` is the engine underneath it.

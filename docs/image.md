# ILL Image Module Reference

## What This Module Is

`ILL.IMG` is the image-processing side of the library. In practice, there are three public workflows that matter:

- load an image and convert it directly to ASS pixels with `IMG`
- vectorize a colored image with `Tracer`
- vectorize a monochrome image with `Potrace`

This page focuses on those public entry points and how they are used in the project's own macros.

## Conventions Used In Examples

```moon
IMGMod = require "ILL.IMG"
{:IMG, :Tracer, :Potrace} = IMGMod
```

Examples on this page are adapted from [`ILL.MakeImage.moon`](/c:/Users/klsru/OneDrive/Documents/github/ILL-Aegisub-Scripts/macros/ILL.MakeImage.moon).

## `IMG(filename)`

Creates an image object and decodes the file immediately.

- Use this when you want pixel-based conversion or when you want raw decoded frames to feed into `Tracer` or `Potrace`.
- Accepted extensions are `png`, `jpg`/`jpeg`, `bmp`, and `gif`.
- The constructor stores the decoded result in `img.infos` and also records `img.extension`.
- If the file type is unsupported, it raises an error instead of returning a partially usable object.

### Example

```moon
filename = aegisub.dialog.open "Open Image", "", "", "Images|*.png;*.jpg;*.jpeg;*.bmp;*.gif;", false, true
img = IMG filename
```

## `img\setInfos(frame = 1)`

Promotes one decoded frame into the fields the rest of the library expects to read directly.

- For static images, it copies the decoded image into `img.width`, `img.height`, and `img.data`.
- For GIFs, it selects one frame from `img.infos.frames` and also exposes `img.delayMs`, `img.x`, and `img.y`.
- Call this before reading `img.width`, `img.height`, or `img.data` yourself.

### Example

```moon
img = IMG filename
img\setInfos!

width = img.width
height = img.height
pixels = img.data
```

## `img\toAss(reduce, frame)`

Converts the image into ASS `\p1` drawing lines.

- `reduce = false` or `nil` generates one 1x1 rectangle per visible pixel.
- `reduce = true` merges horizontally adjacent pixels that share the same color and alpha.
- `reduce = "oneLine"` does the same reduction, but collapses all rows into a single ASS line.
- Transparent pixels are skipped.
- The generated lines already contain a ready-to-use prefix with `\an7`, `\pos`, `\bord0`, `\shad0`, `\frz0`, and `\p1`.

This is the method used by the `Make Image / Pixels` macro.

### Example

```moon
img = IMG filename

asslines = img\toAss true
for pixel in *asslines
  line = Table.copy sub[activeLine]
  line.isShape = true
  line.shape = pixel\gsub "}{", ""
  ass\insertLine line, activeLine
```

## `Tracer.checkoptions(options = {})`

Normalizes a tracing options table.

- If you pass a preset name as a string, it resolves it through `Tracer.optionpresets`.
- If you pass a partial table, it fills in whatever is missing from the default preset.
- Use this whenever you build tracing options yourself instead of relying on the macro UI.

### Example

```moon
preset = Tracer.checkoptions {
  ltres: 1
  qtres: 1
  pathomit: 8
  colorsampling: 2
  numberofcolors: 16
  layering: 0
}
```

## `Tracer.imagedataToTracedata(imgd, options)`

Runs the full color-tracing pipeline and returns an intermediate traced representation.

- `imgd` is any object with `width`, `height`, and `data`, so you can pass either `img` after `img\setInfos!` or a GIF frame object from `img.infos.frames[i]`.
- Internally this performs color quantization, layer extraction, path scanning, internode generation, and spline fitting.
- The result is not final ASS yet. It is a structured traced object meant to be consumed by `Tracer.getAssLines`.

The returned object contains:

- `layers`: traced path data grouped by palette layer
- `palette`: final color palette used in quantization
- `width`
- `height`

### Example

```moon
img = IMG filename
img\setInfos!

preset = Tracer.checkoptions "detailed"
tracedata = Tracer.imagedataToTracedata img, preset
```

## `Tracer.getAssLines(tracedata, options)`

Converts traced layer data into final ASS drawing lines.

- Shapes with the same color/alpha combination are merged into fewer ASS lines.
- The result is ready to insert into subtitle lines.
- This is the last step used by the `Make Image / Image Tracer` macro before insertion into the script.

### Example

```moon
img = IMG filename
img\setInfos!

preset = Tracer.checkoptions "default"
tracedata = Tracer.imagedataToTracedata img, preset
asslines = Tracer.getAssLines tracedata, preset

for trace in *asslines
  line = Table.copy sub[activeLine]
  line.isShape = true
  line.tags = ILL.Tags trace\match "%b{}"
  line.shape = trace\gsub "%b{}", ""
  ass\insertLine line, activeLine
```

## `Potrace(img, frame, turnpolicy, turdsize, optcurve, alphamax, opttolerance)`

Creates a monochrome vectorizer configured for one image frame.

- This is the low-level entry point behind the `Make Image / Potrace` macro.
- The constructor calls `img\setInfos(frame)` internally, so you usually pass the `IMG` instance directly.
- Transparent pixels are first composited over white, then thresholded to black/white before tracing.

Parameters in practice:

- `turnpolicy`: `"right"`, `"black"`, `"white"`, `"majority"`, or `"minority"`
- `turdsize`: minimum blob area to keep
- `optcurve`: whether to optimize curves
- `alphamax`: corner threshold
- `opttolerance`: optimization tolerance

### Example

```moon
img = IMG filename
pot = Potrace img, 1, "minority", 2, true, 1, 0.2
```

## `pot\process()`

Runs the full Potrace pipeline.

- First it extracts raw bitmap contours.
- Then it fits polygons and curves.
- After this call, `pot.pathlist` contains the traced internal paths and the object is ready for serialization.

### Example

```moon
pot = Potrace img, 1, "minority", 2, true, 1, 0.2
pot\process!
```

## `pot\getShape(dec = 3)`

Serializes the traced Potrace result as one ASS drawing string.

- The returned value is just the shape commands, not a complete subtitle line.
- In the project macros, the result is usually wrapped in tags and sometimes moved with `Path(shape)\move(...)`.
- The current implementation accepts `dec` in the signature, but the rounding flow is effectively fixed by the internal `Potrace.round` calls.

### Example

```moon
pot = Potrace img, 1, "minority", 2, true, 1, 0.2
pot\process!

shape = pot\getShape!
line = Table.copy sub[activeLine]
line.isShape = true
line.shape = "{\\an7\\pos(0,0)\\bord0\\shad0\\fscx100\\fscy100\\fr0\\p1}#{shape}"
ass\insertLine line, activeLine
```

## Typical Workflows

### Pixel workflow

```moon
img = IMG filename
asslines = img\toAss true
```

Use this when you want a faithful raster-to-ASS conversion and you do not care about vector simplification.

### Color vector workflow

```moon
img = IMG filename
img\setInfos!
preset = Tracer.checkoptions "default"
tracedata = Tracer.imagedataToTracedata img, preset
asslines = Tracer.getAssLines tracedata, preset
```

Use this when you want layered vector output by color.

### Monochrome vector workflow

```moon
img = IMG filename
pot = Potrace img, 1, "minority", 2, true, 1, 0.2
pot\process!
shape = pot\getShape!
```

Use this when you want a single monochrome traced shape instead of multi-color layers.

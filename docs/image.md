# ILL Image Module Reference

## What This Module Is

`ILL.IMG` is the image-processing side of the library. In practice, there are three workflows that matter:

- decode an image and convert it directly into ASS pixel lines with `IMG`
- trace a colored image into layered vector output with `Tracer`
- trace a monochrome image into one vector shape with `Potrace`

## Conventions Used In Examples

```moon
IMGMod = require "ILL.IMG"
{:IMG, :Tracer, :Potrace} = IMGMod
```

## `IMG`

`IMG` is the decode-and-export entry point. It loads the file immediately and stores the decoded metadata in `img.infos`.

### `IMG(filename)`

Creates an image object and decodes the file immediately.

Arguments:

- `filename`: path to a supported image file.

Supported formats in the current implementation:

- `png`
- `jpg` / `jpeg` / `jpe` / `jfif` / `jfi`
- `bmp` / `dib`
- `gif`

Example:

```moon
img = IMG "C:/work/logo.png"
```

### `img\setInfos(frame = 1)`

Promotes one decoded frame into the fields the rest of the API reads directly: `img.width`, `img.height`, and `img.data`.

For GIFs, this also exposes frame-local `img.delayMs`, `img.x`, and `img.y`.

Arguments:

- `frame`: 1-based GIF frame index. Ignored for static images.

Example:

```moon
img = IMG filename
img\setInfos 1

width = img.width
height = img.height
pixels = img.data
```

### `img\toAss(reduce = nil, frame = 1)`

Converts the decoded image into ASS `\p1` drawing lines.

This is the lowest-level raster export in the module and is what the pixel mode of `Make Image` is built on.

Arguments:

- `reduce`: `nil` or `false` emits one rectangle per visible pixel, `true` merges horizontal runs, and `"oneLine"` also collapses every row into a single subtitle line.
- `frame`: GIF frame index to convert.

Behavior notes:

- fully transparent pixels are skipped
- generated lines already contain a usable prefix with `\an7`, `\pos`, `\bord0`, `\shad0`, and `\p1`
- reduction only merges horizontal neighbors with the same color and alpha

Example:

```moon
img = IMG filename
assLines = img\toAss true

for pixel in *assLines
  line = Table.copy sub[activeLine]
  line.isShape = true
  line.shape = pixel\gsub "}{", ""
  ass\insertLine line, activeLine
```

## `Tracer`

`Tracer` is the colored-vector workflow. It quantizes colors, scans connected regions, traces outlines, and exports layered ASS drawings.

### `Tracer.checkoptions(options = {})`

Normalizes a tracing options table.

Use this first when you are building tracing settings manually instead of going through the macro UI.

Arguments:

- `options`: preset name string or partial options table.

Important fields recognized by the tracer:

- `ltres`: line-fitting error tolerance.
- `qtres`: quadratic/spline fitting tolerance.
- `pathomit`: minimum path size retained after scan.
- `rightangleenhance`: preserves sharper corners during internode processing.
- `colorsampling`: palette sampling mode.
- `numberofcolors`: target palette size.
- `mincolorratio`: minimum palette ratio kept during quantization.
- `colorquantcycles`: refinement passes for quantization.
- `layering`: layer extraction mode.
- `strokewidth`: stroke width used during ASS export.
- `scale`: exported coordinate scale.
- `roundcoords`: coordinate rounding precision during export.
- `blurradius`: blur radius applied before quantization.
- `blurdelta`: blur sensitivity threshold.
- `pal`: optional fixed palette.

Example:

```moon
preset = Tracer.checkoptions {
  numberofcolors: 16
  pathomit: 8
  ltres: 1
  qtres: 1
}
```

### `Tracer.imagedataToTracedata(imgd, options)`

Runs the color-tracing pipeline and returns the intermediate traced representation.

This is not final ASS yet. The result is meant to be passed to `Tracer.getAssLines`.

Arguments:

- `imgd`: image-like object with `width`, `height`, and `data`.
- `options`: normalized tracer options, usually from `Tracer.checkoptions`.

The returned object contains:

- `layers`
- `palette`
- `width`
- `height`

Example:

```moon
img = IMG filename
img\setInfos!

options = Tracer.checkoptions "default"
tracedata = Tracer.imagedataToTracedata img, options
```

### `Tracer.getAssLines(tracedata, options)`

Converts traced layer data into ready-to-insert ASS drawing lines.

This is the final export stage of the color tracer.

Arguments:

- `tracedata`: result of `Tracer.imagedataToTracedata`.
- `options`: tracer options used to export coordinates and style.

Behavior notes:

- output is already grouped by traced color layers
- each string is ready to insert into subtitle lines
- the options still matter here because export scale, rounding, and stroke behavior are applied at this stage

Example:

```moon
img = IMG filename
img\setInfos!

options = Tracer.checkoptions "default"
tracedata = Tracer.imagedataToTracedata img, options
assLines = Tracer.getAssLines tracedata, options
```

## `Potrace`

`Potrace` is the monochrome tracing workflow. It turns one bitmap frame into one vector shape instead of multiple color layers.

### `Potrace(img, frame, turnpolicy, turdsize, optcurve, alphamax, opttolerance)`

Creates a monochrome vectorizer configured for one image frame.

Arguments:

- `img`: `IMG` instance that provides the decoded pixel data.
- `frame`: 1-based GIF frame index passed to `img\setInfos(frame)`.
- `turnpolicy`: ambiguity rule used while walking bitmap contours. Common values are `"right"`, `"black"`, `"white"`, `"majority"`, and `"minority"`.
- `turdsize`: minimum connected-component area kept by the tracer.
- `optcurve`: enables curve optimization after polygon fitting.
- `alphamax`: corner threshold used during optimization.
- `opttolerance`: optimization tolerance.

Behavior notes:

- the constructor calls `img\setInfos(frame)` internally
- transparent pixels are composited into a white background before thresholding
- the trace is fundamentally monochrome

Example:

```moon
img = IMG filename
pot = Potrace img, 1, "minority", 2, true, 1, 0.2
```

### `pot\process()`

Runs the full tracing pipeline and fills `pot.pathlist`.

After this call the object is ready for serialization.

Example:

```moon
pot = Potrace img, 1, "minority", 2, true, 1, 0.2
pot\process!
```

### `pot\getShape(dec = 3)`

Serializes the traced result as one ASS drawing string.

Arguments:

- `dec`: requested decimal precision. The parameter exists in the API, but the current implementation does not expose it as a strong external precision control.

Example:

```moon
pot = Potrace img, 1, "minority", 2, true, 1, 0.2
pot\process!
shape = pot\getShape!
```

## Typical Workflows

### Pixel workflow

```moon
img = IMG filename
assLines = img\toAss true
```

Use this when you want faithful raster output and do not need vector simplification.

### Color vector workflow

```moon
img = IMG filename
img\setInfos!
options = Tracer.checkoptions "default"
tracedata = Tracer.imagedataToTracedata img, options
assLines = Tracer.getAssLines tracedata, options
```

Use this when you want one or more vector layers grouped by color.

### Monochrome vector workflow

```moon
img = IMG filename
pot = Potrace img, 1, "minority", 2, true, 1, 0.2
pot\process!
shape = pot\getShape!
```

Use this when you want one traced shape instead of a layered color export.

# Macros

This page documents the shipped macros as working tools, not just menu entries. The descriptions below are based on the implementation in the project macros and on the module methods each macro actually calls.

## Shapery

`Shapery` is the main shape-processing macro in the project. It is the largest consumer of the geometry stack exposed by `ILL`, especially `Path`, `Line`, `Ass`, `Config`, and the Clipper2-backed boolean operations.

At a high level, `Shapery` works by taking selected ASS drawing lines, extending them into parsed `Line` objects, converting their shape data into `Path`, applying geometry operations, and then exporting the result back into ASS drawing syntax. Depending on the operation, it may also consume `\clip` or `\iclip`, preserve or rewrite `\pos` and `\move`, and split one source line into multiple generated lines.

Registered entries:

- `Shapery/Pathfinder`
- `Shapery/Offsetting`
- `Shapery/Manipulate`
- `Shapery/Transform`
- `Shapery/Utilities`
- `Shapery/Cut Contour`
- `Shapery/Config`

Helper macros:

- `Shape expand`
- `Shape clipper`
- `Clip to shape`
- `Shape to clip`
- `Shape to clip (clipboard)`
- `Shape merge`
- `Shape blend`
- `Shape morph`
- `Shape trim`
- `Shape to 0,0`
- `Shape to pos`
- `Shape to origin`
- `Shape to center`
- `Shape without holes`
- `Shape bounding box`
- `Reverse points`

### Pathfinder

This dialog is the high-level UI for boolean shape operations. Internally it is the place where shape and clip geometry are turned into `Path` objects and then combined through union, intersection, difference, and related pathfinder-style operations.

Use it when the goal is to combine or subtract shapes as geometry, not to visually fake the result with tags.

### Offsetting

This dialog creates real expanded or contracted geometry around an existing path. Its implementation relies on path offsetting rather than ASS border rendering, so the result is new shape data that can be edited, trimmed, merged, or reused in later shape operations.

Use it when you want an actual geometric outline, inset, or growth operation.

### Manipulate

This group changes the internal structure of the path. In implementation terms, it calls operations such as flattening, simplification, and curve rebuilding on parsed geometry rather than moving the shape as a whole.

Use it when the problem is the contour itself: too many points, the wrong kind of segments, or geometry that needs to be normalized before another operation.

### Transform

This group applies direct spatial transforms such as translation, scaling, and rotation. The important implementation detail is that these transforms are applied to parsed shape coordinates, then written back to the line, instead of being delegated to ASS transforms.

Use it when you want deterministic geometry changes rather than runtime visual transforms.

### Utilities

This group exposes helper geometry operations such as shadow-derived shape generation and corner processing. These are implemented as real path manipulations and shape generation, not as style-only shortcuts.

Use it when you need derived shapes generated from the existing contour.

### Cut Contour

This tool combines the current line shape with another contour supplied by the user. The input contour is parsed as geometry and then processed through the same boolean shape logic used by the larger `Shapery` workflows.

Use it when the cutting geometry is not already available as another selected line.

### Config

This screen persists `Shapery` settings through `Config`, allowing the dialogs and helper macros to reuse stored defaults instead of forcing the user to re-enter them every run.

### Helper Macros

The helper macros are not just shortcuts to menu categories. Each one is a very specific geometry routine built on top of `Line.extend`, `Line.callBackExpand`, `Path`, and line/tag rewriting.

#### `Shape expand`

This helper expands a shape into separate outline and shadow geometry derived from the line's current border and shadow values.

Implementation-wise, it removes the original line, expands it if needed, duplicates the working line, strips outline and shadow tags from both copies, and then reconstructs the visible layers as actual shapes. If outline expansion is needed, it creates an offset path. If shadow expansion is needed, it resolves the effective shadow vector with `Line.solveShadow`, moves the relevant geometry, and then subtracts or merges shapes depending on the relationship between outline and shadow colors. The macro can therefore emit multiple resulting lines: one for the original fill, one for the generated outline, and one for the generated shadow shape.

This is why `Shape expand` is much more than "add border": it materializes border and shadow as editable geometry.

#### `Shape clipper`

This helper applies the line's own `\clip` or `\iclip` to the shape itself.

For each expanded working line, it reads the current shape, reads the clip, repositions the clip from screen space into the shape's local coordinate space by subtracting the line position, and then applies either `difference` for `\iclip` or `intersect` for regular `\clip`. If the result is non-empty, it removes the original clip tags and writes the clipped shape back as actual drawing data.

The key point is that this macro converts runtime clipping into permanent geometry.

#### `Shape to clip`

This helper converts the visible shape into a `\clip` or `\iclip` tag on the same line.

Internally it expands the line if needed, moves each generated shape from local shape coordinates into screen space using the line's position, concatenates all resulting contours, and inserts the final path string into either `\clip` or `\iclip` depending on what the line already uses. If the line is text rather than shape, the tag block is rewritten into the text content.

Use it when the shape should stop being the main drawable content and start acting as clipping geometry.

#### `Shape to clip (clipboard)`

This behaves like `Shape to clip`, but instead of writing the result back to the subtitle line, it writes the generated `\clip(...)` string to the clipboard.

That makes it useful as an extraction helper when you want to reuse the clip manually elsewhere.

#### `Clip to shape`

This helper does the inverse conversion: it turns `\clip` or `\iclip` data into the line's shape content.

The macro reads the clip, reallocates it into the line's shape coordinate system with respect to the current alignment and position, removes clip-related tags, and, if the line was originally text, converts it into a shape line by stripping font-related state and inserting the required `\pos`, `\an`, `\fscx100`, `\fscy100`, `\frz0`, and `\p1` tags.

Use it when the clip should become editable drawing data instead of remaining embedded as a tag.

#### `Shape bounding box`

This helper replaces the current shape with the rectangle returned by `Path.boundingBox()`.

It does not merely report the box; it rewrites the shape into that box as ASS drawing data.

Use it when you need the exact rectangular bounds of a drawing as a new shape.

#### `Shape morph`

This helper creates frame-by-frame interpolated shapes between exactly two selected shape lines.

Implementation-wise, it first expands each selected line, moves their shapes into screen-space coordinates, stores them, and then, once both source shapes are available, uses `Path.morph` inside `Line.callBackFBF` to generate one interpolated shape per frame across the timing of the first line. The generated lines are then inserted back into the script.

This makes `Shape morph` a real geometry interpolation tool rather than a simple point shuffle.

#### `Shape merge`

This helper merges selected shapes by grouping them according to their visible color and alpha signature.

The implementation computes a grouping key from fill, outline, shadow, and alpha-related values. Shapes with the same visual signature are collected together, expanded if needed, repositioned into a shared local space, concatenated into one combined drawing, and then emitted as a single line per group. At the end, the original selected lines are deleted and replaced by the grouped merged output.

This means `Shape merge` is not just geometric union. It is a practical batch merge that preserves visual grouping by color state.

#### `Shape blend`

This helper turns multiple selected shape lines into a single line that contains multiple drawing segments with tag transitions between them.

In implementation terms, each shape is expanded, moved into global coordinates, normalized to `\pos(0,0)`, and stored with its tag state. The macro then lays the shapes out sequentially in one combined line by offsetting each subsequent shape according to the accumulated bounding-box widths, removing redundant tags through `tags\difference`, and concatenating the resulting tagged drawing text into one non-shape line.

The result is closer to a packed composite drawing line than to a boolean merge.

#### `Shape without holes`

This helper removes inner contours from the current shape by calling `Path.withoutHoles()`.

Use it when the desired result is only the outer shell of a complex shape, with interior cutouts discarded.

#### `Shape trim`

This helper trims a stack of overlapping shapes by subtracting later shapes from earlier ones.

The macro expands each selected shape and moves it into screen space. After all lines are collected, it iterates backward so that each earlier shape is cut by the geometry of the shapes that come after it. It then deletes the original selection, moves each surviving result back into its local coordinate system, and reinserts the trimmed lines.

In practice, this is a staged subtractive cleanup tool for overlapping shape sets.

#### `Shape to 0,0`

This helper rebases the shape so that the drawing itself is moved into global coordinates and the line position becomes `\pos(0,0)`.

The macro moves the path by the current line position, removes `\move`, inserts `\pos(0,0)`, and writes the moved drawing back. The visible result stays in place, but the coordinate system of the line becomes origin-based.

Use it when you want fully absolute drawing coordinates.

#### `Shape to pos`

This helper aligns the drawing origin with the first coordinate found in the line's `\clip`.

Implementation-wise, it parses the first clip coordinate pair, computes the delta between that point and the line's current `\pos`, moves the shape accordingly, removes `\move` and `\clip`, and replaces the line position with the extracted clip point.

Use it when a clip already encodes the anchor point you want the shape to use.

#### `Shape to origin`

This helper shifts the drawing so that the bounding-box top-left corner becomes the local origin of the shape.

After computing the bounding box, the macro moves the path to origin, then compensates the line's `\pos` or `\move` so the rendered result remains visually stationary.

Use it when you want a cleaner local coordinate system anchored at the top-left corner of the shape bounds.

#### `Shape to center`

This helper shifts the drawing so that the bounding-box center becomes the local origin of the shape.

It computes the center from the bounding box, moves the geometry to center, compensates `\pos` or `\move` by the same amount, and finally forces alignment to `\an7` through `Line.changeAlign` so the line metadata matches the new geometric anchor.

Use it when you want the shape centered around its own local origin.

#### `Reverse points`

This helper reverses contour direction for the shape, the clip, or both, depending on the stored configuration flags.

If shape reversal is enabled, it parses the shape into `Path`, reverses the point order, and writes it back. If clip reversal is enabled and a clip exists, it does the same for the clip geometry and rewrites either `\clip` or `\iclip`. The line is then updated with the modified geometry.

Use it when contour direction matters for interpolation, fill behavior, or downstream geometry operations.

## Envelope Distort

`Envelope Distort` is a mesh-driven shape warping macro.

Registered entry:

- `Envelope Distort / Make with Mesh`

The macro can either read a mesh already stored in `line.grid` or reconstruct one from `\clip`. It removes the active clip, converts the source shape and the mesh into `Path`, and then decides between a perspective transform and a denser envelope-distortion workflow depending on the structure of the mesh. In the non-perspective case it flattens the source shape and distorts each region against the real mesh pieces before rewriting the line.

Use it when a shape must be bent into a custom deformation field rather than moved by a standard transform.

## Make Image

`Make Image` is the raster-to-ASS macro family and the primary consumer of `ILL.IMG`.

Registered entries:

- `Make Image / Image Tracer`
- `Make Image / Pixels`
- `Make Image / Potrace`

### Image Tracer

This mode opens an image, decodes it through `IMG`, and then traces color regions with `Tracer.imagedataToTracedata`. The traced regions are converted into ASS lines with `Tracer.getAssLines`, which means the output is region-based rather than pixel-by-pixel.

If the source is animated, the macro can iterate frames and emit output frame by frame.

### Pixels

This mode performs direct raster conversion through `img\toAss(...)`.

It is the most literal image path in the project: instead of tracing vector regions, it converts image pixels into ASS drawing lines and emits the result directly.

### Potrace

This mode creates a `Potrace` object from the decoded image and extracts a traced monochrome shape with `pot\getShape()`.

Compared to `Image Tracer`, it is focused on one clean black-and-white vectorized contour rather than multi-color region tracing.

## Change Alignment

`Change Alignment` changes `\an` for text or shape lines without moving the visible result on screen.

Registered entry:

- `Change Alignment`

The macro presents a 3x3 alignment picker, requires exactly one target alignment, parses each selected line with `Line.extend`, and then delegates the actual compensation work to `Line.changeAlign`. The implementation therefore does not just rewrite the alignment number; it also recomputes the placement data required to preserve the rendered position.

## ILL - Split Text

`ILL - Split Text` is a structural line-expansion macro built on top of `Ass`, `Line`, `Text`, and `Tags`.

Registered entries:

- `By Chars`
- `By Words`
- `By Tags Blocks`
- `By Line Breaks`

The macro removes each original non-shape line, extends it into a parsed `Line`, and then calls one of four splitters: `Line.chars`, `Line.words`, `Line.tags`, or `Line.breaks`. Each generated fragment is inspected for angle and transform state, optionally receives an `\org`, and then has either `\pos` or `\move` recalculated through `Line.reallocate`. The updated tags are written back into the fragment text before the new lines are inserted into the script.

The result is not just textual splitting. It is a placement-aware expansion of one ASS line into multiple stable fragments.

## Line To FBF

`Line To FBF` is a frame-baking macro.

Registered entry:

- `Line To FBF`

The macro asks for a frame step, removes the original line, processes it with `Line.process`, and then expands it through `Line.callBackFBFWithStep`. For each generated frame slice it inserts one new line into the script.

Use it when transforms, movement, or timing-dependent line state must be materialized into explicit frame-by-frame ASS output rather than left as runtime tags.

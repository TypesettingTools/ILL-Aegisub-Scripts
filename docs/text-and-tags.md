# ILL Text And Tags Module Reference

## What This Module Solves

ASS dialogue is not just plain text. A usable macro needs to understand:

- individual tags such as `\pos`, `\move`, or `\bord`
- full tag blocks such as `{...}`
- text and tag blocks interleaved in one line
- line-level structures such as words, characters, breaks, shape mode, and frame expansion

That is the job of `Tag`, `Tags`, `Text`, and `Line`.

## Conventions

```moon
ILL = require "ILL.ILL"
{:Tag, :Tags, :Text, :Line, :Ass} = ILL
```

## `Tag`

`Tag` is the smallest ASS text unit handled by the library. It stores one parsed tag and converts its payload into something easier to work with in code.

### `Tag(raw, name, value, i)`

Creates one parsed ASS tag.

Arguments:

- `raw`: original tag text, such as `"\pos(100,200)"`.
- `name`: normalized tag name, such as `"pos"` or `"bord"`.
- `value`: raw payload extracted from the tag. The constructor normalizes it into numbers, booleans, coordinate arrays, or transform tables.
- `i`: original character position inside the tag block, used to preserve order.

Example:

```moon
tag = Tag "\\move(100,200,150,240,0,300)", "move", "100,200,150,240,0,300", 1
coords = tag\getValue!
```

### `tag\setValue(name, value, i = nil)`

Builds a tag from logical data instead of raw ASS text.

Arguments:

- `name`: tag name to build.
- `value`: normalized Lua value. Examples: number for `\bord`, table for `\pos`, boolean for `\b`.
- `i`: optional original index metadata.

Example:

```moon
tag = Tag!\setValue "pos", {320, 240}
raw = tostring tag
```

### `tag\getValue()`

Returns the normalized tag value.

This is what you usually want when reading `\pos`, `\move`, `\clip`, `\fad`, or `\t(...)` from parsed text.

### `tag\copy()`

Returns an independent copy of the tag object.

### `Tag.getPattern(name, withValue = false)`

Returns the parser pattern for one tag family.

Arguments:

- `name`: tag family name.
- `withValue`: when `true`, returns the capture pattern used to extract only the value.

## `Tags`

`Tags` represents one full tag block, not just one tag.

### `Tags(tags = "")`

Creates one parsed tag block.

Arguments:

- `tags`: raw tag-block string. The constructor also normalizes nested transforms, `\1c` aliases, and `\fr` aliases.

Example:

```moon
tags = Tags "{\\an7\\bord2\\shad0}"
```

### `tags\get()`

Returns the current raw tag string.

### `tags\open()` and `tags\close()`

Remove or add the surrounding `{}` delimiters.

These helpers are used internally so tags can be rewritten without worrying about braces at every step.

### `tags\animated(cmd = "hide")`

Temporarily hides or restores `\t(...)` tags so non-transform operations can inspect the rest of the block safely.

Arguments:

- `cmd`: `"hide"` replaces the leading slash inside `\t` payloads, anything else restores it.

### `tags\remove(...)`

Removes one or more tags or tag groups.

Arguments:

- `...`: each argument may be `"name"`, `{"name", replacement, n}`, or a group alias such as `"all"`, `"font"`, `"perspective"`, `"colors"`, `"shadow"`, or `"outline"`.

Example:

```moon
line.tags\remove "clip", "iclip"
line.tags\remove "font"
```

### `tags\insert(...)`

Inserts one or more tags into the block.

Arguments:

- `...`: each argument may be `"rawTag"`, `{"rawTag", invert}`, or `{{name, value}, invert}`.

This is the method most macros use when writing updated `\pos`, `\move`, `\clip`, or helper tags back into generated fragments.

Example:

```moon
line.tags\insert {{"pos", {320, 240}}, true}
line.tags\insert "\\bord0\\shad0"
```

### `tags\getTag(name, subTags = tags\get())`

Returns the underlying `Tag` object for one tag.

Arguments:

- `name`: tag name to search.
- `subTags`: optional source text used during internal parsing.

### `tags\split()`

Returns the full parsed tag list as `Tag` objects sorted by original position.

Use this when you need to inspect the exact tag sequence instead of just querying one name at a time.

### `tags\clean()`

Rebuilds the block into a normalized order and removes parser noise.

### `tags\clear(styleref = nil)`

Removes duplicate tags and optionally strips tags that only restate the style defaults.

Arguments:

- `styleref`: optional style table, usually `line.styleref`.

### `tags\difference(other)`

Keeps only the tag values that differ from another block.

Arguments:

- `other`: another `Tags` object used as the comparison source.

This is useful when rebuilding split lines and wanting to emit only the tags that actually changed between blocks.

### `tags\existsTag(name)`, `tags\existsTagAnd(...)`, and `tags\existsTagOr(...)`

Presence checks for tag names.

## `Text`

`Text` represents one dialogue line as alternating tag and text layers.

### `Text(text = "", isShape = false)`

Parses a full dialogue string into alternating tag and text blocks.

Arguments:

- `text`: full line text.
- `isShape`: when `true`, treats the body as ASS drawing data and skips normal text splitting logic.

Example:

```moon
text = Text "{\\bord2}Hello {\\i1}world"
```

### `text\stripped()`

Returns the text with all tag blocks removed.

### `text\iter()`

Iterates over parsed blocks, yielding `(tags, text, i, n)`.

This is the read-only traversal method when you want to inspect the structure of the original line.

### `text\callBack(fn)`

Maps the blocks through a callback.

Arguments:

- `fn`: callback receiving `(tags, text, i, n)` and returning replacement `(tags, text)`.

Example:

```moon
line.text\callBack (tags, text, i, n) ->
  return tags, text\upper!
```

### `text\modifyBlock(newTags, newText = nil, i = 1)`

Replaces one parsed block.

Arguments:

- `newTags`: replacement `Tags` object for the selected block.
- `newText`: optional replacement text for that block.
- `i`: 1-based block index.

### `text\moveToFirstLayer()`

Moves first-category tags such as `\pos`, `\move`, `\clip`, and `\fad` into the first tag block.

This mirrors how ASS effectively treats tags that should only have one active value per rendered line.

### `text\insertPendingTags(add_all = false, add_transforms = false)`

Propagates missing previous tags into later blocks.

Arguments:

- `add_all`: when `true`, propagates all missing tags.
- `add_transforms`: when `true`, also propagates `\t(...)`.

This is especially useful before splitting a line into blocks or explicit line-break fragments.

### `text\existsTag(name)`, `text\existsTagAnd(...)`, and `text\existsTagOr(...)`

Presence checks across all parsed blocks.

### `Text.getLineBreaks(text)`

Splits one raw line by explicit ASS line breaks while preserving the tags that remain in effect on each fragment.

Arguments:

- `text`: raw dialogue string containing optional `\N`.

Example:

```moon
breaks, n = Text.getLineBreaks "{\\fs50}AB\\N{\\bord3}CD"
```

## `Line`

`Line` is the high-level helper that turns one subtitle line into something macros can split, reposition, expand frame by frame, or convert into geometry.

### `Line.process(ass, line)`

Processes one line in place and fills cached style, metric, and positioning data.

Arguments:

- `ass`: `Ass` context with styles and script metadata.
- `line`: dialogue line to enrich.

This is the base step behind most text macros. It resolves the effective style, parses tags, computes metrics, and establishes the line's anchor position.

### `Line.extend(ass, line, noblank = true)`

Extends one processed line with line-break-level structures in `line.lines`.

Arguments:

- `ass`: `Ass` context.
- `line`: source line.
- `noblank`: when `true`, blank fragments are filtered out.

Example:

```moon
Line.extend ass, l
```

### `Line.update(ass, line, noblank = true)`

Clears cached data and recomputes the extended structures.

Arguments:

- `ass`: `Ass` context.
- `line`: line to refresh.
- `noblank`: forwarded to `Line.extend`.

### `Line.words(ass, line, noblank = false)`

Splits an extended line into word fragments.

Arguments:

- `ass`: `Ass` context.
- `line`: extended line.
- `noblank`: when `true`, blank-only fragments are skipped.

Example:

```moon
Line.extend ass, l
words = Line.words ass, l, true
```

### `Line.chars(ass, line, noblank = false)`

Splits an extended line into UTF-8-aware character fragments.

Arguments:

- `ass`: `Ass` context.
- `line`: extended line.
- `noblank`: when `true`, blank-only fragments are skipped.

### `Line.breaks(ass, line, noblank = false)`

Splits an extended line by `\N`.

Arguments:

- `ass`: `Ass` context.
- `line`: extended line.
- `noblank`: when `true`, empty break fragments are skipped.

### `Line.tags(ass, line, noblank = false)`

Splits an extended line into one fragment per text/tag block.

Arguments:

- `ass`: `Ass` context.
- `line`: extended line.
- `noblank`: when `true`, blank-only blocks are skipped.

### `Line.reallocate(sourceLine, generatedLine, isMove = false)`

Recomputes `\pos` or `\move` so a generated fragment keeps the same visual placement as the source line.

Arguments:

- `sourceLine`: original unsplit line.
- `generatedLine`: derived fragment line.
- `isMove`: when `true`, returns a six-value `\move` payload instead of a two-value `\pos`.

This is one of the core helpers behind `Split Text`.

### `Line.callBackTags(ass, line, fn)`

Calls `fn` once for each generated tag-block fragment after position tags are updated.

Arguments:

- `ass`: `Ass` context.
- `line`: extended source line.
- `fn`: callback receiving `(lineBlock, index)`.

### `Line.callBackShape(ass, line, fn)`

Calls `fn` once for each fragment after converting it to shape mode.

Arguments:

- `ass`: `Ass` context.
- `line`: source line.
- `fn`: callback receiving `(shapeLine, index)`.

This is the bridge between text workflows and geometry workflows.

### `Line.callBackExpand(ass, line, grid = nil, fn)`

Calls `fn` once for each fragment after expanding style transforms into final geometry.

Arguments:

- `ass`: `Ass` context.
- `line`: source line.
- `grid`: optional `{rows, cols, isBezier}` descriptor used by envelope workflows.
- `fn`: callback receiving `(expandedShapeLine, index)`.

### `Line.callBackFBF(ass, line, fn)`

Expands one line frame by frame using a step of `1`.

Arguments:

- `ass`: `Ass` context.
- `line`: processed source line.
- `fn`: callback receiving `(line, frame, endFrame, relativeIndex, totalFrames)`.

### `Line.callBackFBFWithStep(ass, line, step = 1, fn)`

Expands one line into frame slices while materializing `\move`, `\fade`, and `\t(...)`.

Arguments:

- `ass`: `Ass` context.
- `line`: processed source line.
- `step`: number of frames merged into each slice.
- `fn`: callback receiving `(line, frame, endFrame, relativeIndex, totalFrames)`.

Example:

```moon
Line.callBackFBFWithStep ass, l, 2, (line, frame, endFrame, i, n) ->
  ass\insertLine line, s
```

### `Line.changeAlign(line, an, width = nil, height = nil)`

Changes alignment while compensating position so the rendered result stays visually stable.

Arguments:

- `line`: source line.
- `an`: target ASS alignment.
- `width`: optional precomputed width.
- `height`: optional precomputed height.

### `Line.solveShadow(line)`

Returns the effective `xshad` and `yshad` values after reconciling `\shad`, `\xshad`, and `\yshad`.

Arguments:

- `line`: processed line.

### `Line.toShape(line)` and `Line.toPath(line)`

Convert text into ASS drawing data or a `Path`.

Arguments:

- `line`: line whose `line.data` and `line.text_stripped` should be converted.

Example:

```moon
shape = Line.toShape l
path = Line.toPath l
```

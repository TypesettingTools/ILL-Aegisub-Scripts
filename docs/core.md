# ILL Core Module Reference

## What This Module Covers

`ILL.ILL` is the main library module used by nearly every macro in the project. It contains:

- `Aegi` for Aegisub runtime interaction
- `Config` for persistent macro settings
- `Ass` for script and selection manipulation
- `Font` for font metrics
- utility modules such as `Math`, `Table`, `Util`, and `UTF8`

## Conventions

```moon
ILL = require "ILL.ILL"
{:Aegi, :Config, :Math, :Table, :Util, :UTF8, :Ass, :Font} = ILL
```

## `Aegi`

`Aegi` is the thin integration layer around Aegisub's runtime helpers.

### `Aegi.ffm(ms)`

Converts milliseconds to a frame index.

- `ms`: time in milliseconds.

Example:

```moon
startFrame = Aegi.ffm l.start_time
```

### `Aegi.mff(frame)`

Converts a frame index back to milliseconds.

- `frame`: video frame index.

### `Aegi.progressTitle(title)`

Sets the title of the progress dialog.

- `title`: progress window title.

### `Aegi.progressTask(task = "")`

Updates the current progress message.

- `task`: progress message.

### `Aegi.progressSet(value, max = 100)`

Sets numeric progress.

- `value`: current progress value.
- `max`: total progress range.

### `Aegi.progressCancelled()`

Returns whether the user cancelled the current operation.

### `Aegi.progressCancel()`

Aborts the current macro execution.

### `Aegi.display(interface, buttons, options, title)`

Shows an Aegisub dialog and returns the pressed button plus collected values.

- `interface`: Aegisub dialog definition array.
- `buttons`: button labels shown in the dialog.
- `options`: dialog options table.
- `title`: dialog title.

Example:

```moon
button, elements = Aegi.display interface, {"Ok", "Cancel"}, {close: "Cancel"}, "Transform"
```

## `Config`

`Config` is the persistence helper used by dialog-driven macros.

### `Config.getPath(dir)`

Builds the base config directory under `?user`.

- `dir`: relative directory under `?user`.

### `Config.getMacroPath(dir, namespace = script_namespace)`

Builds the macro-specific config path without the `.json` extension.

- `dir`: base config directory.
- `namespace`: filename stem used for the macro config.

### `Config.getElements(interface)`

Extracts a `{name = value}` table from a dialog definition.

- `interface`: dialog definition array whose `name`/`value` pairs should be extracted.

### `Config(interface = {}, dir = "/config/")`

Creates a configuration helper for one dialog schema.

- `interface`: dialog schema whose `value` fields act as defaults.
- `dir`: relative config directory under `?user`.

Example:

```moon
cfg = Config interface
```

### `config\setPath(dir = config.dir)`

Overrides the config directory.

- `dir`: relative config directory.

### `config\setJsonPath(namespace = script_namespace)`

Overrides the JSON filename used by the config object.

- `namespace`: filename stem before `.json`.

### `config\save(elements)`

Writes one set of collected UI values to disk.

- `elements`: table keyed by element name. The method also injects `__VERSION__`.

### `config\getInterface()`

Returns the interface with stored values applied when a compatible config file exists.

## `Ass`

`Ass` is the working subtitle context used by the macros. It wraps the subtitle data, the current selection, style metadata, and insertion/removal helpers.

### `Ass(sub, sel, activeLine, remLine = true)`

- `sub`: subtitle object received by the macro.
- `sel`: selected line indexes.
- `activeLine`: active selected line index.
- `remLine`: when `true`, removed lines are deleted from the script.

Example:

```moon
ass = Ass sub, sel, activeLine
```

### `ass\iterSub(copy = false)` and `ass\iterSel(copy = false)`

Iterate over subtitle lines or selected dialogue lines.

- `copy`: when `true`, also yields a deep-copied editable line.

Example:

```moon
for l, s, i, n in ass\iterSel!
  ass\progressLine s, i, n
```

### `ass\setLine(line, selectionIndex)`

Overwrites one existing line.

- `line`: replacement line object.
- `selectionIndex`: selected line index relative to the current processing context.

### `ass\insertLine(line, selectionIndex)`

Inserts a generated line after the referenced selection entry.

- `line`: line object to insert.
- `selectionIndex`: selected line index used as the insertion reference.

### `ass\removeLine(line, selectionIndex)`

Comments and optionally deletes a source line.

- `line`: source line object.
- `selectionIndex`: selected line index of that source line.

### `ass\progressLine(selectionIndex, i, n)`

Updates the progress window for one source line.

- `selectionIndex`: original selected line index.
- `i`: current loop index.
- `n`: total selected lines.

### `ass\warning(selectionIndex, message)` and `ass\error(selectionIndex, message)`

Emit contextual warnings or errors tied to the current source line.

- `selectionIndex`: original selected line index.
- `message`: user-facing explanation.

## `Font`

`Font` exposes metrics and text-to-shape conversion.

### `Font(styleData)`

Creates a font helper configured from effective style/tag data.

- `styleData`: processed style/tag table, usually `line.data`.

### `font\getTextExtents(text = nil)`

Measures one text string.

- `text`: string to measure.

### `font\getMetrics()`

Returns ascent, descent, and related font metrics.

### `font\getTextToShape(text = nil)`

Converts one text string into ASS drawing commands.

- `text`: string to convert into ASS drawing commands.

Example:

```moon
font = Font l.data
shape = font\getTextToShape l.text_stripped
```

## Utility Modules

### `Math`

Small numeric helpers used throughout interpolation and geometry code.

#### `Math.sign(a)`

- `a`: number to inspect.

#### `Math.clamp(a, b, c)`

Clamps a value into an interval.

- `a`: value being clamped.
- `b`: lower bound.
- `c`: upper bound.

#### `Math.round(a, dec = 3)`

Rounds a number.

- `a`: number to round.
- `dec`: decimal precision.

#### `Math.lerp(t, a, b)`

Linearly interpolates between two values.

- `t`: interpolation factor.
- `a`: start value.
- `b`: end value.

#### `Math.random(a, b)`

Returns a random number inside the requested interval.

- `a`: lower bound.
- `b`: upper bound.

#### `Math.perlinNoise(x, y, freq, depth, seed = 2000)`

Generates procedural 2D noise.

- `x`: sample x coordinate.
- `y`: sample y coordinate.
- `freq`: base frequency.
- `depth`: number of octaves.
- `seed`: random seed.

#### `Math.cubicRoots(a, b, c, d, ep = 1e-8)`

Returns the real roots of a cubic polynomial.

- `a`, `b`, `c`, `d`: cubic polynomial coefficients.
- `ep`: epsilon used when testing near-zero values.

### `Table`

Helpers for copying and editing plain Lua arrays/tables.

#### `Table.copy(tb, deepcopy = true)`

- `tb`: source table.
- `deepcopy`: when `true`, recursively copies nested tables.

#### `Table.push(tb, ...)`

- `tb`: target array.
- `...`: values appended to the end.

#### `Table.unshift(tb, ...)`

- `tb`: target array.
- `...`: values inserted at the beginning.

#### `Table.slice(tb, f, l, s)`

- `tb`: source array.
- `f`: first index.
- `l`: last index.
- `s`: step.

#### `Table.splice(tb, start, deleteCount, ...)`

- `tb`: array to edit.
- `start`: starting index.
- `deleteCount`: number of items to remove.
- `...`: optional items to insert.

#### `Table.view(tb, table_name = "table_unnamed", indent = "")`

Formats a table for debugging.

- `tb`: table to format.
- `table_name`: label used in the formatted output.
- `indent`: current indentation prefix.

### `Util`

Mixed helpers for string handling, ASS evaluation, interpolation, and filesystem checks.

#### `Util.lmatch(value, pattern, last = false)`

Returns the last match of a pattern.

- `value`: source string.
- `pattern`: Lua pattern to search.
- `last`: internal recursion cursor.

#### `Util.headTail(s, div)`

Splits a string into the part before and after the first delimiter match.

- `s`: source string.
- `div`: separator pattern.

#### `Util.splitByPattern(s, div)`

Splits a string repeatedly by a pattern.

- `s`: source string.
- `div`: separator pattern.

#### `Util.convertColor(mode, value)`

Converts between color encodings used by style data and ASS tags.

- `mode`: conversion mode.
- `value`: input color string.

#### `Util.getTimeInInterval(currTime, t1, t2, accel = 1)`

Returns normalized interpolation time in one interval.

- `currTime`: current relative time.
- `t1`: interval start.
- `t2`: interval end.
- `accel`: easing factor.

#### `Util.getAlphaInterpolation(currTime, t1, t2, t3, t4, a1, a2, a3, a = a3)`

Computes alpha progression across multiple fade segments.

- `currTime`: current relative time.
- `t1`, `t2`, `t3`, `t4`: fade boundary times.
- `a1`, `a2`, `a3`: alpha values.
- `a`: accumulator seed used internally.

#### `Util.getTagFade(currTime, lineDur, dec, ...)`

Resolves the effective alpha produced by `\fad` or `\fade`.

- `currTime`: current relative time.
- `lineDur`: full line duration.
- `dec`: base alpha already present before fade is applied.
- `...`: values unpacked from `\fad` or `\fade`.

#### `Util.getTagTransform(currTime, lineDur, ...)`

Resolves the interpolation factor of a `\t(...)`.

- `currTime`: current relative time.
- `lineDur`: full line duration.
- `...`: parsed transform timing fields.

#### `Util.getTagMove(currTime, lineDur, x1, y1, x2, y2, t1, t2)`

Resolves the current position produced by `\move(...)`.

- `currTime`: current relative time.
- `lineDur`: full line duration.
- `x1`, `y1`: move start position.
- `x2`, `y2`: move end position.
- `t1`, `t2`: optional move interval.

#### `Util.interpolation(t = 0.5, interpolationType = "auto", ...)`

Interpolates values of several supported types.

- `t`: interpolation factor.
- `interpolationType`: explicit mode such as `"number"`, `"alpha"`, `"color"`, `"shape"`, `"table"`, or `"auto"`.
- `...`: values to interpolate.

#### `Util.fixPath(path)`

Normalizes filesystem path separators.

- `path`: filesystem path to normalize.

#### `Util.fileExist(dir, isDir = false)`

Checks whether a file or directory exists.

- `dir`: path to test.
- `isDir`: when `true`, checks directory existence.

#### `Util.isBlank(t)`

Checks whether a string or line-like value is effectively blank.

- `t`: string or line-like value.

#### `Util.isShape(t)`

Checks whether a string or line-like value looks like ASS drawing data.

- `t`: string or line-like value.

#### `Util.checkClass(cls, name)`

Checks whether an object is an instance of the expected class.

- `cls`: object or instance to inspect.
- `name`: expected class name.

### `UTF8`

UTF-8 helpers for character-aware iteration.

#### `UTF8(s)`

- `s`: source UTF-8 string.

#### `UTF8.charrange(c, i)`

- `c`: source string.
- `i`: byte index of the character start.

#### `UTF8.charcodepoint(c)`

- `c`: one UTF-8 character.

#### `utf\chars()`

Iterates over UTF-8 characters.

#### `utf\len()`

Returns the UTF-8 character count.

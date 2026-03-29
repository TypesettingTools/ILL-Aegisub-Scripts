# ILL Core Module Reference

## What This Module Covers

`ILL.ILL` is the main library module used by nearly every macro in the project. It contains:

- `Aegi` for Aegisub runtime interaction
- `Config` for persistent macro settings
- `Ass` for script and selection manipulation
- `Font` for font metrics
- utility modules such as `Math`, `Table`, `Util`, and `UTF8`

Examples on this page are adapted from the shipped macros, especially `ILL.Shapery`, `ILL.MakeImage`, `ILL.SplitText`, and `ILL.Line2FBF`.

## Conventions

```moon
ILL = require "ILL.ILL"
{:Aegi, :Config, :Math, :Table, :Util, :UTF8, :Ass, :Font} = ILL
```

When this page shows `Ass(...)`, `Config(...)`, `UTF8(...)`, or `Font(...)`, that is the constructor form seen from user code after MoonScript lowers `new`.

## `Aegi`

`Aegi` is the thin integration layer around the Aegisub runtime. It keeps macros from scattering direct calls to `aegisub.progress`, `aegisub.dialog.display`, `aegisub.debug.out`, and `aegisub.cancel`.

### `Aegi.ffm(ms)`

Converts milliseconds to frame number using the active script timing context.

```moon
startFrame = Aegi.ffm l.start_time
endFrame = Aegi.ffm l.end_time
```

### `Aegi.mff(frame)`

Converts a frame number back to milliseconds.

```moon
s = Aegi.mff i
e = Aegi.mff math.min(i + step, endFrame)
```

### `Aegi.progressTitle(title)`

Sets the progress window title used by long-running macros.

### `Aegi.progressTask(task = "")`

Updates the current progress message.

This is heavily used by macros that process many lines, frames, or image chunks.

```moon
Aegi.progressTask "Tracing image regions"
```

### `Aegi.progressSet(value)`

Sets numeric progress.

### `Aegi.progressCancelled()`

Returns whether the user cancelled the current operation.

### `Aegi.progressCancel()`

Explicitly aborts the current macro execution through the Aegisub runtime.

### `Aegi.debug(value)` and `Aegi.log(value)`

Convenience wrappers for debug output.

### `Aegi.display(interface, buttons, options, title)`

Displays a dialog and returns the selected button and values.

This is the main entry point used by `Shapery`, `Make Image`, and other dialog-driven macros.

```moon
button, elements = Aegi.display interface, {"Ok", "Cancel"}, {close: "Cancel"}, "Transform"
```

## `Config`

`Config` is the persistence layer used by dialog-based macros to remember user choices between runs.

### `Config.getPath()`

Returns the configuration base path.

### `Config.getMacroPath()`

Returns the macro-specific path used for config storage.

### `Config.getElements(interface)`

Converts a dialog interface description into a serializable value table.

This is how `Shapery` turns its UI definitions into default config payloads.

```moon
cfg = Config.getElements cfgInterface
```

### `Config(interface = {})`

Creates a configuration object around one interface definition.

```moon
cfg = Config interfaces.pathfinder
```

### `config\setPath(path)`

Overrides the filesystem path used by this config object.

### `config\setJsonPath(path)`

Sets the JSON file path used for persistence.

```moon
cfg\setJsonPath script_namespace .. "Config"
```

### `config\reset()`

Resets persisted values back to interface defaults.

### `config\save(elements)`

Writes a set of dialog values to disk.

```moon
cfg\save elements
```

### `config\getInterface()`

Returns the interface definition with stored values applied.

This is the form normally passed back into `Aegi.display`.

```moon
button, elements = Aegi.display cfg\getInterface!, {"Ok", "Cancel"}, {close: "Cancel"}, "Pathfinder"
```

## `Ass`

`Ass` is the script-context object used by most macros. It wraps the subtitle data, the current selection, and insertion/removal helpers so a macro can safely rewrite lines.

### `Ass(sub, sel, activeLine, commit = true)`

Creates a working script context.

```moon
ass = Ass sub, sel, activeLine, false
```

### `ass\iterSel()`

Iterates over the selected lines and yields the line object, selection index, loop index, and total count.

This is the normal outer loop in most shipped macros.

```moon
for l, s, i, n in ass\iterSel!
    ass\progressLine s, i, n
```

### `ass\insertLine(line, selectionIndex)`

Inserts a generated line back into the script.

### `ass\removeLine(line, selectionIndex)`

Removes the current source line.

### `ass\replaceLine(line, selectionIndex)`

Overwrites a line in place.

### `ass\warning(selectionIndex, message)` and `ass\error(selectionIndex, message)`

Emit user-facing messages tied to the current processing context.

### `ass\getNewSelection()`

Returns the new selection after insertions and removals.

This is typically the macro return value after rewriting lines.

```moon
return ass\getNewSelection!
```

## `Font`

`Font` exposes font metrics and shape extraction helpers used when text has to be measured or converted into geometry.

### `Font(style, text = "", scale = 1)`

Creates a font helper for the given ASS style and optional text.

### `font\getTextExtents(text = nil)`

Returns text extents for one string, usually width and height information.

### `font\textToShape(text = nil)`

Converts text into ASS drawing data.

This is especially useful when a macro wants to leave text mode and operate on geometry instead.

## Utility Modules

These modules support the higher-level workflows above.

### `Math`

Core numeric helpers used by geometry, interpolation, and frame-aware calculations.

#### `Math.sign(a)`

Returns `1`, `0`, or `-1` depending on the sign of the number.

#### `Math.clamp(a, b, c)`

Limits `a` so it stays inside the interval `[b, c]`.

#### `Math.round(a, dec = 3)`

Rounds a number to a given number of decimal places.

#### `Math.lerp(t, a, b)`

Linearly interpolates between `a` and `b`, clamping `t` to the `0..1` range.

```moon
t = Math.clamp progress, 0, 1
x = Math.lerp t, x1, x2
```

#### `Math.random(a, b)`

Returns a random number between `a` and `b`.

#### `Math.perlinNoise(x, y, freq, depth, seed = 2000)`

Generates smooth procedural noise from a 2D coordinate.

#### `Math.cubicRoots(a, b, c, d, ep = 1e-8)`

Returns the real roots calculated for a cubic equation. This is mainly useful in curve-related internals.

### `Table`

Table and array helpers used when duplicating lines, building result lists, or editing parsed structures.

#### `Table.isEmpty(tb)`

Returns whether the table has no entries.

#### `Table.shallowcopy(tb)`

Creates a shallow copy of the table.

#### `Table.deepcopy(tb)`

Creates a deep copy of the table, including nested tables.

#### `Table.copy(tb, deepcopy = true)`

Copies the table using deep copy by default.

```moon
copy = Table.copy line
```

#### `Table.push(tb, ...)`

Appends one or more values to the end of an array.

#### `Table.pop(tb)`

Removes and returns the last value of an array.

#### `Table.reverse(tb)`

Returns a reversed array copy.

#### `Table.shift(tb)`

Removes and returns the first value of an array.

#### `Table.unshift(tb, ...)`

Inserts one or more values at the beginning of an array.

#### `Table.slice(tb, f, l, s)`

Returns a sliced array built from the selected interval.

#### `Table.splice(tb, start, delete, ...)`

Removes and/or inserts values inside an array, similar to splice operations in other languages.

#### `Table.view(tb, table_name = "table_unnamed", indent = "")`

Returns a formatted string representation of a table for debugging and inspection.

### `Util`

Mixed helpers for string handling, ASS tag evaluation, interpolation, filesystem checks, and lightweight type checks.

#### `Util.lmatch(value, pattern)`

Returns the last match found for a pattern inside a string.

#### `Util.headTail(s, div)`

Splits a string into the part before and after the first delimiter match.

#### `Util.splitByPattern(s, div)`

Repeatedly splits a string by a delimiter pattern and returns all pieces.

#### `Util.convertColor(mode, value)`

Converts style-format colors into ASS tag color or alpha format.

#### `Util.getTimeInInterval(currTime, t1, t2, accel = 1)`

Returns a normalized interpolation time between `0` and `1` for a time interval.

#### `Util.getAlphaInterpolation(currTime, t1, t2, t3, t4, a1, a2, a3)`

Computes alpha transitions across fade intervals.

#### `Util.getTagFade(currTime, lineDur, dec, ...)`

Resolves the effective alpha value produced by `\fad` or `\fade` at a given time.

#### `Util.getTagTransform(currTime, lineDur, ...)`

Resolves the effective interpolation factor used by a `\t(...)` transform at a given time.

#### `Util.getTagMove(currTime, lineDur, x1, y1, x2, y2, t1, t2)`

Resolves the current `x` and `y` position produced by a `\move(...)` tag at a given time.

#### `Util.interpolation(t = 0.5, interpolationType = "auto", ...)`

Interpolates numbers, alpha values, colors, shapes, or tables. In `"auto"` mode it detects the value type automatically.

#### `Util.fixPath(path)`

Normalizes path separators for the current operating system.

#### `Util.fileExist(dir, isDir)`

Checks whether a file or directory exists.

#### `Util.isBlank(t)`

Returns whether a line or string should be treated as blank.

#### `Util.isShape(t)`

Returns whether a text value looks like an ASS drawing shape.

#### `Util.checkClass(cls, name)`

Checks whether an object is an instance of a given class name.

### `UTF8`

UTF-8 aware text helpers used when a macro must work with characters rather than raw bytes.

#### `UTF8(s)`

Creates a UTF-8 helper around a string.

```moon
utf = UTF8 l.text_stripped
```

#### `UTF8.charrange(c, i)`

Returns the byte width of the character starting at position `i`.

#### `UTF8.charcodepoint(c)`

Returns the Unicode codepoint of one UTF-8 character.

#### `utf\chars()`

Iterates through the string character by character in UTF-8 aware form.

```moon
for i, char in utf\chars!
    -- safe character iteration
```

#### `utf\len()`

Returns the number of UTF-8 characters in the string.

## How This Module Is Usually Used

The most common library workflow starts here:

1. build an `Ass` context from the current subtitle selection
2. use `Aegi.display` and `Config` to collect user options
3. parse or transform lines through `Line`, `Text`, `Tags`, and `Path`
4. write the resulting lines back with `ass\insertLine`, `ass\replaceLine`, or `ass\removeLine`

That is why `ILL.ILL` is the real foundation of the project, not just a bag of helpers.

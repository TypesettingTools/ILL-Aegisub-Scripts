# ILL Text And Tags Module Reference

## What This Module Solves

ASS dialogue is not just plain text. A usable macro needs to understand:

- individual tags such as `\pos`, `\move`, or `\bord`
- full tag blocks such as `{...}`
- text and tag blocks interleaved in one line
- line-level structures such as words, characters, breaks, shape mode, and frame expansion

That is the job of `Tag`, `Tags`, `Text`, and `Line`.

Examples on this page are based on how the project macros actually use these classes, especially `ILL.SplitText`, `ILL.Shapery`, `ILL.EnvelopeDistort`, and `ILL.Line2FBF`.

## Conventions

```moon
ILL = require "ILL.ILL"
{:Tag, :Tags, :Text, :Line, :Ass} = ILL
```

When this page shows `Tag(...)`, `Tags(...)`, or `Text(...)`, it is using the constructor form seen from user code rather than exposing MoonScript's internal `new`.

## `Tag`

`Tag` represents one parsed ASS tag with a normalized value.

### `Tag(raw, name, value, i)`

Creates a parsed tag object.

The important point is that this is not just a stored raw string: the constructor converts the payload into something useful for code. Coordinate tags become structured values, booleans become booleans, and compound tags such as `\t(...)` keep their internal parts.

```moon
tag = Tag "\\pos(100,200)", "pos", "100,200", 1
coords = tag\getValue!
```

### `tag\setValue(name, value, i)`

Builds or rebuilds a tag from a logical value instead of from already-written ASS text.

Use this when a macro is generating a new tag to inject back into the line.

```moon
tag = Tag!\setValue "bord", 4
raw = tostring tag
```

### `tag\getValue()`

Returns the normalized value stored by the tag.

This is what matters when a macro needs to read `\pos`, `\move`, `\clip`, `\alpha`, and similar tags without reparsing strings manually.

### `tag\copy()`

Returns an independent copy of the tag object.

### `Tag.getPattern(name)`

Returns the matching pattern used by the parser for a tag family.

### `tag\__tostring()`

Serializes the object back into ASS tag syntax.

## `Tags`

`Tags` represents one full tag block, not just one tag.

It is the normal abstraction used when a macro needs to inspect, remove, or insert multiple tags on a line.

### `Tags(tags = "")`

Parses a tag block into an object that can be queried and rewritten.

```moon
tags = Tags "{\\an7\\bord2\\shad0}"
```

### `tags\get(name)`

Returns the normalized value of one tag if it exists.

```moon
align = tags\get "an"
```

### `tags\getTag(name)`

Returns the underlying `Tag` object.

Use this when you need tag metadata or want to clone and alter the tag itself.

### `tags\insert(tagSpec, replace = false)`

Inserts a tag or tag specification into the block.

This is heavily used in `Split Text` after fragment positions are recalculated and the macro needs to write `\pos`, `\move`, or helper tags back into each split line.

```moon
line.tags\insert {{"pos", Line.reallocate l, line}, true}
```

### `tags\remove(...)`

Removes one or more tags from the block.

`Envelope Distort` uses this pattern before re-inserting updated `\clip` data.

```moon
line.tags\remove "clip", "iclip"
```

### `tags\existsTag(name)` and `tags\existsTagOr(...)`

Checks whether a tag is present.

### `tags\split()`

Returns the parsed tag list in a form suitable for deeper inspection.

### `tags\clean()`

Normalizes the block by removing parser noise and collapsing redundant structure.

### `tags\clear()`

Removes all tags from the block.

### `tags\difference(other)`

Computes a tag-level difference against another tag block.

This is useful when a macro wants to preserve only the tags that changed.

### `tags\__tostring()`

Serializes the tag block back into `{...}` syntax.

## `Text`

`Text` represents one line as alternating text and tag blocks.

This is the layer that lets macros work on the structure of the line instead of on raw substring operations.

### `Text(text = "")`

Parses a line string into blocks.

```moon
text = Text l.text
```

### `text\iter()`

Iterates through parsed blocks.

Use it when you need to inspect the original text structure without rewriting it immediately.

### `text\callBack(fn)`

Maps the parsed blocks through a callback.

### `text\modifyBlock(block)`

Replaces or inserts one block in the parsed structure.

In `Split Text`, this is part of the final step where recalculated tags are written back into each generated line fragment.

```moon
line.text\modifyBlock line.tags
```

### `text\moveToFirstLayer()`

Moves pending tag data to the first text layer where it should be rendered.

### `text\insertPendingTags()`

Flushes pending tag changes into the text structure.

### `text\existsTag(name)` and `text\existsTagOr(...)`

Checks whether the line text contains a tag anywhere in the parsed structure.

### `Text.getLineBreaks(text)`

Splits a text string by explicit ASS line breaks in a parser-aware way.

## `Line`

`Line` is the high-level line object built on top of parsed ASS content.

It is what turns one subtitle line into something a macro can split, reshape, move, convert to geometry, or expand frame by frame.

### `Line.process(ass, line, doCopy = true)`

Parses a raw subtitle line into a richer object with cached data such as tags, style-driven metrics, and detected shape/text state.

### `Line.extend(ass, line, doCopy = true)`

Extends a line so the rest of the higher-level helpers can operate on it safely.

Most project macros do this before they attempt text splitting or geometry conversion.

```moon
Line.extend ass, l, false
```

### `Line.words(ass, line, doCopy = true)`

Splits the line into one line per word.

`ILL.SplitText` uses this to create independent dialogue fragments while preserving positioning.

### `Line.chars(ass, line, doCopy = true)`

Splits the line into one line per character using UTF-8 aware iteration.

### `Line.breaks(ass, line, doCopy = true)`

Splits the line by ASS line breaks.

### `Line.tags(ass, line, doCopy = true)`

Splits the line by tag block boundaries.

This is useful when the author already encoded semantic structure into tag groups.

### `Line.reallocate(sourceLine, generatedLine, keepMove = false)`

Computes a new `\pos` or `\move` payload so the generated fragment stays visually aligned after splitting.

This is one of the most important internal steps in `ILL.SplitText`.

```moon
line.tags\insert {{"move", Line.reallocate l, line, true}, true}
```

### `Line.callBackTags(ass, line, fn)`

Runs a callback over parsed tag data.

### `Line.callBackShape(ass, line, fn)`

Runs a callback over shape data after converting the line into geometry.

This is the hook style used by shape-processing macros.

### `Line.callBackExpand(ass, line, fn)`

Expands a line into several derived lines through a callback pipeline.

### `Line.callBackFBF(ass, line, fn)` and `Line.callBackFBFWithStep(ass, line, step, fn)`

Expand a line frame by frame.

`Line To FBF` uses the stepped version to materialize transforms into explicit per-frame lines.

```moon
Line.callBackFBFWithStep ass, l, elements.step, (line, i, endFrame, j, n) ->
    -- generate one frame slice
```

### `Line.changeAlign(line, an)`

Changes alignment while computing the position compensation needed to keep the rendered result stable.

This is the core idea behind the `Change Alignment` macro.

### `Line.solveShadow(line)`

Resolves shadow-related data into a usable form for geometry workflows.

### `Line.toShape(ass, line)` and `Line.toPath(ass, line)`

Convert a line into ASS drawing data or into a `Path` object so the geometry module can take over.

These methods are the bridge between text-level macros and shape-level macros.

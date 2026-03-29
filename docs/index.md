# ILL Aegisub Scripts

`ILL` is a library and macro collection for Aegisub focused on three hard problems:

- treating ASS text as structured data instead of opaque strings
- turning drawings into real geometric objects that can be transformed, merged, trimmed, offset, and warped
- converting raster images into ASS output through pixel conversion, color tracing, or monochrome vectorization

The project is split into user-facing macros and reusable modules. The macros are not thin demos: they are the main proof of how the modules are intended to be used in real typesetting workflows.

## Who This Documentation Is For

This site is written for two audiences:

- macro users who want to know what each tool actually does before running it in Aegisub
- macro authors who want to build on top of `ILL.ILL`, `ILL.IMG`, and `clipper2.clipper2`

## What You Will Find Here

### Guides

- [Macros](macros.md): implementation-based explanations of the shipped tools, what they operate on, and what kind of output they generate.
- [Modules](modules.md): a project map showing how the public modules fit together.

### Module Reference

- [Core](core.md): Aegisub integration, configuration storage, ASS context helpers, and core utility modules.
- [Text and Tags](text-and-tags.md): `Tag`, `Tags`, `Text`, and `Line`.
- [Geometry](geometry.md): `Point`, `Segment`, `Curve`, and `Path`.
- [Image](image.md): `IMG`, `Tracer`, and `Potrace`.
- [Clipper2](clipper2.md): the low-level geometry backend used by `Path`.

## Recommended Reading Order

### If You Mainly Want To Use The Macros

1. Start with [Macros](macros.md) to understand the intent and scope of each tool.
2. Read [Text and Tags](text-and-tags.md) if you work mostly with dialogue lines.
3. Read [Geometry](geometry.md) if you work mostly with drawings and clips.
4. Read [Image](image.md) only if you need raster-to-ASS workflows.

### If You Want To Build New Tools On Top Of The Library

1. Start with [Core](core.md) to understand `Ass`, `Aegi`, and `Config`.
2. Move to [Text and Tags](text-and-tags.md) to learn how lines are parsed and rewritten.
3. Read [Geometry](geometry.md) for shape manipulation and path-based workflows.
4. Use [Image](image.md) and [Clipper2](clipper2.md) when your tool really needs them.

## Project Map

### Main Macros

- `Shapery`
- `Envelope Distort`
- `Make Image`
- `Change Alignment`
- `ILL - Split Text`
- `Line To FBF`

### Public Modules

- `ILL.ILL`
- `ILL.IMG`
- `clipper2.clipper2`

## How The Project Is Intended To Be Used

The normal high-level workflow looks like this:

1. open a line or shape in Aegisub
2. run a macro that turns that line into a richer internal object
3. let the macro apply text parsing, geometry processing, or image conversion through the `ILL` modules
4. write the result back as one or more ASS lines

That same workflow is what the module reference pages document in detail.

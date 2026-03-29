# Modules

## Overview

The project is organized into three main blocks:

- `macros/`: user-facing commands registered in Aegisub.
- `modules/`: reusable MoonScript libraries.
- `ffi-packages/`: native code and build scripts used by the FFI wrappers.

## Public Module Map

### `ILL.ILL`

The main library of the project. It is the base module for text, tags, line processing, and shape manipulation.

Main areas:

- `Aegi`: Aegisub progress, dialog, and log integration.
- `Config`: macro configuration persistence.
- `Math`, `Table`, `Util`, `UTF8`: general-purpose helpers.
- `Ass`: ASS script reading, iteration, and updates.
- `Line`: line processing, expansion, splitting, and frame-by-frame workflows.
- `Tag`, `Tags`, `Text`: ASS tag and text parsing/manipulation.
- `Point`, `Segment`, `Curve`, `Path`: vector geometry.
- `Font`: text metrics and text-to-shape conversion.

## `ILL.IMG`

Image loading and conversion module.

Main areas:

- `IMG`: loads image files and converts them into ASS raster lines.
- `Tracer`: color tracing pipeline with presets.
- `Potrace`: monochrome vectorization.
- `LIBPNG`, `LIBJPG`, `LIBGIF`, `LIBBMP`: format-specific decoders.

## `clipper2.clipper2`

FFI wrapper for native geometric operations.

Main areas:

- `CPP.path`: native path creation and manipulation.
- `CPP.paths`: path collections and boolean operations.
- enums for `FillRule`, `JoinType`, and `EndType`.

## Relationship Between Modules

- `Shapery` mainly depends on `ILL.ILL` and `clipper2.clipper2`.
- `Envelope Distort` depends on `ILL.ILL`.
- `Make Image` depends on `ILL.IMG` and `ILL.ILL`.
- `Split Text`, `Change Alignment`, and `Line To FBF` mainly depend on `ILL.ILL`.

## Recommended Entry Point For Development

If you are building a new macro:

1. start with `Ass` and `Line`;
2. use `Text`, `Tags`, and `Tag` to manipulate ASS content;
3. use `Path` and `Point` when the workflow involves shape data;
4. use `IMG` or `clipper2` only when image processing or heavy geometry is actually needed.

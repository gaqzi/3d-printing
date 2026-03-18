# 3D Printing Models

A collection of open 3D models, primarily gridfinity bins and organizers. Each model is individually licensed — see the header of each `.scad` file for its license.

The default license is [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) unless otherwise specified in the file.

## Getting started

```bash
# Install dependencies (requires bd/beads: brew install beads)
script/bootstrap

# Build all models
script/build

# Build a specific model
script/build kiprim-ld50e-laser-distance-measurer.scad

# Build multi-color parts (one STL per part)
script/build kiprim-ld50e-laser-distance-measurer.parts

# Build a single part
PART=lip script/build kiprim-ld50e-laser-distance-measurer.parts

# Verify all models compile
script/build check

# Clean build output
script/build clean
```

## OpenSCAD IDE setup

This project requires a **snapshot build** of OpenSCAD (2026+). The stable release (2021.01) is very outdated and missing features used here. Download the latest snapshot from [openscad.org/downloads](https://openscad.org/downloads.html).

Once installed, open OpenSCAD and go to **Edit > Preferences**:

- **Advanced** tab: set **3D Rendering Backend** to **Manifold** (much faster renders)
- **Features** tab: check **textmetrics** (needed for the gridfinity base text feature)

## Multi-color printing

Models with a `.parts` file support multi-color printing. Each part exports as a separate STL that can be assigned a different filament in the slicer.

To import into Bambu Studio: select all the part STLs at once and it will offer to import them as parts of the same object. Then assign filaments to each part.

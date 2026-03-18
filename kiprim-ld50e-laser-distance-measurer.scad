// SPDX-License-Identifier: CC-BY-SA-4.0
// Copyright (c) 2026 Björn Andersson <ba@bjorn.now>

include <vendor/gridfinity_extended_openscad/modules/gridfinity_constants.scad>
use <vendor/gridfinity_extended_openscad/modules/module_gridfinity_cup.scad>
use <vendor/gridfinity_extended_openscad/modules/module_gridfinity.scad>

// Select which part to render: "bin", "lip", "floor", or "all" (preview)
PART = "all";

// Bin dimensions in gridfinity units
width = [2, 0];   // 2 units = 84mm
depth = [3, 0];   // 4 units = 168mm
height = [4, 0];  // 4 units = 28mm

// Internal cavity approximate dimensions (after walls + clearance)
// X: 2*42 - 2*0.5(clearance) - 2*0.95(wall) ≈ 81.1mm
// Y: 4*42 - 2*0.5(clearance) - 2*0.95(wall) ≈ 165.1mm

// Tool cutout shape (measurements of Kiprim LD50E + manual)
// Bottom layer: manual recess (73 x 104 x 18.5mm)
// Upper layer: tool recess (55 x 115 x 15mm), offset inward
module tool_shape() {
    // Manual recess (open slot, full height so manual slides in from top)
    cube([73, 104, 18.5]);
    // Tool recess (narrower, extends beyond manual in Y)
    translate([9, -5.5, 3.5])
        cube([55, 115, 15]);
}

// Center the cutout in the bin cavity
cavity_x = 2 * 42 - 2 * 0.5 - 2 * 0.95;  // ~81.1mm
cavity_y = 3 * 42 - 2 * 0.5 - 2 * 0.95;   // ~165.1mm

tool_x_extent = 73;
tool_y_min = -5.5;
tool_y_extent = 109.5 - (-5.5);  // = 115

x_offset = (cavity_x - tool_x_extent) / 2 + 0.95 + 0.5;
y_offset = (cavity_y - tool_y_extent) / 2 + 0.95 + 0.5 - tool_y_min;
z_offset = 10;

floor_thickness = 0.6;

// --- Modules for each part ---

module cup_with_lip() {
    gridfinity_cup(
        width = width, depth = depth, height = height,
        filled_in = "enabled",
        lip_settings = LipSettings(lipNotch = true)
    );
}

module cup_no_lip() {
    gridfinity_cup(
        width = width, depth = depth, height = height,
        filled_in = "enabled",
        lip_settings = LipSettings(lipStyle = "none", lipNotch = true)
    );
}

module bin_part() {
    difference() {
        cup_no_lip();
        // Tool cavity
        translate([x_offset, y_offset, z_offset])
            tool_shape();
        // Remove floor slab volumes so color pieces fit flush
        floor_part();
    }
}

module lip_part() {
    difference() {
        cup_with_lip();
        cup_no_lip();
    }
}

module floor_part() {
    translate([x_offset, y_offset, z_offset]) {
        // Manual recess floor (bottom of open slot)
        cube([73, 104, floor_thickness]);
        // South shelf (tool head rests here, y = -5.5 to 0)
        translate([9, -5.5, 3.5])
            cube([55, 5.5, floor_thickness]);
        // North shelf (tool bottom rests here, y = 104 to 109.5)
        translate([9, 104, 3.5])
            cube([55, 5.5, floor_thickness]);
    }
}

// --- Render ---

set_environment(
    width = width,
    depth = depth,
    height = height,
    render_position = "zero",
    setColour = "disabled"
)
if (PART == "bin") {
    bin_part();
} else if (PART == "lip") {
    lip_part();
} else if (PART == "floor") {
    floor_part();
} else {
    // "all" — preview with colors
    // render() forces CGAL evaluation so lip difference displays correctly in F5
    color("grey") bin_part();
    color("white") render() lip_part();
    color("red") floor_part();
}

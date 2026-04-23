// SPDX-License-Identifier: CC-BY-SA-4.0
// Copyright (c) 2026 Björn Andersson <ba@bjorn.now>

include <vendor/gridfinity_extended_openscad/modules/gridfinity_constants.scad>
use <vendor/gridfinity_extended_openscad/modules/module_gridfinity_cup.scad>
use <vendor/gridfinity_extended_openscad/modules/module_gridfinity.scad>
use <vendor/gridfinity_extended_openscad/modules/module_lip.scad>

// Select which part to render: "cup", "lip", "floor", or "all" (preview)
// In the slicer, import the lip and floor as modifier meshes (not normal
// parts). Modifiers change the filament color without creating separate
// perimeters, avoiding body boundary artifacts on the outer wall.
PART = "all";

// Cup dimensions in gridfinity units
cup_units_x = [2, 0];
cup_units_y = [3, 0];
cup_units_z = [4, 0];

// Gridfinity cup geometry
gf_clearance      = 0.5;
gf_wall_thickness = 0.95;
cup_inner_x = 2 * gf_pitch - 2 * gf_clearance - 2 * gf_wall_thickness;
cup_inner_y = 3 * gf_pitch - 2 * gf_clearance - 2 * gf_wall_thickness;

// --- Physical measurements of Kiprim LD50E + manual ---

manual_width     = 72;
manual_depth     = 103;
manual_thickness = 3;

tool_width  = 50.5 - 4.5; // the ends taper from 50.5 down to 42mm on the bottom and 44mm at the top, reduce for fit and the width for the manual give plenty of room
tool_depth  = 109.5;
tool_height = 25;  // recess is shallower to save plastic

tool_recess_height = 15;

// --- Derived dimensions (with margin) ---

manual_recess_width  = manual_width + 1;
manual_recess_depth  = manual_depth + 1;
manual_recess_height = manual_thickness + 0.5 + tool_recess_height;

tool_recess_width = tool_width + 1;
tool_recess_depth = tool_depth + 2;
tool_step_z       = manual_thickness + 0.5;  // tool shelf sits on top of manual layer

tool_x_inset        = (manual_recess_width - tool_recess_width) / 2;
tool_overhang_south = (tool_recess_depth - manual_recess_depth) / 2;
tool_overhang_north = tool_recess_depth - manual_recess_depth - tool_overhang_south;

x_offset = (cup_inner_x - manual_recess_width) / 2 + gf_wall_thickness + gf_clearance;
y_offset = (cup_inner_y - tool_recess_depth) / 2 + gf_wall_thickness + gf_clearance + tool_overhang_south;
z_offset = 10;

floor_thickness = 0.6;

// Cup outer dimensions (for thermal relief placement)
cup_outer_x = cup_units_x[0] * gf_pitch;
cup_outer_y = cup_units_y[0] * gf_pitch;
cup_top_z   = cup_units_z[0] * gf_zpitch;

// Thermal relief: air gap ring inside the wall at cross-section transitions.
// When a large solid mass cools, it contracts and pulls on the outer wall,
// creating a visible line. The relief breaks this thermal connection.
relief_width  = 1;    // width of the air gap
relief_height = 5;    // height of the air gap
relief_inset  = 3;    // distance from outer wall to gap (clears corner radius)
relief_radius = 2;    // corner radius for the relief ring

// --- Tool cutout shape ---

recess_radius = 1;  // corner radius for recess cutouts

module rounded_cube(size, r) {
    // Cube with rounded vertical corners, same outer dimensions
    translate([r, r, 0])
        linear_extrude(size[2])
            offset(r = r)
                square([size[0] - 2*r, size[1] - 2*r]);
}

module tool_shape() {
    // Manual recess — open slot, extrudes to top so manual slides in
    rounded_cube([manual_recess_width, manual_recess_depth, manual_recess_height], recess_radius);
    // Tool recess — narrower, extends beyond manual in Y
    translate([tool_x_inset, -tool_overhang_south, tool_step_z])
        rounded_cube([tool_recess_width, tool_recess_depth, tool_recess_height], recess_radius);
}

// --- Modules for each part ---

module thermal_relief(z, inset_override = -1) {
    // Rounded ring void inside the wall to break thermal contraction pull.
    // Inset far enough from the outer wall to clear the gridfinity corner
    // radius, with rounded corners for smooth toolpaths.
    inset = gf_clearance + (inset_override >= 0 ? inset_override : relief_inset);
    outer_x = cup_outer_x - 2*inset;
    outer_y = cup_outer_y - 2*inset;
    inner_x = outer_x - 2*relief_width;
    inner_y = outer_y - 2*relief_width;
    translate([inset, inset, z - relief_height/2])
        difference() {
            rounded_cube([outer_x, outer_y, relief_height], relief_radius);
            translate([relief_width, relief_width, -0.01])
                rounded_cube([inner_x, inner_y, relief_height + 0.02], relief_radius);
        }
}

module cup_part() {
    difference() {
        gridfinity_cup(
            width = cup_units_x, depth = cup_units_y, height = cup_units_z,
            filled_in = "enabled",
            lip_settings = LipSettings(lipNotch = true)
        );
        translate([x_offset, y_offset, z_offset])
            tool_shape();
        thermal_relief(z_offset);                   // at recess start
        thermal_relief(cup_top_z, inset_override=1);  // at lip start (less inset — lip walls are thinner)
    }
}

module lip_part() {
    // Render just the lip ring using the library's dedicated module.
    translate([0, 0, cup_units_z[0] * gf_zpitch - fudgeFactor * 2])
        cupLip(
            num_x = cup_units_x[0],
            num_y = cup_units_y[0],
            wall_thickness = gf_wall_thickness,
            lip_notches = true
        );
}

module floor_part() {
    translate([x_offset, y_offset, z_offset]) {
        rounded_cube([manual_recess_width, manual_recess_depth, floor_thickness], recess_radius);
        // South shelf — tool head rests here
        translate([tool_x_inset, -tool_overhang_south, tool_step_z])
            cube([tool_recess_width, tool_overhang_south, floor_thickness]);
        // North shelf — tool bottom rests here
        translate([tool_x_inset, manual_recess_depth, tool_step_z])
            cube([tool_recess_width, tool_overhang_north, floor_thickness]);
    }
}

// --- Render ---

set_environment(
    width = cup_units_x,
    depth = cup_units_y,
    height = cup_units_z,
    render_position = "zero",
    setColour = "disabled"
)
if (PART == "cup") {
    cup_part();
} else if (PART == "lip") {
    lip_part();
} else if (PART == "floor") {
    floor_part();
} else {
    // "all" — preview with colors
    color("grey") cup_part();
    color("white") lip_part();
    color("red") floor_part();
}

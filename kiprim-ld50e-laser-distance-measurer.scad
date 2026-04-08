// SPDX-License-Identifier: CC-BY-SA-4.0
// Copyright (c) 2026 Björn Andersson <ba@bjorn.now>

include <vendor/gridfinity_extended_openscad/modules/gridfinity_constants.scad>
use <vendor/gridfinity_extended_openscad/modules/module_gridfinity_cup.scad>
use <vendor/gridfinity_extended_openscad/modules/module_gridfinity.scad>

// Select which part to render: "cup", "lip", "floor", or "all" (preview)
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

// --- Tool cutout shape ---

module tool_shape() {
    // Manual recess — open slot, extrudes to top so manual slides in
    cube([manual_recess_width, manual_recess_depth, manual_recess_height]);
    // Tool recess — narrower, extends beyond manual in Y
    translate([tool_x_inset, -tool_overhang_south, tool_step_z])
        cube([tool_recess_width, tool_recess_depth, tool_recess_height]);
}

// --- Modules for each part ---

module cup_with_lip() {
    gridfinity_cup(
        width = cup_units_x, depth = cup_units_y, height = cup_units_z,
        filled_in = "enabled",
        lip_settings = LipSettings(lipNotch = true)
    );
}

module cup_no_lip() {
    gridfinity_cup(
        width = cup_units_x, depth = cup_units_y, height = cup_units_z,
        filled_in = "enabled",
        lip_settings = LipSettings(lipStyle = "none", lipNotch = true)
    );
}

module cup_part() {
    difference() {
        cup_no_lip();
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
        cube([manual_recess_width, manual_recess_depth, floor_thickness]);
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
    // render() forces CGAL evaluation so lip difference displays correctly in F5
    color("grey") cup_part();
    color("white") render() lip_part();
    color("red") floor_part();
}

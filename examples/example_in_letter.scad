/*
 * Example of how to create a scaled engineering drawing using inches
 *
 * Copyright 2017 Grant Likely <grant.likely@secretlab.ca>
 *
 * SPDX-License-Identifier: MIT
 *
 * Creates an engineering drawing in 1:2 scale, showing measurements in inches
 * and plotted on US letter sized paper.
 *
 * To see how scale and units can be controlled on a drawing, try changing
 * 'myscale = 1/100', and '$dim_units="m"', and see what happens.
 */

use <../dimlines.scad>
use <widget.scad>

$dim_pagename="letter";
$dim_units="inch";
pagesize = dim_pagesize();
myscale = 1/2;

// dim_unitscale() gives the $dim_units size of an OpenSCAD unit
in = 1/dim_unitscale();
widget_size = [6*in, 2*in, 2.5*in];

/* Draw all the scaled parts of the drawing. Note that $dim_modelscale is set
 * inside this block only. $dim_modelscale is used when an object is scaled
 * down to fit on the sheet. It makes sure the lines and fonts are the correct
 * size after scaling the object. Otherwise the sizes of different parts of the
 * diagram will not match.
 */
union() {
    $dim_modelscale=myscale;
    color("black") {
        translate([pagesize.x*2/8, pagesize.y*6/8]) scale(dim_modelscale())
        widget(widget_size, action="dim:top");

        translate([pagesize.x*2/8, pagesize.y*3/8]) scale(dim_modelscale())
        rotate([-90,0,0]) widget(widget_size, action="dim:front");

        translate([pagesize.x*6/8, pagesize.y*3/8]) scale(dim_modelscale())
        rotate([0,-90,0]) rotate([-90,0,0])
            widget(widget_size, action="dim:right");
    }

    translate([pagesize.x*6/8, pagesize.y*6/8]) scale(dim_modelscale())
        rotate([-45,0,0]) rotate([0,0,45])
        widget(widget_size);
}


/* Draw the titleblock */
fs = dim_fontsize();
title_width = 50*fs;
row_height = 3*fs;

cols = [0, title_width*0.167, title_width*0.333, title_width*0.667,
        title_width*0.73, title_width*0.9];
rows = [0, -row_height, -row_height*2, -row_height*3];

// spacing tweaks to fit into the blocks
desc_x = 0.2*fs; // column offset for start of small text
desc_y = -fs; // row offset for start of small text
det_y = -2.5*fs;  // row offset for start of detail text
desc_size = .65; // relative size of description text

lines = [
    // horizontal lines
    [cols[0], rows[0], "horz", title_width, 2],
    [cols[2], rows[1], "horz", title_width - cols[2], 1],
    [cols[0], rows[2], "horz", title_width, 2],

    // vertical lines
    [0, 0, "vert", row_height * 2, 2],
    [cols[2], rows[0], "vert", row_height * 2, 1],
    [cols[3], rows[0], "vert", row_height * 2, 1],
    [cols[4], rows[1], "vert", row_height, 1],
    [cols[5], rows[1], "vert", row_height, 1],
    [title_width, 0, "vert", row_height * 2, 2],
];

descs = [
    [cols[2]+desc_x, rows[0]+desc_y, "horz", "Title", desc_size],
    [cols[3]+desc_x, rows[0]+desc_y, "horz", "Scale", desc_size],
    [cols[2]+desc_x, rows[1]+desc_y, "horz", "Creator", desc_size],
    [cols[3]+desc_x, rows[1]+desc_y, "horz", "Rev", desc_size],
    [cols[4]+desc_x, rows[1]+desc_y, "horz", "Date of issue", desc_size],
    [cols[5]+desc_x, rows[1]+desc_y, "horz", "Sheet", desc_size]
];

details = [
    [cols[0]+desc_x*5, rows[0]+det_y, "horz", "Example Widget in inches", 1],
    [cols[2]+desc_x, rows[0]+det_y, "horz", "Sample Part", 1], //Title
    [cols[3]+desc_x, rows[0]+det_y, "horz", str("1:",1/myscale), 1], //Scale
    [cols[2]+desc_x, rows[1]+det_y, "horz", "G. Likely", 1], //Creator
    [cols[3]+desc_x, rows[1]+det_y, "horz", "", 1], //Rev
    [cols[4]+desc_x, rows[1]+det_y, "horz", "2017-5-17", 1], //Date of issue
    [cols[5]+desc_x, rows[1]+det_y, "horz", "1/1", 1] //Sheet
];

color("black") {
    translate([pagesize.x-title_width-dim_pagemargin(),
               dim_pagemargin()+row_height*2])
        dim_titleblock(lines, descs, details);
    dim_pageborder();
}


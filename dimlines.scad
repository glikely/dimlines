/* Dimension lines for OpenSCAD.
 *
 * Copyright 2013-2016 Don Smiley
 * Copyright 2017 Grant Likely <grant.likely@secretlab.ca>
 *
 * SPDX-License-Identifier: MIT
 *
 * What this program does:
 *
 * This program can draw lines with arrows and has a primitive dimensioning
 * element for putting text within arrows.  In addition, should the area being
 * dimensioned be too narrow, there is a provision for putting the text on
 * either side of the arrows.
 *
 * The dimension lines are drawn on the xy plane and are meant to be seen in a
 * top view.
 *
 * =======================================================
 * Be sure to view this from above -- ctrl-4
 * =======================================================
 *
 * To use this program, copy this file into your OpenSCAD project or library
 * directory and add "use <dimlines.scad>" to your OpenSCAD files. You may
 * optionally modify the size constants by setting $dim_fontsize and
 * $dim_linewidth in your scad file.
 *
 * Available:
 *
 * Assorted constants to ease the use of dimensioning line.  Because there is
 * no introspection regarding the dimensions of your creations, you will want
 * to adjust the parameters to fit the context of your creation.  You can adjust
 * the size of the text, lines, etc to match the rest of your objects.
 *
 * the following functions or modules are available.
 *
 *  dim_line(length, weight, left, right)
 *      Can draw a line with the options of including an arrow at either end
 *
 *  dim_circlecenter(radius, weight, size)
 *      Draws the cross in the center of a circle.
 *
 *  dim_dimension(length, text, weight, loc, offset, center)
 *      draws text within lines, such as <--- 3.5 --->
 *      with the use of the variable pos you can alter the placement of the text
 *      loc="center"      <--- 3.5 --->  this is the default
 *      loc="left"        3.5 <---->
 *      loc="right"       <----> 3.5
 *      loc="outside"     ---> 3.5 <---
 *
 *      Can also pass in text such as a variable name in place of a
 *      numeric dimension.
 *
 *  dim_leaderline(radius, text, angle, dlength, hlength,
 *                 direction=undef, weight, do_circle)
 *
 *      Pointer to the edge of a circle and showing text
 *
 *      usage of the leader line:
 *          translate to the center of the circle and call dim_leaderline().
 *
 *      Typically leader lines have a bend in them.  The angle variable is used
 *      to specify the angle from which the line will point to the center of the
 *      circle.  The radius specifies the location of the arrow. 'dlength' and
 *      'hlength' are the lengths of the diagonal and horizontal portions of the
 *      leader line respectively. The horizontal line will extend to the left or
 *      right depending on the angle, but a specific direction can be forced by
 *      setting direction to "right" or "left".
 *
 *
 * Created by Don Smiley
 *
 */

/**
 * Constants related to the annotation lines
 *
 * Because the dimension of the part to be documented can vary widely, you
 * probably are going to need to adjust the parameters to fit the context of
 * your part.
 *
 * The following special variables can be set from user code to control the
 * appearance of dimension lines.
 *
 * Variable
 * $dim_font        - Typeface for dimension labels. (default: OpenSCAD default)
 * $dim_fontsize    - Size of font in base units. Is approximately the height
 *                    of a single line of text. (default: 10pt font, or 8*pt
 *                    because font height over baseline is smaller than the
 *                    described font size.) If you change $dim_fontsize
 *                    significantly, you should make a similar change to
 *                    $dim_linesize
 * $dim_linewidth   - Width of lines. (default: 1pt)
 * $dim_extrude_flag - (bool) If true, extrude dimension lines into 3D objects.
 * $dim_mmsize      - Size of mm in base units. OpenSCAD models normally use a
 *                    1:1 mapping between base units and mm, and there should
 *                    be no reason to set $dim_mmsize. However, if you're
 *                    working with a model that uses a different scale, then
 *                    this parameter can be changed. (default: 1)
 * $dim_units       - Measurement units to use when displaying dimensions.
 *                    Supported units include: "mm", "cm", "m", "inch", "feet",
 *                    "points". (default: "mm")
 *
 * For example, the following parameters were used for a part 3.5 units long.
 * $dim_fontsize is set to about 5% of the object length, or 0.175 units.
 */

// Shortcuts for units of measure
mm = 1;
inch = mm * 25.4;
foot = inch * 12;
pt = inch/72;

// Table of units. Each tuple is [name, scale, symbol]
units = [
    ["mm", 1, " mm"],
    ["cm", 0.1, " cm"],
    ["m", 0.001, " m"],
    ["inch", 1/inch, "\""],
    ["feet", 1/foot, "\'"],
    ["points", 1/pt, " pt"]
];

// Page sizes
pagesizes = [
    ["A0", [1189,841]],
    ["A1", [841,594]],
    ["A2", [594,420]],
    ["A3", [420,297]],
    ["A4", [297,210]],
    ["letter", [279.4,215.9]],
    ["11x17", [431.8, 279.4]],
];

// configuration for units of measurement
function dim_mmsize() = is_undef($dim_mmsize) ? mm : $dim_mmsize;
function dim_units() = is_undef($dim_units) ? "mm" : $dim_units;
function dim_unitscale() = units[search([dim_units()], units)[0]][1] / dim_mmsize();
function dim_unitsymbol() = units[search([dim_units()], units)[0]][2];
function dim_modelscale() = is_undef($dim_modelscale) ? 1 : $dim_modelscale;

// configuration for font, font size, line size and whether to extrude into 3D
function dim_font() = is_undef($dim_font) ? undef : $dim_font;
function dim_fontsize() = (is_undef($dim_fontsize) ? 10*pt*0.8 : $dim_fontsize) / dim_modelscale();
function dim_linewidth() = (is_undef($dim_linewidth) ? 1 * pt : $dim_linewidth) / dim_modelscale();
function dim_extrude_flag() = is_undef($dim_extrude) ? true : $dim_extrude;

// configuration for page size and border
function dim_pagename() = is_undef($dim_pagename) ? "A4" : $dim_pagename;
function dim_pagesize() = pagesizes[search([dim_pagename()], pagesizes)[0]][1];
function dim_pagemargin() = is_undef($dim_pagemargin) ? 10+dim_fontsize() : $dim_pagemargin;

// BUG: The OpenSCAD built in font (at least on the Debian packaged version) is
// missing some symbols. ex. the diameter '⌀' glyph. Uncomment the following if
// you have problems with the font.
//$dim_font="FreeSans";

/**
 * dim_extrude() - Helper to optionally extrude 2D dimension objects to 3D.
 *
 * Intended for internal use of this library. dim_extrude() should be prefixed
 * onto every call to a 2D module like square(), circle(), and polygon(). If
 * $dim_extrude is true, then it will extrude the shapes. Otherwise it will
 * leave them as 2D.
 */
module dim_extrude()
{
    if (dim_extrude_flag())
        linear_extrude(dim_linewidth()*0.01, convexity=10)
            children();
    else
        children();
}

/**
 * dim_text() - Simple text() wrapper to extrude and use dimline defaults
 *
 * Uses exact same arguments as the built in text() module, except the size argument
 * is replaced with weight. Weight scales the text size based on dim_fontsize().
 */
module dim_text(text, weight=1, font=dim_font(), halign="left", valign="baseline",
                spacing=1, direction="ltr", language="en", script="latin")
{
    dim_extrude()
        text(text, size=dim_fontsize()*weight, font=font, halign=halign,
             valign=valign, spacing=spacing, direction=direction,
             language=language, script=script, $fn=25);
}

module dim_arrow(arr_points, arr_length)
{
    // arrow points to the left
    dim_extrude() polygon(
        points = [[0, 0],
                [arr_points, arr_points / 2],
                [arr_length, 0],
                [arr_points, -arr_points / 2]],
        paths = [[0, 1, 2, 3]], convexity = 2);
}

/**
 * dim_line() - Draw a horizontal line with optional arrows
 * length: length of the line in OpenSCAD units
 * weight: Thickness of the line relative to dim_linewidth(). With default
 *         values, this will draw a 1pt thickness line.
 * left: (str) Line ending for the beginning of the line
 * right: (str) Line ending for the end of the line if true.
 *
 * Valid values for @left and @right are: "arrow", "round", "flat"
 * and "square". Default value is "flat".
 */
module dim_line(length, weight=1, left=undef, right=undef)
{
    /* This module draws a line that can have an arrow on either end.  Because
     * the intended use is to be viewed strictly from above, the height of the
     * line is set arbitrarily thin.
     *
     * The factors arr_length and arr_points are used to create a proportionate
     * arrow. Your sense of asthetics may lead you to choose different
     * numbers.
     */
    width = dim_linewidth()*weight;
    arr_points = width * 4;
    arr_length = arr_points * .6;
    line_length = length - arr_length * ((left=="arrow" ? 1 : 0) + (right=="arrow" ? 1 : 0));

    translate([left=="arrow" ? arr_length : 0, -width / 2])
        dim_extrude() square([line_length, width], center=false);

    for (end = [[left, false], [right, true]]) {
        translate([end[1] ? length : 0, 0]) rotate([0, 0, end[1] ? 180 : 0]) {
            if (end[0] == "arrow")
                dim_arrow(arr_points, arr_length);
            else if (end[0] == "round")
                dim_extrude() circle(width/2, $fn=16);
            else if (end[0] == "square")
                dim_extrude() square(width, center=true);
        }
    }
}


/**
 * dim_outline() - Get the outline of a 2D shape
 * weight: Thickness of outline relative dim_linewidth(). Defaults to 1
 *
 * Creates an outline of the child 2D shapes. For example, this can convert a
 * solid circle into an open ring. This is important when creating 2D drawings.
 * OpenSCAD merges all overlapping shapes when rendering 2D objects, so if the
 * object is solid, it is impossible to have details inside the shape. By
 * converting the shape to an outline it is possible to render additional
 * details inside the shape.
 */
module dim_outline(weight=1) {
    dim_extrude() difference() {
        offset(delta=weight*dim_linewidth()/2) children();
        offset(delta=-weight*dim_linewidth()/2) children();
    }
}

/**
 * dim_circlecenter() - Draw drill center markings
 * radius: radius of circle to be marked
 * weight: Thickness of the line relative to dim_linewidth(). With default
 *         values, this will draw a 1pt thickness line.
 * size: length of crosshair lines
 */
module dim_circlecenter(radius, weight=1, size=dim_linewidth()*6)
{
    // Outside edge markers
    for (i=[0,90,180,270])
        rotate([0,0,i]) translate([radius-size/2, 0]) dim_line(size, weight);
    // Hole center crosshairs
    for (i=[0,90])
        rotate([0,0,i]) translate([-size/2, 0]) dim_line(size, weight);
}

function text_or_length(length, text, prefix="") =
    text ? text : str(prefix, length * dim_unitscale(), dim_unitsymbol());

/**
 * dim_dimension() - Draw a dimension line showing measurement between two points
 * length: length of dimension line in model units
 * text: string to use as label. If text is omitted, the value of length is
 *       converted into a string and used as a label
 * weight: Thickness of the line relative to dim_linewidth(). With default
 *         values, this will draw a 1pt thickness line.
 * loc: Position of label
 * offset: If set, offset dimension line by this value and draw extension lines
 * center: (bool) Center dimension line across the x axis if true.
 *
 * This module draws a dimensioned line with a label. By default it draws the
 * line broken with the label in the middle. Placement of the label and
 * dimension lines can be controlled with the 'loc' argument.
 */
module dim_dimension(length, text=undef, weight=1, loc=undef, offset=undef, center=false)
{
    _label = text_or_length(length, text);
    space = len(_label) * dim_fontsize();
    xoff = center ? -length/2 : 0;
    _loc = loc ? loc : (space+dim_linewidth()*10 < length ? "center" : "left");

    translate([xoff, offset ? offset : 0]) {
        if (_loc == "center") {
            dim_line(length/2-space/2, weight, left="arrow");

            translate([length/2, 0])
                dim_text(_label, halign="center", valign="center");

            translate([length/2+space/2, 0])
                dim_line(length/2-space/2, weight, right="arrow");

        } else if (_loc == "left") {
             dim_line(length, weight, left="arrow", right="arrow");

             translate([-dim_fontsize(), 0])
                 dim_text(_label, halign="right", valign="center");

        } else if (_loc == "right") {
            dim_line(length, weight, left="arrow", right="arrow");

            translate([length+dim_fontsize(), 0])
                dim_text(_label, valign="center");

        } else if (_loc == "outside") {
            translate([-length/2, 0])
                dim_line(length/2, weight, right="arrow");

            translate([length/2, 0])
                dim_text(_label, halign="center", valign="center");

            translate([length, 0])
                dim_line(length/2, weight, left="arrow");
        } else {
            echo("dimensions(): error: unrecognized value for loc:", loc);
        }
    }

    if (offset)
         for (x=[xoff,xoff+length])
            translate([x,0]) rotate([0,0,offset < 0 ? -90 : 90])
                translate([dim_linewidth()*2,0])
                    dim_line(abs(offset)+dim_fontsize()/2, weight);
}

/**
 * dim_leaderline() - Create a labelled line pointing to a circle edge
 * radius: Radius of circle/arc being pointed to
 * text: text label to place at end of leader line. If omitted, diameter is
 *       shown instead
 * angle: angle to draw arrow portion of leader line
 * dlength: length of diagonal portion of leader line
 * hlength: length of horizontal portion of leader line
 * direction: If specified, force direction of horizontal line.  Valid values
 *            are: "left" or "right"
 * do_circle: if true draw a circle around the text label. Useful for callouts.
 *
 * Creates a line that points directly at a center point from the given radius.
 * Then, a short horzizontal line is generated, followed by text.  The
 * direction of the horizontal short line defaults to the right for angles -90
 * to 90, and left otherwise, but can be forced by using the 'direction'
 * argument.
 */
module dim_leaderline(radius=0, text=undef, angle=45, dlength=dim_fontsize()*5,
                   hlength=dim_fontsize()*4, direction=undef, do_circle=false)
{
    label = text_or_length(radius*2, text, prefix="⌀");
    text_length = len(label) * dim_fontsize() * 0.6;
    space = dim_fontsize() * 0.6;
    dlen = dlength < dim_linewidth()*2 ? dim_linewidth()*2 : dlength;

    dir_left = direction ? direction == "left" :
                            (abs(angle) % 360 > 90) && (abs(angle) % 360 < 270);

    // Rotate to angle of arrow
    rotate([0, 0, angle]) {
        // Draw diagonal arrow
        if (dlength>0)
            translate([radius, 0]) dim_line(dlen, left="arrow", right="round");

        // Move out to end of arrow and rotate back to horizontal
        translate([radius + (dlength > 0 ? dlength : 0), 0]) rotate([0, 0, -angle]) {

            // Draw horizontal line
            rotate([0,0,dir_left ? 180 : 0])
                dim_line(hlength, left=(dlength <= 0) ? "arrow" : "round");

            // Draw label. Centered text is used to make do_circle test simpler.
            text_pos = hlength + space + text_length/2;
            translate([text_pos * (dir_left ? -1 : 1), 0]) {
                dim_text(label, valign="center", halign="center");

                if (do_circle)
                    dim_outline() circle(text_length/2 + space);
            }
        }
    }
}

/**
 * dim_titleblock() - Draw a tabular title block
 * lines: array of lines to draw as table borders
 * descs: array of table cell description labels
 * details: array of table contents text
 *
 * 'lines' holds the description of the lines. 'width' is the line width as a
 * multipler to dim_linewidth().
 *
 * lines     = [[startx, starty, horz/vert, length, width],
 *              [startx, starty, horz/vert, length, width]]
 *
 * 'descs' holds the descriptions of the title blocks. these are meant to sit in
 * the upper left corner. size, like width above, is a factor that
 * increases/decreases the size of the font
 *
 * descs    = [[startx, starty, horz/vert, text, size],
 *             [startx, starty, horz/vert, text, size]]
 *
 * holds the detail associated with the part being documented
 *
 * details    = [[startx, starty, horz/vert, text, size],
 *               [startx, starty, horz/vert, text, size]]
 */
module dim_titleblock(lines, descs, details)
{
    for (line = lines) translate([line[0], line[1]]) {
        if (line[2] == "vert") rotate([0, 0, -90])
            dim_line(line[3], weight=line[4], left="square", right="square");
        else if (line[2] == "horz")
            dim_line(line[3], weight=line[4], left="square", right="square");
    }

    for (line = descs)
        translate([line[0], line[1]])
            rotate([0, 0, line[2]=="vert" ? 90 : 0])
                dim_text(line[3], weight=line[4]);

    for (line = details)
        translate([line[0], line[1]])
            rotate([0, 0, line[2]=="vert" ? 90 : 0])
                dim_text(line[3], weight=line[4]);
}

module dim_pageborder(ps=dim_pagesize(), pm=dim_pagemargin())
{
    divsize = 50;
    bg = dim_fontsize();
    rx_offset = round(((ps.x-bg)/2)/divsize);
    ry_offset = round(((ps.y-bg)/2)/divsize);

    refchars = "ABCDEFGHJKLMNPQRSTUVWXYZ";

    // Page outline
    translate([pm,pm]) dim_outline(weight=2) square([ps.x-pm*2,ps.y-pm*2]);
    translate([pm-bg,pm-bg]) dim_outline(weight=1) square([ps.x-(pm-bg)*2,ps.y-(pm-bg)*2]);

    // Centering lines
    translate([ps.x/2, pm-bg]) rotate([0,0,90]) dim_line(bg*2);
    translate([ps.x/2, ps.y-(pm-bg)]) rotate([0,0,-90]) dim_line(bg*2);
    translate([pm-bg, ps.y/2]) rotate([0,0,0]) dim_line(bg*2);
    translate([ps.x-(pm-bg),ps.y/2]) rotate([0,0,180]) dim_line(bg*2);

    // Horizontal reference marks
    for (i=[divsize:divsize:ps.x/2-pm]) {
        translate([ps.x/2+i, pm-bg]) rotate([0,0,90]) dim_line(bg);
        translate([ps.x/2+i, ps.y-(pm-bg)]) rotate([0,0,-90]) dim_line(bg);
        translate([ps.x/2-i, pm-bg]) rotate([0,0,90]) dim_line(bg);
        translate([ps.x/2-i, ps.y-(pm-bg)]) rotate([0,0,-90]) dim_line(bg);
    }

    // Horizontal reference numbers
    for (i=[0:rx_offset*2-1])
        for (y=[pm-bg/2, ps.y-(pm-bg/2)])
            translate([ps.x/2-(rx_offset-0.5-i)*50, y])
                dim_text(str(i+1), weight=0.5, halign="center", valign="center");

    // Vertical reference marks
    for (i=[divsize:divsize:ps.y/2-pm]) {
        translate([pm-bg, ps.y/2+i]) rotate([0,0,0]) dim_line(bg);
        translate([ps.x-(pm-bg),ps.y/2+i]) rotate([0,0,180]) dim_line(bg);
        translate([pm-bg, ps.y/2-i]) rotate([0,0,0]) dim_line(bg);
        translate([ps.x-(pm-bg),ps.y/2-i]) rotate([0,0,180]) dim_line(bg);
    }

    // Vertical reference letters
    for (i=[0:ry_offset*2-1])
        for (x=[pm-bg/2, ps.x-(pm-bg/2)])
            translate([x, ps.y/2+(ry_offset-0.5-i)*50])
                dim_text(refchars[i], weight=0.5, halign="center", valign="center");
}

/* Scale examples to match size of dimension elements */
DIM_SAMPLE_SCALE = dim_fontsize() / 0.175;

/**
 * sample_titleblock1() - Example of how to draw a title block
 *
 * Note the use of double thickness lines around the perimeter. Any line can be
 * adjusted to be thinner or thicker.
 *
 * Note also that since lines are centered on their widths, some adjustments for
 * half-width spacing is needed to avoid a jagged look on corners.  You can see
 * that in the horizontal lines in the first section that are offset by half-width
 * of the outside line. In this case, dim_linewidth().
 */
module sample_titleblock1()
{
    fs = dim_fontsize();
    title_width = 50*fs;
    row_height = 3*fs;

    cols = [0, title_width*0.167, title_width*0.333, title_width*0.667,
            title_width*0.73, title_width*0.9];
    rows = [0, -row_height, -row_height*2, -row_height*3, -row_height*4];

    // spacing tweaks to fit into the blocks
    desc_x = 0.2*fs; // column offset for start of small text
    desc_y = -fs; // row offset for start of small text
    det_y = -2.5*fs;  // row offset for start of detail text
    desc_size = .65; // relative size of description text

    lines = [
        // horizontal lines
        [cols[0], rows[0], "horz", title_width, 2],
        [cols[0], rows[1], "horz", title_width, 1],
        [cols[2], rows[2], "horz", title_width - cols[2], 1],
        [cols[3], rows[3], "horz", title_width - cols[3], 1],
        [cols[0], rows[4], "horz", title_width, 2],

        // vertical lines
        [0, 0, "vert", row_height * 4, 2],
        [cols[1], rows[0], "vert", row_height, 1],
        [cols[2], rows[0], "vert", row_height * 4, 1],
        [cols[3], rows[0], "vert", row_height * 4, 1],
        [cols[4], rows[3], "vert", row_height, 1],
        [cols[5], rows[3], "vert", row_height, 1],
        [title_width, 0, "vert", row_height * 4, 2],
    ];

    descs = [
        [cols[0]+desc_x, rows[0]+desc_y, "horz", "Responsible dep", desc_size],
        [cols[1]+desc_x, rows[0]+desc_y, "horz", "Technical reference", desc_size],
        [cols[2]+desc_x, rows[0]+desc_y, "horz", "Creator", desc_size],
        [cols[3]+desc_x, rows[0]+desc_y, "horz", "Approval person", desc_size],
        [cols[2]+desc_x, rows[1]+desc_y, "horz", "Document type", desc_size],
        [cols[3]+desc_x, rows[1]+desc_y, "horz", "Document status", desc_size],
        [cols[2]+desc_x, rows[2]+desc_y, "horz", "Title", desc_size],
        [cols[3]+desc_x, rows[2]+desc_y, "horz", "Identification number", desc_size],
        [cols[3]+desc_x, rows[3]+desc_y, "horz", "Rev", desc_size],
        [cols[4]+desc_x, rows[3]+desc_y, "horz", "Date of issue", desc_size],
        [cols[5]+desc_x, rows[3]+desc_y, "horz", "Sheet", desc_size]
    ];

    details = [
        [cols[0]+desc_x, rows[0]+det_y, "horz", "", 1], //Responsible dep.
        [cols[1]+desc_x, rows[0]+det_y, "horz", "", 1], //Technical reference
        [cols[2]+desc_x, rows[0]+det_y, "horz", "D. Smiley ", 1], //Creator
        [cols[3]+desc_x, rows[0]+det_y, "horz", "", 1], //Approval person
        [cols[0]+desc_x*5, rows[2]+det_y, "horz", "My OpenSCAD Project", 1],
        [cols[2]+desc_x, rows[1]+det_y, "horz", "", 1], //Document type
        [cols[3]+desc_x, rows[1]+det_y, "horz", "First issue", 1], //Document status
        [cols[2]+desc_x, rows[2]+det_y, "horz", "Sample Part", 1], //Title
        [cols[3]+desc_x, rows[2]+det_y, "horz", "123", 1], //Identification number
        [cols[3]+desc_x, rows[3]+det_y, "horz", "", 1], //Rev
        [cols[4]+desc_x, rows[3]+det_y, "horz", "2013-3-31", 1], //Date of issue
        [cols[5]+desc_x, rows[3]+det_y, "horz", "1/100", 1] //Sheet
    ];

    dim_titleblock(lines, descs, details);
}

module sample_revisionblock(revisions)
{
    // revision block headings
    fs = dim_fontsize();
    title_width = 16*fs;
    row_height = 2*fs;
    desc_x = 0.2*fs;
    desc_y = -1.5*fs;
    desc_size = 1;

    cols = [0, title_width*3.5/16, title_width*11/16, title_width];
    rows = [0, -row_height, -row_height * 2];
    revision_width = cols[3];

    // draw
    lines = [
        // horizontal lines
        [cols[0], rows[0], "horz", revision_width, 1],
        [cols[0], rows[1], "horz", revision_width, 1],
        [cols[0], rows[2], "horz", revision_width, 1],

        // vertical lines
        [cols[0], rows[0], "vert", row_height * 2, 1],
        [cols[1], rows[0], "vert", row_height, 1],
        [cols[2], rows[0], "vert", row_height, 1],
        [cols[3], rows[0], "vert", row_height * 2, 1],
    ];

    descs = [
        [cols[0]+desc_x, rows[0]+desc_y, "horz", "Rev.", desc_size],
        [cols[1]+desc_x, rows[0]+desc_y, "horz", "Date", desc_size],
        [cols[2]+desc_x, rows[0]+desc_y, "horz", "Initials", desc_size],
        [cols[1]+desc_x, rows[1]+desc_y, "horz", "Revisions", desc_size],
    ];

    details = [];
    num_revisions = len(revisions);

    translate([0, row_height * 2]) {
        dim_titleblock(lines, descs, details);

        //  now for the start of actual revisions
        //  do this piecemeal -- draw the vertical first
        for (col = [0:len(cols)])
            translate([cols[col], 0]) rotate([0, 0, 90])
                dim_line(num_revisions * row_height, left="square", right="square");

        for (row = [0:len(revisions)]) {
            translate([0, row * row_height])
                dim_line(revision_width, left="square", right="square");

            for (col = [0:2])
                translate([(cols[col]+desc_x), ((row+1)*row_height+desc_y)])
                    dim_text(revisions[row][col]);
        }
    }
}

module sample_titleblock2()
{
    fs = dim_fontsize();
    row_height = 3*fs;

    title_width = 42*fs;
    cols = [0, title_width*16/42, title_width*26/42, title_width];

    rows = [0, -row_height, -row_height * 2, -row_height * 3, -row_height * 4,
            -row_height * 5, -row_height * 6, -row_height * 7];
    title_height = rows[7];

    // spacing tweaks to fit into the blocks
    desc_x = 0.25*fs; // column offset for start of small text
    desc_y = -fs; // row offset for start of small text
    det_x = 2*fs;  // col offset for start of detail text
    det_y = -2.5*fs;  // row offset for start of detail text
    desc_size = .65; // relative size of description text


    lines = [
        // horizontal lines
        [cols[0], rows[0], "horz", title_width, 1],
        [cols[2], rows[1], "horz", cols[3] - cols[2], 1],
        [cols[0], rows[2], "horz", cols[1] - cols[0], 1],
        [cols[0], rows[3], "horz", cols[3], 1],
        [cols[0], rows[4], "horz", cols[2], 1],
        [cols[0], rows[5], "horz", cols[3], 1],
        [cols[0], rows[6], "horz", cols[2], 1],
        [cols[0], rows[7], "horz", cols[2], 1],
        [cols[0], rows[7], "horz", title_width, 1],

        // vertical lines
        [cols[0], rows[0], "vert", -rows[7], 1],
        [cols[1], rows[0], "vert", -rows[7], 1],
        [cols[2], rows[0], "vert", -rows[7], 1],
        [cols[3], rows[0], "vert", -rows[7], 1],
    ];

    part_desc = ["Material", "Finish", "Weight", "Part No."];
    doc_desc = ["Drawing Number",
                "Created by",
                "Reviewed by",
                "Date of issue"
    ];

    // aspects of the part
    part_details = [
        "My Sample Part",   // title
        "Stainless Steel",  // material
        " ",                // finish
        "2.5",              // weight
        "123",              // part no
    ];

    // aspects documenting the creation of the part
    doc_details = [
        "33-2",             // Drawing No.
        "D. Smiley",        // Created by
        "G. Likely",        // Reviewed by
        "2013-3-31",        // Date
    ];

    // the organization making the part
    org_details = [
        "My logo",
        "Canny Machines",
        "Org Address, phone"
    ];

    descs = [
        // part description
        [cols[0]+desc_x, rows[2]+desc_y, "horz", part_desc[0], desc_size],
        [cols[0]+desc_x, rows[3]+desc_y, "horz", part_desc[1], desc_size],
        [cols[0]+desc_x, rows[4]+desc_y, "horz", part_desc[2], desc_size],
        [cols[0]+desc_x, rows[5]+desc_y, "horz", part_desc[3], desc_size],

        // documentation description
        [cols[1]+desc_x, rows[3]+desc_y, "horz", doc_desc[0], desc_size],
        [cols[1]+desc_x, rows[4]+desc_y, "horz", doc_desc[1], desc_size],
        [cols[1]+desc_x, rows[5]+desc_y, "horz", doc_desc[2], desc_size],
        [cols[1]+desc_x, rows[6]+desc_y, "horz", doc_desc[3], desc_size],
   ];

    details = [
        [cols[0]+desc_x, rows[0]+det_y, "horz", part_details[0], 1.5],
        [cols[0]+desc_x, rows[2]+det_y, "horz", part_details[1], 1],
        [cols[0]+desc_x, rows[3]+det_y, "horz", part_details[2], 1],
        [cols[0]+desc_x, rows[4]+det_y, "horz", part_details[3], 1],
        [cols[0]+desc_x, rows[5]+det_y, "horz", part_details[4], 1],

        [cols[1]+desc_x*2, rows[3]+det_y, "horz", doc_details[0], 1],
        [cols[1]+desc_x*2, rows[4]+det_y, "horz", doc_details[1], 1],
        [cols[1]+desc_x*2, rows[5]+det_y, "horz", doc_details[2], 1],
        [cols[1]+desc_x*2, rows[6]+det_y, "horz", doc_details[3], 1],

        // Organization Details
        [cols[1]+desc_x, rows[1]+det_y, "horz", org_details[0], 1.5],
        [cols[2]+desc_x, rows[0]+det_y, "horz", org_details[1], 1.5],
        [cols[2]+desc_x, rows[1]+det_y, "horz", org_details[2], 1],
    ];

    dim_titleblock(lines, descs, details);

    revisions = [
        ["1a", "2013-4-1", "ds"],
        ["1b", "2013-4-2", "ds"],
        ["2a", "2013-4-3", "ds"],
        ["3a", "2013-4-5", "ds"],
        ["4a", "2013-4-15", "ds"],
        ["5a", "2017-5-10", "gcl"],
    ];

    translate([0, title_height]) rotate([0, 0, 90])
    sample_revisionblock(revisions);
}

module sample_line(length, weight=1, left="flat", right="flat")
{
    label = str("weigh=",weight," left=\"", left, "\" right=\"", right, "\"");
    translate([-length/2,0]) dim_line(length, weight, left=left, right=right);
    translate([0,dim_linewidth()*weight/2])
        dim_text(label, weight=0.5, halign="center", valign="bottom");
}

module sample_lines()
{
    endings = ["flat", "square", "round", "arrow"];
    length = 4 * DIM_SAMPLE_SCALE;

    // sample lines
    translate([0,-dim_fontsize()*2])
        dim_text("Sample Lines", halign="center", valign="bottom");

    translate([0,0]) sample_line(length);
    translate([0, 1*dim_fontsize()*2])
        sample_line(length, left="arrow");
    translate([0, 2*dim_fontsize()*2])
        sample_line(length, right="arrow");
    for (i=[2:5])
        translate([0, (i+1) * dim_fontsize()*2])
            sample_line(length, weight=i);
    for (i=[0:len(endings)-1])
        translate([0, (i+7) * dim_fontsize()*2])
            sample_line(length, left=endings[i], right=endings[i], weight=6);
}

/**
 * sample_dimensions() - Sample dimesioning lines with number label
 *
 * This shows sample dimensions with numeric length labels.
 */
module sample_dimensions(with_text=false)
{
    /* shows all possibilities */
    loc = ["center", "left", "right", "outside"];
    length = 2.5 * DIM_SAMPLE_SCALE;

    translate([0, -dim_fontsize()*2])
        dim_text(with_text ? "Labelled Dimensions" : "Dimensions",
             halign="center", valign="bottom");

    // The following two lines are vertical lines that bracket the dimensions
    // left arrow
    translate([-length/2,0]) rotate([0, 0, 90])
        dim_line(length);

    // right arrow
    translate([length/2,0]) rotate([0, 0, 90])
        dim_line(length);

    //  The following runs through all the dimension types
    for (i = [0:len(loc)-1])
        translate([-length/2, 0.5 * (len(loc)-i) * DIM_SAMPLE_SCALE])
            dim_dimension(length=length, loc=loc[i], text=with_text ? loc[i] : undef);
}

/**
 * sample_units() - Sample use of different measurement units
 */
module sample_units(change_mmsize=false)
{
    height = (len(units)+1) * 0.5 * DIM_SAMPLE_SCALE;
    length = 2.5 * DIM_SAMPLE_SCALE;

    translate([0, -dim_fontsize()*2])
        dim_text(change_mmsize ? "Changing $dim_mmsize" : "Changing $dim_units",
                 halign="center", valign="bottom");

    // The following two lines are vertical lines that bracket the dimensions
    translate([-length/2, 0]) rotate([0, 0, 90]) dim_line(height);
    translate([length/2, 0]) rotate([0, 0, 90]) dim_line(height);

    // The following runs through all the dimension units
    for (i = [0:len(units)-1]) {
        $dim_units = units[i][0];
        $dim_mmsize = change_mmsize ? units[i][1] : 1;
        translate([-length/2, 0.5 * (len(units)-i) * DIM_SAMPLE_SCALE])
            dim_dimension(length);
    }
}

/**
 * sample_leaderlines() - Show sample leader lines
 */
module sample_leaderlines(radius=0.25*DIM_SAMPLE_SCALE)
{
    // Label the sample
    translate([0, -dim_fontsize()*16])
        dim_text("leader lines", halign="center", valign="bottom");

    // Simple call to dim_leaderline() shows circle diameter
    dim_leaderline(radius);

    // Angle of line can be specified
    for (angle = [90:30:210])
        dim_leaderline(radius, str(angle, "° leader line"), angle=angle);

    // A circle can be placed around the label
    for (i = [0:3]) {
        labels = ["A", "B", "C", "D"];
        angle = -(i*30 + 30);
        text_y = (i+2) * 2 * dim_fontsize();
        dlen = abs(text_y / sin(angle)) - radius;

        dim_leaderline(radius, labels[i], do_circle=true, angle=angle, dlength=dlen);
    }
}

/**
 * sample_leaderlines_lr() - Show leader lines forced to the left & right
 *
 * Note: The alen & hlen calculations are simply to keep the sample lines
 * nicely arranged. Normally you won't bother with calculating the location so
 * precisely.
 */
module sample_leaderlines_lr(radius=0.5 * DIM_SAMPLE_SCALE)
{
    // Label the sample
    translate([0, -dim_fontsize()*16])
        dim_text("leader lines left/right", halign="center", valign="bottom");

    dim_outline() circle(radius);

    // Simple call to dim_leaderline() shows circle diameter
    dim_leaderline(radius);

    // Leader lines forced to the left
    for (angle = [70:20:210]) {
        text_y = ((180-angle)/10) * dim_fontsize();
        alen = abs(text_y / sin(angle)) - radius;
        hlen = DIM_SAMPLE_SCALE*1.5 + (text_y/tan(angle));

        dim_leaderline(radius, angle=angle, dlength=alen, hlength=hlen,
                    direction="left", text=str(angle, "° left"));
    }

    // Leader lines forced to the right
    for (angle = [-110:20:25]) {
        // These calculations make the sample lines line up nicely.  Normally
        // you wouldn't bother with precisely calculating alen & hlen.
        text_y = (angle/10) * dim_fontsize();
        alen = abs(text_y / sin(angle)) - radius;
        hlen = DIM_SAMPLE_SCALE*1.5 - (text_y/tan(angle));

        dim_leaderline(radius, angle=angle, dlength=alen, hlength=hlen,
                    direction="right", text=str(angle, "° right"));
    }

}

module sample_circlecenter()
{
    radius = .25 * DIM_SAMPLE_SCALE;

    translate([0, -DIM_SAMPLE_SCALE/2-dim_fontsize()*2])
        dim_text("dim_circlecenter()", halign="center", valign="bottom");

    dim_outline() difference() {
        square(DIM_SAMPLE_SCALE, center=true);
        circle(r=radius, center=true, $fn=100);
    }
    color("Black")
        dim_circlecenter(radius);
}

// uncomment these to sample
module all_samples()
{
    // Explicitly set the dimensioning parameters
    $dim_pagename="A3";

    ps = dim_pagesize();
    bw = dim_pagemargin();

    translate(-ps/2) {
        dim_pageborder();
        translate([ps.x*3/16, ps.y*3/16]) sample_lines();

        translate([ps.x*7/16, ps.y*5/16]) sample_dimensions();
        translate([ps.x*7/16, ps.y*2/16]) sample_dimensions(true);
        translate([ps.x*11/16, ps.y*10/16]) sample_units();
        translate([ps.x*14/16, ps.y*10/16]) sample_units(true);

        translate([ps.x*12/16, ps.y*6/16]) sample_circlecenter();
        translate([ps.x*3/16, ps.y*11/16]) sample_leaderlines();
        translate([ps.x*7/16, ps.y*11/16]) sample_leaderlines_lr();

        translate([bw, ps.y-bw]) sample_titleblock1();
        translate([ps.x-bw-dim_fontsize()*42, bw+dim_fontsize()*3*7]) sample_titleblock2();
    }
}

all_samples();

/* Dimension lines for OpenSCAD.
 *
 * Copyright 2013-2016 Don Smiley
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
 *  line(length, width, left_arrow=false, right_arrow=false)
 *      Can draw a line with the options of including an arrow at either end
 *
 *  circle_center(radius, size, line_width)
 *      Draws the cross in the center of a circle.  There are defaults for the
 *      cross size and line width
 *
 *  dimensions(length, line_width, loc="center", label=undef)
 *      draws text within lines, such as <--- 3.5 --->
 *      with the use of the variable loc you can alter the placement of the text
 *      loc="center"      <--- 3.5 --->  this is the default
 *      loc="left"        3.5 <---->
 *      loc="right"       <----> 3.5
 *      loc="outside"     ---> 3.5 <---
 *
 *      Can also pass in text such as a variable name in place of a
 *      numeric dimension.
 *
 *  leader_line(angle, radius, angle_length, horz_line_length,
 *              direction=undef, line_width, text)
 *
 *      for use in pointing to the edge of a circle and showing text
 *
 *      usage of the leader line:
 *          translate to the center of the circle
 *      Typically leader lines have a bend in them.  The angle variable is used
 *      to specify the angle from which the line will point to the center of the
 *      circle.  The radius specifies the location of the arrow. The
 *      angle_length is distance that the leader line takes until meeting the
 *      horizontal line. Once the angled line meets the horizontal line, that
 *      line will either extend to the right or left.  direction and therefore
 *      be either "right" or "left".  line_width typically would be whatever
 *      constant you have selected for all your dimensioned lines. Finally, the
 *      text will be the value that you wish to show, such as R 0.500.
 *
 *
 * Created by Don Smiley
 *
 */

/* Constants related to the annotation lines
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
 *                    of a single line of text. (default: 0.175)
 *                    By default all the drawing sizes are scaled from font
 *                    size, so if you change the value of $dim_fontsize, all
 *                    the other sizes will be adjusted accordingly.
 * $dim_linewidth   - Width of lines. (default: $dim_fontsize/7)
 * $dim_extrude_flag - (bool) If true, extrude dimension lines into 3D objects.
 *
 * For example, the following parameters were used for a part 3.5 units long.
 * $dim_fontsize is set to about 5% of the object length, or 0.175 units.
 */

// configuration for font, font size, line size and whether to extrude into 3D
function dim_font() = $dim_font ? $dim_font : undef;
function dim_fontsize() = $dim_fontsize ? $dim_fontsize : 0.175;
function dim_linewidth() = $dim_linewidth ? $dim_linewidth : dim_fontsize() / 7;
function dim_extrude_flag() = $dim_extrude ? $dim_extrude : true;

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

module arrow(arr_points, arr_length)
{
    // arrow points to the left
    dim_extrude() polygon(
        points = [[0, 0],
                [arr_points, arr_points / 2],
                [arr_length, 0],
                [arr_points, -arr_points / 2]],
        paths = [[0, 1, 2, 3]], convexity = 2);
}

module line(length, left_arrow=false, right_arrow=false)
{
    /* This module draws a line that can have an arrow on either end.  Because
     * the intended use is to be viewed strictly from above, the height of the
     * line is set arbitrarily thin.
     *
     * The factors arr_length and arr_points are used to create a proportionate
     * arrow. Your sense of asthetics may lead you to choose different
     * numbers.
     */
    width = dim_linewidth();
    arr_points = width * 4;
    arr_length = arr_points * .6;
    line_length = length - arr_length * ((left_arrow ? 1 : 0) + (right_arrow ? 1 : 0));

    union() {
        translate([left_arrow ? arr_length : 0, -width / 2])
            dim_extrude() square([line_length, width], center=false);

        if (left_arrow)
            arrow(arr_points, arr_length);

        if (right_arrow) {
            translate([length, 0])
            rotate([0, 0, 180])
            arrow(arr_points, arr_length);
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
 * circle_center() - Draw drill center markings
 * radius: radius of circle to be marked
 * size: length of crosshair lines
 */
module circle_center(radius, size=dim_linewidth()*6)
{
    // Outside edge markers
    for (i=[0,90,180,270])
        rotate([0,0,i]) translate([radius-size/2, 0]) line(size);
    // Hole center crosshairs
    for (i=[0,90])
        rotate([0,0,i]) translate([-size/2, 0]) line(size);
}

function text_or_length(length, mytext, prefix="") =
    mytext ? mytext : str(prefix, length);

/**
 * dimensions() - Draw a dimension line showing measurement between two points
 * length: length of dimension line in model units
 * loc: Location of label
 * label: string to use as label. If mytext is omitted, the value of length is
 *         converted into a string and used as a label
 *
 * This module draws a dimensioned line with a label. By default it draws the
 * line broken with the label in the middle. Placement of the label and
 * dimension lines can be controlled with the 'loc' argument.
 */
module dimensions(length, loc="center", mytext=undef)
{
    _label = text_or_length(length, mytext);
    space = len(_label) * dim_fontsize();

    if (loc == "center") {
        line(length/2-space/2, left_arrow=true);

        translate([length/2, 0]) dim_extrude()
            text(_label, size=dim_fontsize(), font=dim_font(),
                 halign="center", valign="center");

        translate([length/2+space/2, 0])
            line(length/2-space/2, right_arrow=true);

    } else if (loc == "left") {
         line(length, left_arrow=true, right_arrow=true);

         translate([-dim_fontsize(), 0]) dim_extrude()
             text(_label, size=dim_fontsize(), font=dim_font(),
                  halign="right", valign="center");

    } else if (loc == "right") {
        line(length, left_arrow=true, right_arrow=true);

        translate([length+dim_fontsize(), 0]) dim_extrude()
            text(_label, size=dim_fontsize(), font=dim_font(), valign="center");

    } else if (loc == "outside") {
        translate([-length/2, 0])
            line(length/2, right_arrow=true);

        translate([length/2, 0]) dim_extrude()
            text(_label, size=dim_fontsize(), font=dim_font(),
                 halign="center", valign="center");

        translate([length, 0])
            line(length/2, left_arrow=true);
    } else {
        echo("dimensions(): error: unrecognized value for loc:", loc);
    }
}

/**
 * leader_line() - Create a labelled line pointing to a circle edge
 * radius: Radius of circle being pointed to
 * text: text label to place at end of leader line. If omitted, diameter is shown instead
 * angle: angle to draw arrow portion of leader line
 * angle_length: length of arrow line
 * horz_line_length: length of horizontal portion of leader line
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
module leader_line(radius, text=undef, angle=45, angle_length=dim_fontsize()*4,
                   horz_line_length=dim_fontsize()*4,
                   direction=undef, do_circle=false)
{
    label = text_or_length(radius*2, text, prefix="⌀");
    text_length = len(label) * dim_fontsize() * 0.6;
    space = dim_fontsize() * 0.6;
    alen = angle_length < dim_linewidth()*2 ? dim_linewidth()*2 : angle_length;

    dir_left = direction ? direction == "left" :
                            (abs(angle) % 360 > 90) && (abs(angle) % 360 < 270);

    // Rotate to angle of arrow
    rotate([0, 0, angle]) {
        // Draw angled arrow
        translate([radius, 0]) line(alen, left_arrow=true);

        // Move out to end of arrow and rotate back to horizontal
        translate([radius + alen, 0]) rotate([0, 0, -angle]) {

            // Draw horizontal line
            translate([dir_left ? -horz_line_length : 0, 0])
                line(horz_line_length);

            // Draw label. Centered text is used to make do_circle test simpler.
            text_pos = horz_line_length + space + text_length/2;
            translate([text_pos * (dir_left ? -1 : 1), 0]) {
                dim_extrude()
                    text(label, size=dim_fontsize(), font=dim_font(),
                         valign="center", halign="center");

                if (do_circle)
                    dim_outline() circle(text_length/2 + space);
            }
        }
    }
}

module titleblock(lines, descs, details) {
    /* titleblock
     *
     * This module accepts the following arrays with formats:
     *
     * holds the description of the lines. width is a factor that
     * expands the line width beyond dim_linewidth()
     *
     * lines     = [[startx, starty, horz/vert, length, width],
     *              [startx, starty, horz/vert, length, width]]
     *
     * holds the descriptions of the title blocks. these are meant to sit in
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

    for (line = lines) {
        translate([line[0]*dim_linewidth(), line[1]*dim_linewidth()])
        if (line[2] == "vert") rotate([0, 0, -90])
            line(length=line[3] * dim_linewidth(),
                 $dim_linewidth=dim_linewidth() * line[4]);
        else if (line[2] == "horz")
            line(length=(line[3] + 1) * dim_linewidth(),
                 $dim_linewidth=dim_linewidth() * line[4]);
    }

    for (line = descs)
        translate([line[0] * dim_linewidth(), line[1] * dim_linewidth()])
            rotate([0, 0, line[2]=="vert" ? 90 : 0]) dim_extrude()
                text(line[3], size=dim_fontsize()*line[4], font=dim_font());

    for (line = details)
        translate([line[0] * dim_linewidth(), line[1] * dim_linewidth()])
            rotate([0, 0, line[2]=="vert" ? 90 : 0]) dim_extrude()
                text(line[3], size=dim_fontsize()*line[4], font=dim_font());
}

/* Scale examples to match size of dimension elements */
DIM_SAMPLE_SCALE = dim_fontsize() / 0.175;

module sample_titleblock1() {
    /* sample titleblock
     *
     * Note the use of double thickness lines around the perimeter. Any line
     * can be adjusted to be thinner or thicker.
     *
     * Note also that since lines are centered on their widths, some adjustments
     * for half-width spacing is needed to avoid a jagged look on corners.
     * You can see that in the horizontal lines in the first section that are
     * offset by 1, which is the half-width of the outside line.
     */
    title_width = 300;
    row_height = 15;

    cols = [-1, 50, 114, 200, 215, 270];
    rows = [0, -row_height, -row_height * 2, -row_height * 3, -row_height * 4];

    // spacing tweaks to fit into the blocks
    desc_x = 2; // column offset for start of small text
    desc_y = -5; // row offset for start of small text
    det_y = -13;  // row offset for start of detail text
    desc_size = .65; // relative size of description text

    lines = [
        // horizontal lines
        [cols[0], rows[0], "horz", title_width, 2],
        [cols[0], rows[1], "horz", title_width, 1],
        [cols[2], rows[2], "horz", title_width - cols[2] - 1, 1],
        [cols[3], rows[3], "horz", title_width - cols[3] - 1, 1],
        [cols[0], rows[4] - 1, "horz", title_width, 2],

        // vertical lines
        [0, 0, "vert", row_height * 4, 2],
        [cols[1], rows[0], "vert", row_height, 1],
        [cols[2], rows[0], "vert", row_height * 4, 1],
        [cols[3], rows[0], "vert", row_height * 4, 1],
        [cols[4], rows[3], "vert", row_height, 1],
        [cols[5], rows[3], "vert", row_height, 1],
        [title_width - 1, 0, "vert", row_height * 4, 2],
    ];

    descs = [
        [cols[0] + desc_x, rows[0] + desc_y, "horz",
            "Responsible dep", desc_size],
        [cols[1] + desc_x, rows[0] + desc_y, "horz",
            "Technical reference", desc_size],
        [cols[2] + desc_x, rows[0] + desc_y, "horz",
            "Creator", desc_size],
        [cols[3] + desc_x, rows[0] + desc_y, "horz",
            "Approval person", desc_size],
        [cols[2] + desc_x, rows[1] + desc_y, "horz",
            "Document type", desc_size],
        [cols[3] + desc_x, rows[1] + desc_y, "horz",
            "Document status", desc_size],
        [cols[2] + desc_x, rows[2] + desc_y, "horz",
            "Title", desc_size],
        [cols[3] + desc_x, rows[2] + desc_y, "horz",
            "Identification number", desc_size],
        [cols[3] + desc_x, rows[3] + desc_y, "horz",
            "Rev", desc_size],
        [cols[4] + desc_x, rows[3] + desc_y, "horz",
            "Date of issue", desc_size],
        [cols[5] + desc_x, rows[3] + desc_y, "horz",
            "Sheet", desc_size]
    ];

    details = [
        [cols[0] + desc_x,  rows[0] + det_y, "horz",
            " ", 1], //Responsible dep.
        [cols[1] + desc_x, rows[0] + det_y, "horz",
            " ", 1], //Technical reference
        [cols[2] + desc_x, rows[0] + det_y, "horz",
            "D. Smiley ", 1], //Creator
        [cols[3] + desc_x, rows[0] + det_y, "horz",
            " ", 1], //Approval person
        [cols[0] + desc_x + 5, rows[2] + det_y, "horz",
            "My OpenSCAD Project", 1],
        [cols[2] + desc_x, rows[1] + det_y, "horz",
            " ", 1], //Document type
        [cols[3] + desc_x, rows[1] + det_y, "horz",
            "First issue", 1], //Document status
        [cols[2] + desc_x, rows[2] + det_y, "horz",
            "Sample Part", 1], //Title
        [cols[3] + desc_x, rows[2] + det_y, "horz",
            "123", 1], //Identification number
        [cols[3] + desc_x, rows[3] + det_y, "horz",
            " ", 1], //Rev
        [cols[4] + desc_x, rows[3] + det_y, "horz",
            "2013-3-31", 1], //Date of issue
        [cols[5] + desc_x, rows[3] + det_y, "horz",
            "1/100", 1] //Sheet
    ];


    titleblock(lines, descs, details);
}

module sample_revisionblock(revisions) {

    // revision block headings
    row_height = 15;
    revision_width = 120;
    desc_x = 2;
    desc_y = -10;
    desc_size = 1;

    cols = [0, 25, 80, revision_width];
    rows = [0, -row_height, -row_height * 2];

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
        [cols[0] + desc_x, rows[0] + desc_y, "horz",
            "Rev.", desc_size],
        [cols[1] + desc_x, rows[0] + desc_y, "horz",
            "Date", desc_size],
        [cols[2] + desc_x, rows[0] + desc_y, "horz",
            "Initials", desc_size],
        [cols[1] + desc_x, rows[1] + desc_y, "horz",
            "Revisions", desc_size],
    ];

    details = [];
    num_revisions = len(revisions);

    translate([0, row_height * 2 * dim_linewidth()]) {
        titleblock(lines, descs, details);

        //  now for the start of actual revisions
        //  do this piecemeal -- draw the vertical first

        for (col = [0: len(cols)]) {
            translate([cols[col] * dim_linewidth(), 0])
            rotate([0, 0, 90])
            line(num_revisions * row_height * dim_linewidth());
        }

        for (row = [0: len(revisions)]) {
            translate([0, row * row_height * dim_linewidth()])
            line(revision_width * dim_linewidth());

            for (col = [0:2]) {
                translate([(cols[col] + desc_x) * dim_linewidth(),
                    ((row + 1) * row_height + desc_y) * dim_linewidth()])
                dim_extrude() text(revisions[row][col], size=dim_fontsize(),
                                  font=dim_font());
            }
        }
    }
}

module sample_titleblock2() {

    row_height = 20;

    cols = [-.5, 115, 174, 290];
    title_width = cols[3];

    rows = [0, -row_height, -row_height * 2, -row_height * 3, -row_height * 4,
            -row_height * 5, -row_height * 6, -row_height * 7
    ];
    title_height = rows[7];

    // spacing tweaks to fit into the blocks
    desc_x = 2; // column offset for start of small text
    desc_y = -5; // row offset for start of small text
    det_x = 15;  // col offset for start of detail text
    det_y = -15;  // row offset for start of detail text
    desc_size = .65; // relative size of description text


    lines = [
        // horizontal lines
        [-.5, 0, "horz", title_width, 1],

        [cols[2], rows[1], "horz", cols[3] - cols[2] - .5, 1],
        [cols[0], rows[2], "horz", cols[1] - cols[0] - .5, 1],
        [cols[0], rows[3], "horz", cols[3] - .5, 1],
        [cols[0], rows[4], "horz", cols[2] - .5, 1],
        [cols[0], rows[5], "horz", cols[3] - .5, 1],
        [cols[0], rows[6], "horz", cols[2] - .5, 1],
        [cols[0], rows[7], "horz", cols[2] - .5, 1],

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
        [cols[0] + desc_x, rows[2] + desc_y, "horz", part_desc[0], desc_size],
        [cols[0] + desc_x, rows[3] + desc_y, "horz", part_desc[1], desc_size],
        [cols[0] + desc_x, rows[4] + desc_y, "horz", part_desc[2], desc_size],
        [cols[0] + desc_x, rows[5] + desc_y, "horz", part_desc[3], desc_size],

        // documentation description
        [cols[1] + desc_x, rows[3] + desc_y, "horz", doc_desc[0], desc_size],
        [cols[1] + desc_x, rows[4] + desc_y, "horz", doc_desc[1], desc_size],
        [cols[1] + desc_x, rows[5] + desc_y, "horz", doc_desc[2], desc_size],
        [cols[1] + desc_x, rows[6] + desc_y, "horz", doc_desc[3], desc_size],
   ];

    details = [
        [cols[0] + desc_x, rows[0] + det_y, "horz", part_details[0], 1.5],
        [cols[0] + desc_x, rows[2] + det_y, "horz", part_details[1], 1],
        [cols[0] + desc_x, rows[3] + det_y, "horz", part_details[2], 1],
        [cols[0] + desc_x, rows[4] + det_y, "horz", part_details[3], 1],
        [cols[0] + desc_x, rows[5] + det_y, "horz", part_details[4], 1],

        [cols[1] + desc_x * 2, rows[3] + det_y, "horz", doc_details[0], 1],
        [cols[1] + desc_x * 2, rows[4] + det_y, "horz", doc_details[1], 1],
        [cols[1] + desc_x * 2, rows[5] + det_y, "horz", doc_details[2], 1],
        [cols[1] + desc_x * 2, rows[6] + det_y, "horz", doc_details[3], 1],

        // Organization Details
        [cols[1] + desc_x, rows[1] + det_y, "horz", org_details[0], 1.5],
        [cols[2] + desc_x, rows[0] + det_y, "horz", org_details[1], 1.5],
        [cols[2] + desc_x, rows[1] + det_y, "horz", org_details[2], 1],

    ];

    titleblock(lines, descs, details);

    revisions = [
        ["1a", "2013-4-1", "ds"],
        ["1b", "2013-4-2", "ds"],
        ["2a", "2013-4-3", "ds"],
        ["3a", "2013-4-5", "ds"],
        ["4a", "2013-4-15", "ds"],
        ["5a", "2017-5-10", "gcl"],
    ];

    translate([0, title_height*dim_linewidth()]) rotate([0, 0, 90])
    sample_revisionblock(revisions);


}

module sample_lines()
{
    // sample lines
    line(length=2 * DIM_SAMPLE_SCALE, left_arrow=false, right_arrow=false);
    translate([0, -0.25 * DIM_SAMPLE_SCALE])
        line(length=2 * DIM_SAMPLE_SCALE, left_arrow=true, right_arrow=false);
    translate([0, -0.5 * DIM_SAMPLE_SCALE])
        line(length=2 * DIM_SAMPLE_SCALE, left_arrow=false, right_arrow=true);
    translate([0, -0.75 * DIM_SAMPLE_SCALE])
        line(length=2 * DIM_SAMPLE_SCALE, left_arrow=true, right_arrow=true);
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

    // The following two lines are vertical lines that bracket the dimensions
    // left arrow
    translate([0, -1.75 * DIM_SAMPLE_SCALE]) rotate([0, 0, 90])
        line(length);

    // right arrow
    translate([length, -1.75 * DIM_SAMPLE_SCALE]) rotate([0, 0, 90])
        line(length);

    //  The following runs through all the dimension types
    for (i = [0:len(loc)-1]) {
        translate([0, -.5 * i * DIM_SAMPLE_SCALE])
            dimensions(length=length, loc=loc[i], mytext=with_text ? loc[i] : undef);
    }
}

/**
 * sample_leaderlines() - Show sample leader lines
 */
module sample_leaderlines(radius=0.25*DIM_SAMPLE_SCALE)
{
    // Simple call to leader_line() shows circle diameter
    leader_line(radius);

    // Angle of line can be specified
    for (angle = [90:30:210])
        leader_line(radius, str(angle, "° leader line"), angle=angle);

    // A circle can be placed around the label
    for (i = [0:3]) {
        labels = ["A", "B", "C", "D"];
        angle = -(i*30 + 30);
        text_y = (i+2) * 2 * dim_fontsize();
        alen = abs(text_y / sin(angle)) - radius;

        leader_line(radius, labels[i], do_circle=true, angle=angle, angle_length=alen);
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
    dim_outline() circle(radius);

    // Simple call to leader_line() shows circle diameter
    leader_line(radius);

    // Leader lines forced to the left
    for (angle = [70:20:210]) {
        text_y = ((180-angle)/10) * dim_fontsize();
        alen = abs(text_y / sin(angle)) - radius;
        hlen = DIM_SAMPLE_SCALE*1.5 + (text_y/tan(angle));

        leader_line(radius, angle=angle, angle_length=alen, horz_line_length = hlen,
                    direction="left", text=str(angle, "° left"));
    }

    // Leader lines forced to the right
    for (angle = [-110:20:25]) {
        // These calculations make the sample lines line up nicely.  Normally
        // you wouldn't bother with precisely calculating alen & hlen.
        text_y = (angle/10) * dim_fontsize();
        alen = abs(text_y / sin(angle)) - radius;
        hlen = DIM_SAMPLE_SCALE*1.5 - (text_y/tan(angle));

        leader_line(radius, angle=angle, angle_length=alen, horz_line_length = hlen,
                    direction="right", text=str(angle, "° right"));
    }

}

module sample_circlecenter() {

    radius = .25 * DIM_SAMPLE_SCALE;
    difference() {
        cube([DIM_SAMPLE_SCALE, DIM_SAMPLE_SCALE, DIM_SAMPLE_SCALE], center=true);
        cylinder(h=1.1 * DIM_SAMPLE_SCALE, r=radius, center=true, $fn=100);
    }
    color("Black") translate([0, 0, .51 * DIM_SAMPLE_SCALE])
        circle_center(radius);
}

// uncomment these to sample
module all_samples()
{
    // Explicitly set the dimensioning parameters
    $dim_height=0.01;

    sample_lines();

    translate([-5.5 * DIM_SAMPLE_SCALE, 0]) sample_dimensions();
    translate([-11 * DIM_SAMPLE_SCALE, 0]) sample_dimensions(true);

    translate([4 * DIM_SAMPLE_SCALE, 0]) sample_circlecenter();
    translate([-2 * DIM_SAMPLE_SCALE, 3 * DIM_SAMPLE_SCALE]) sample_leaderlines();
    translate([-9 * DIM_SAMPLE_SCALE, 3 * DIM_SAMPLE_SCALE]) sample_leaderlines_lr();
    translate([3 * DIM_SAMPLE_SCALE, 4 * DIM_SAMPLE_SCALE]) sample_titleblock1();
    translate([0 * DIM_SAMPLE_SCALE, -2 * DIM_SAMPLE_SCALE]) sample_titleblock2();
}

all_samples();

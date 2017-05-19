/*
 * Example of how to create self-dimensioning modules with dimlines.scad
 *
 * Copyright 2017 Grant Likely <grant.likely@secretlab.ca>
 *
 * SPDX-License-Identifier: MIT
 *
 * This is a simple self-dimensioning module. When called without arguments,
 * widget() draws the object, but if the 'action' argument is provided, it uses
 * dimlines to draw the object outline and dimensions. When you view this file
 * in OpenSCAD, it will show an exploded view of the widget and outlines for
 * the top, front and right projections.
 */

use <../dimlines.scad>

default_size = [75,25,30];

module widget(size=default_size, action="add", flange=true)
{
    hole_offset = (size.x-size.y)/2;
    vert_hole_radius = size.y*0.3;
    horiz_hole_radius = size.z*0.3;

    if (action == "add") {
        difference() {
            union() {
                hull() {
                    translate([-hole_offset,0]) cylinder(r=size.y/2,h=size.z/2);
                    translate([hole_offset,0]) cylinder(r=size.y/2,h=size.z/2);
                }
                translate([0,0,size.z/2]) rotate([90,0,0]) {
                    cylinder(r=size.z/2, h=size.y, center=true);
                    if (flange)
                        cylinder(r=size.z*0.4, h=size.y*1.1, center=true);
                }
            }
            // Vertical mounting holes
            translate([-hole_offset,0,size.z/4])
                cylinder(r=vert_hole_radius,h=size.z,center=true);
            translate([hole_offset,0,size.z/4])
                cylinder(r=vert_hole_radius,h=size.z,center=true);

            // Horizontal hole
            translate([0,0,size.z/2]) rotate([90,0,0])
                cylinder(r=horiz_hole_radius, h=size.y*1.2, center=true);
        }
    } else if (action == "dim:top") {
        dim_outline(weight=2) projection() widget(size);
        dim_outline() projection(cut=true) translate([0,0,-size.z/2-0.01]) widget(size);
        translate([size.x/2,-size.y/2]) rotate([0,0,90]) {
            dim_dimension(size.y/2, offset=-dim_fontsize()*4);
            dim_dimension(size.y, offset=-dim_fontsize()*7);
        }

        translate([-size.x/2,-size.y/2])
            dim_dimension(size.x/2-hole_offset, offset=-dim_fontsize()*3);
        translate([hole_offset,-size.y/2])
            dim_dimension(size.x/2-hole_offset, offset=-dim_fontsize()*3);

        for (x=[hole_offset,-hole_offset]) translate([x,0]) {
            dim_circlecenter(vert_hole_radius);
            dim_leaderline(vert_hole_radius, angle=75);
        }

    } else if (action == "dim:front") rotate([90,0,0]) {
        dim_outline(weight=2) projection() rotate([-90,0,0]) widget(size);
        dim_outline() projection(cut=true) rotate([-90,0,0]) widget(size);
        dim_outline() projection(cut=true) translate([0,0,-size.y/2-0.01])
            rotate([-90,0,0]) widget(size);
        translate([-size.x/2, 0])
            dim_dimension(size.x/2, offset=-dim_fontsize()*4);
        dim_dimension(size.x, offset=-dim_fontsize()*7, center=true);
        translate([size.x/2,0]) rotate([0,0,90]) {
            dim_dimension(size.z/2, offset=-dim_fontsize()*4);
            dim_dimension(size.z, offset=-dim_fontsize()*7);
        }
        translate([0,size.z/2]) {
            dim_leaderline(horiz_hole_radius, angle=150);
            dim_leaderline(size.z*0.4, angle=135);
            dim_leaderline(size.z/2, angle=120);
            dim_circlecenter(horiz_hole_radius);
        }

    } else if (action == "dim:right") rotate([0,90,0]) {
        dim_outline(weight=2) projection() rotate([0,-90,0]) widget(size);
        dim_outline(weight=2) projection() rotate([0,-90,0])
            widget(size, flange=false);
        dim_outline() projection(cut=true) translate([0,0,-size.z/2+0.01])
            rotate([0,-90,0]) widget(size);
        translate([0, size.y/2]) rotate([0,0,90])
            dim_dimension(size.y*0.05, offset=-dim_fontsize()*4);
    }
}


widget();
color("blue") translate([0,0,default_size.z*1.5]) widget(action="dim:top");
color("green") translate([0,-default_size.y*1.5,0]) widget(action="dim:front");
color("red") translate([default_size.x,0,0]) widget(action="dim:right");

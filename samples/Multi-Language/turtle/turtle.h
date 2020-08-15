#ifndef TURTLE_H
#define TURTLE_H

/*
    turtle.h

    Simple array-based turtle graphics engine in C. Exports to BMP files.

    (header info only; see turtle.c for implementation)

    Author: Mike Lam, James Madison University, August 2015
    Modified by: Eric Smith, June 2020 (Added turtle_pixel_t)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

typedef unsigned short turtle_pixel_t;


/*
    Initialize the 2d field that the turtle moves on. This must be called
    before any of the other functions in this library.
*/
void turtle_init(turtle_pixel_t *framebuffer, int width, int height);


/*
    Reset the turtle's location, orientation, color, and pen status to the
    default values: center of the field (0,0), facing right (0 degrees), black,
    and down, respectively).
*/
void turtle_reset();


/*
    Creates a backup of the current turtle. Once you have a backup you can 
    restore from a backup using turtle_restore(); This is useful in complex
    drawing situations.
*/
void turtle_backup();


/*
    Restores the turtle from the backup. Note that the behavior is undefined
    if you have not first called turtle_backup().
 */
void turtle_restore();


/*
    Move the turtle forward, drawing a straight line if the pen is down.
*/
void turtle_forward(int pixels);


/*
    Move the turtle backward, drawing a straight line if the pen is down.
*/
void turtle_backward(int pixels);


/*
    Turn the turtle to the left by the specified number of degrees.
*/
void turtle_turn_left(double angle);


/*
    Turn the turtle to the right by the specified number of degrees.
*/
void turtle_turn_right(double angle);


/*
    Set the pen status to "up" (do not draw).
*/
void turtle_pen_up();


/*
    Set the pen status to "down" (draw).
*/
void turtle_pen_down();


/*
    Start filling. Call this before drawing a polygon to activate the
    bookkeeping required to run the filling algorithm later.
*/
void turtle_begin_fill();


/*
    End filling. CAll this after drawing a polygon to trigger the fill
    algorithm. The filled polygon may have up to 128 sides.
*/
void turtle_end_fill();


/*
    Move the turtle to the specified location, drawing a straight line if the
    pen is down. Takes integer coordinate parameters.
*/
void turtle_goto(int x, int y);


/*
    Move the turtle to the specified location, drawing a straight line if the
    pen is down. Takes real-numbered coordinate parameters, and is also used
    internally to implement forward and backward motion.
*/
void turtle_goto_real(double x, double y);


/*
    Rotate the turtle to the given heading (in degrees). 0 degrees means
    facing to the right; 90 degrees means facing straight up.
*/
void turtle_set_heading(double angle);


/*
    Set the current drawing color. Each component (red, green, and blue) may
    be any value between 0 and 255 (inclusive). Black is (0,0,0) and white is
    (255,255,255).
*/
void turtle_set_pen_color(int red, int green, int blue);


/*
    Set the current filling color. Each component (red, green, and blue) may
    be any value between 0 and 255 (inclusive). Black is (0,0,0) and white is
    (255,255,255).
*/
void turtle_set_fill_color(int red, int green, int blue);


/*
    Draw a 1-pixel dot at the current location, regardless of pen status.
*/
void turtle_dot();


/*
    Draw a 1-pixel dot at the given location using the current draw color,
    regardless of current turtle location or pen status.
*/
void turtle_draw_pixel(int x, int y);


/*
    Draw a 1-pixel dot at the given location using the current fill color,
    regardless of current turtle location or pen status.
*/
void turtle_fill_pixel(int x, int y);


/*
    Draw a straight line between the given coordinates, regardless of current
    turtle location or pen status.
*/
void turtle_draw_line(int x0, int y0, int x1, int y1);


/*
    Draw a circle at the given coordinates with the given radius, regardless of
    current turtle location or pen status.
*/
void turtle_draw_circle(int x, int y, int radius);


/*
    Fill a circle at the given coordinates with the given radius, regardless of
    current turtle location or pen status.
*/
void turtle_fill_circle(int x0, int y0, int radius);


/*
    Draw a turtle at the current pen location.
 */
void turtle_draw_turtle();


/*
    Save current field to a .bmp file.
*/
void turtle_save_bmp(const char *filename);


/*
    Enable video output. When enabled, periodic frame bitmaps will be saved
    with sequentially-ordered filenames matching the following pattern:
    "frameXXXX.bmp" (X is a digit). Frames are emitted after a regular number of
    pixels have been drawn; this number is set by the parameter to this
    function. Some experimentation may be required to find a optimal values for
    different shapes.
*/
void turtle_begin_video(int pixels_per_frame);


/*
    Emit a single video frame containing the current field image.
*/
void turtle_save_frame();


/*
    Disable video output.
*/
void turtle_end_video();


/*
    Returns the current x-coordinate.
*/
double turtle_get_x();


/*
    Returns the current x-coordinate.
*/
double turtle_get_y();


/*
    Draw an integer at the current location.
*/
void turtle_draw_int(int value);


/*
    Clean up any memory used by the turtle graphics system. Call this at the
    end of the program to ensure there are no memory leaks.
*/
void turtle_cleanup();


#endif


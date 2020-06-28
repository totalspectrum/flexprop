/*
    turtle.c

    Simple array-based turtle graphics engine in C. Exports to BMP files.

    Author: Mike Lam, James Madison University, August 2015
    Modified by Eric Smith, June 2020 to write to RGB565 pixel maps.

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

    Known issues:

        - "filled" polygons are not always entirely filled, especially when
          side angles are very acute; there is probably an incorrect floating-
          point or integer conversion somewhere

*/

#include "turtle.h"

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <math.h>


/**  DEFINITIONS  **/

#define ABS(X) ((X)>0 ? (X) : (-(X)))

#define PI 3.141592653589793

#define MAX_POLYGON_VERTICES 128

// pixel data (red, green, blue triplet)
typedef struct {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} rgbpix_t;

/**  GLOBAL TURTLE STATE  **/

typedef struct {
    double  xpos;       // current position and heading
    double  ypos;       // (uses floating-point numbers for
    double  heading;    //  increased accuracy)

    turtle_pixel_t pen_color;   // current pen color
    turtle_pixel_t fill_color;  // current fill color
    bool   pendown;     // currently drawing?
    bool   filled;      // currently filling?
} turtle_t;

turtle_t main_turtle;
turtle_t backup_turtle;

turtle_pixel_t *main_turtle_image = NULL;        // 2d pixel data field

int    main_field_width  = 0;           // size in pixels
int    main_field_height = 0;

bool   main_field_save_frames = false;  // currently saving video frames?
int    main_field_frame_count    = 0;   // current video frame counter
int    main_field_frame_interval = 10;  // pixels per frame
int    main_field_pixel_count    = 0;   // total pixels drawn by turtle since
                                        // beginning of video
int    main_turtle_poly_vertex_count = 0;       // polygon vertex count
double main_turtle_polyX[MAX_POLYGON_VERTICES]; // polygon vertex x-coords
double main_turtle_polyY[MAX_POLYGON_VERTICES]; // polygon vertex y-coords

/**  PIXEL CONVERSION FUNCTIONS **/

turtle_pixel_t turtle_rgb2pixel(int r, int g, int b)
{
    turtle_pixel_t p;

    p = (r>>3)<<11;
    p |= (g>>2)<<5;
    p |= (b>>3);
    return p;
}

void turtle_pixel2rgb(turtle_pixel_t p, rgbpix_t *RGB)
{
    int r, g, b;
    
    /* red: duplicate high 3 bits to fill in low 3 */
    r = (p>>11) & 0x1f;
    r = (r<<3) | (r>>2);

    /* green: duplicate high 2 bits to fill in low 2 */
    g = (p>>5) & 0x3f;
    g = (g<<2) | (g>>4);

    /* blue: like red */
    b = (p>>0) & 0x1f;
    b = (b<<3) | (b>>2);

    RGB->red = r;
    RGB->green = g;
    RGB->blue = b;
}

/**  TURTLE FUNCTIONS  **/

void turtle_init(turtle_pixel_t *framebuffer, int width, int height)
{
    turtle_pixel_t white;
    int x;
    white = turtle_rgb2pixel(255, 255, 255);
    //white = turtle_rgb2pixel(0, 0, 255); // blue for debug
    main_turtle_image = framebuffer;

    x = width * height;
    while (x > 0) {
        framebuffer[--x] = white;
    }

    // save field size for later
    main_field_width = width;
    main_field_height = height;

    // disable video
    main_field_save_frames = false;

    // reset turtle position and color
    turtle_reset();
}

void turtle_reset()
{
    // move turtle to middle of the field
    main_turtle.xpos = 0.0;
    main_turtle.ypos = 0.0;

    // orient to the right (0 deg)
    main_turtle.heading = 0.0;

    // default draw color is black
    main_turtle.pen_color = turtle_rgb2pixel(0, 0, 0);

    // default fill color is green
    main_turtle.fill_color = turtle_rgb2pixel(0, 255, 0);

    // default pen position is down
    main_turtle.pendown = true;

    // default fill status is off
    main_turtle.filled = false;
    main_turtle_poly_vertex_count = 0;
}

void turtle_backup() {
    backup_turtle = main_turtle;
}

void turtle_restore() {
    main_turtle = backup_turtle;
}

void turtle_forward(int pixels)
{
    // calculate (x,y) movement vector from heading
    double radians = main_turtle.heading * PI / 180.0;
    double dx = cos(radians) * pixels;
    double dy = sin(radians) * pixels;

    // delegate to another method to actually move
    turtle_goto_real(main_turtle.xpos + dx, main_turtle.ypos + dy);
}

void turtle_backward(int pixels)
{
    // opposite of "forward"
    turtle_forward(-pixels);
}

void turtle_strafe_left(int pixels) {
    turtle_turn_left(90);
    turtle_forward(pixels);
    turtle_turn_right(90);
}

void turtle_strafe_right(int pixels) {
    turtle_turn_right(90);
    turtle_forward(pixels);
    turtle_turn_left(90);
}

void turtle_turn_left(double angle)
{
    // rotate turtle heading
    main_turtle.heading += angle;

    // constrain heading to range: [0.0, 360.0)
    if (main_turtle.heading < 0.0) {
        main_turtle.heading += 360.0;
    } else if (main_turtle.heading >= 360.0) {
        main_turtle.heading -= 360.0;
    }
}

void turtle_turn_right(double angle)
{
    // opposite of "turn left"
    turtle_turn_left(-angle);
}

void turtle_pen_up()
{
    main_turtle.pendown = false;
}

void turtle_pen_down()
{
    main_turtle.pendown = true;
}

void turtle_begin_fill()
{
    main_turtle.filled = true;
    main_turtle_poly_vertex_count = 0;
}

void turtle_end_fill()
{
    // based on public-domain fill algorithm in C by Darel Rex Finley, 2007
    //   from http://alienryderflex.com/polygon_fill/

    double nodeX[MAX_POLYGON_VERTICES];     // x-coords of polygon intercepts
    int nodes;                              // size of nodeX
    int x, y, i, j;                         // current pixel and loop indices
    double temp;                            // temporary variable for sorting

    //  loop through the rows of the image
    for (y = -(main_field_height/2); y < main_field_height/2; y++) {

        //  build a list of polygon intercepts on the current line
        nodes = 0;
        j = main_turtle_poly_vertex_count-1;
        for (i = 0; i < main_turtle_poly_vertex_count; i++) {
            if ((main_turtle_polyY[i] <  (double)y &&
                 main_turtle_polyY[j] >= (double)y) ||
                (main_turtle_polyY[j] <  (double)y &&
                 main_turtle_polyY[i] >= (double)y)) {

                // intercept found; record it
                nodeX[nodes++] = (main_turtle_polyX[i] +
                        ((double)y - main_turtle_polyY[i]) /
                        (main_turtle_polyY[j] - main_turtle_polyY[i]) *
                        (main_turtle_polyX[j] - main_turtle_polyX[i]));
            }
            j = i;
            if (nodes >= MAX_POLYGON_VERTICES) {
                fprintf(stderr, "Too many intercepts in fill algorithm!\n");
                exit(EXIT_FAILURE);
            }
        }

        //  sort the nodes via simple insertion sort
        for (i = 1; i < nodes; i++) {
            temp = nodeX[i];
            for (j = i; j > 0 && temp < nodeX[j-1]; j--) {
                nodeX[j] = nodeX[j-1];
            }
            nodeX[j] = temp;
        }

        //  fill the pixels between node pairs
        for (i = 0; i < nodes; i += 2) {
            for (x = (int)floor(nodeX[i])+1; x < (int)ceil(nodeX[i+1]); x++) {
                turtle_fill_pixel(x, y);
            }
        }
    }

    main_turtle.filled = false;

    // redraw polygon (filling is imperfect and can occasionally occlude sides)
    for (i = 0; i < main_turtle_poly_vertex_count; i++) {
        int x0 = (int)round(main_turtle_polyX[i]);
        int y0 = (int)round(main_turtle_polyY[i]);
        int x1 = (int)round(main_turtle_polyX[(i+1) %
            main_turtle_poly_vertex_count]);
        int y1 = (int)round(main_turtle_polyY[(i+1) %
            main_turtle_poly_vertex_count]);
        turtle_draw_line(x0, y0, x1, y1);
    }
}

void turtle_goto(int x, int y)
{
    turtle_goto_real((double)x, (double)y);
}

void turtle_goto_real(double x, double y)
{
    // draw line if pen is down
    if (main_turtle.pendown) {
        turtle_draw_line((int)round(main_turtle.xpos),
                         (int)round(main_turtle.ypos),
                         (int)round(x),
                         (int)round(y));
    }

    // change current turtle position
    main_turtle.xpos = (double)x;
    main_turtle.ypos = (double)y;

    // track coordinates for filling
    if (main_turtle.filled && main_turtle.pendown &&
            main_turtle_poly_vertex_count < MAX_POLYGON_VERTICES) {
        main_turtle_polyX[main_turtle_poly_vertex_count] = x;
        main_turtle_polyY[main_turtle_poly_vertex_count] = y;
        main_turtle_poly_vertex_count++;
    }
}

void turtle_set_heading(double angle)
{
    main_turtle.heading = angle;
}

void turtle_set_pen_color(int red, int green, int blue)
{
    main_turtle.pen_color = turtle_rgb2pixel(red, green, blue);
}

void turtle_set_fill_color(int red, int green, int blue)
{
    main_turtle.fill_color = turtle_rgb2pixel(red, green, blue);
}

void turtle_dot()
{
    // draw a pixel at the current location, regardless of pen status
    turtle_draw_pixel((int)round(main_turtle.xpos),
                      (int)round(main_turtle.ypos));
}

static size_t num_pixels_out_of_bounds = 0;

void turtle_draw_pixel(int x, int y)
{
    if (x < (- main_field_width/2)  || x > (main_field_width/2) ||
        y < (-main_field_height/2) || y > (main_field_height/2)) {

        // only print the first 100 error messages (prevents runaway output)
        if (++num_pixels_out_of_bounds < 100) {
            fprintf(stderr, "Pixel out of bounds: (%d,%d)\n", x, y);
        }
        return;
    }

    // calculate pixel offset in image data array
    int idx = main_field_width * (-y+main_field_height/2)
                               + (x+main_field_width/2);

    // "draw" the pixel by setting the color values in the image matrix
    if (idx >= 0 && idx < main_field_width*main_field_height) {
        main_turtle_image[idx]   = main_turtle.pen_color;
    }

    // track total pixels drawn and emit video frame if a frame interval has
    // been crossed (and only if video saving is enabled, of course)
    if (main_field_save_frames &&
            main_field_pixel_count++ % main_field_frame_interval == 0) {
        turtle_save_frame();
    }
}

void turtle_fill_pixel(int x, int y)
{
    // calculate pixel offset in image data array
    int idx = main_field_width * (-y+main_field_height/2)
                               + (x+main_field_width/2);

    // check to make sure it's not out of bounds
    if (idx >= 0 && idx < main_field_width*main_field_height) {
        main_turtle_image[idx]  = main_turtle.fill_color;
    }
}

void turtle_draw_line(int x0, int y0, int x1, int y1)
{
    // uses a variant of Bresenham's line algorithm:
    //   https://en.wikipedia.org/wiki/Talk:Bresenham%27s_line_algorithm

    int absX = ABS(x1-x0);          // absolute value of coordinate distances
    int absY = ABS(y1-y0);
    int offX = x0<x1 ? 1 : -1;      // line-drawing direction offsets
    int offY = y0<y1 ? 1 : -1;
    int x = x0;                     // incremental location
    int y = y0;
    int err;

    turtle_draw_pixel(x, y);
    if (absX > absY) {

        // line is more horizontal; increment along x-axis
        err = absX / 2;
        while (x != x1) {
            err = err - absY;
            if (err < 0) {
                y   += offY;
                err += absX;
            }
            x += offX;
            turtle_draw_pixel(x,y);
        }
    } else {

        // line is more vertical; increment along y-axis
        err = absY / 2;
        while (y != y1) {
            err = err - absX;
            if (err < 0) {
                x   += offX;
                err += absY;
            }
            y += offY;
            turtle_draw_pixel(x,y);
        }
    }
}

void turtle_draw_circle(int x0, int y0, int radius)
{
    // implementation based on midpoint circle algorithm:
    //   https://en.wikipedia.org/wiki/Midpoint_circle_algorithm

    int x = radius;
    int y = 0;
    int switch_criteria = 1 - x;

    if (main_turtle.filled) {
        turtle_fill_circle(x0, y0, radius);
    }

    while (x >= y) {
        turtle_draw_pixel( x + x0,  y + y0);
        turtle_draw_pixel( y + x0,  x + y0);
        turtle_draw_pixel(-x + x0,  y + y0);
        turtle_draw_pixel(-y + x0,  x + y0);
        turtle_draw_pixel(-x + x0, -y + y0);
        turtle_draw_pixel(-y + x0, -x + y0);
        turtle_draw_pixel( x + x0, -y + y0);
        turtle_draw_pixel( y + x0, -x + y0);
        y++;
        if (switch_criteria <= 0) {
            switch_criteria += 2 * y + 1;       // no x-coordinate change
        } else {
            x--;
            switch_criteria += 2 * (y - x) + 1;
        }
    }
}

void turtle_fill_circle(int x0, int y0, int radius) {

    int rad_sq = radius * radius;

    // Naive algorithm, pretty ugly due to no antialiasing:
    for (int x = x0 - radius; x < x0 + radius; x++) {
        for (int y = y0 - radius; y < y0 + radius; y++) {
            int dx = x - x0;
            int dy = y - y0;
            int dsq = (dx * dx) + (dy * dy);
            if (dsq < rad_sq) turtle_fill_pixel(x, y);
        }
    }
}

void turtle_fill_circle_here(int radius)
{
    turtle_fill_circle(main_turtle.xpos, main_turtle.ypos, radius);
}

void turtle_draw_turtle()
{
    // We are going to make our own backup of the turtle, since turtle_backup()
    // only gives us one level of undo.
    turtle_t original_turtle = main_turtle;

    turtle_pen_up();

    // Draw the legs
    for (int i = -1; i < 2; i+=2) {
        for (int j = -1; j < 2; j+=2) {
            turtle_backup();
                turtle_forward(i * 7);
                turtle_strafe_left(j * 7);

                main_turtle.fill_color = main_turtle.pen_color;
                turtle_fill_circle_here(5);

                main_turtle.fill_color = original_turtle.fill_color;
                turtle_fill_circle_here(3);
            turtle_restore();
        }
    }

    // Draw the head
    turtle_backup();
        turtle_forward(10);
        main_turtle.fill_color = main_turtle.pen_color;
        turtle_fill_circle_here(5);

        main_turtle.fill_color = original_turtle.fill_color;
        turtle_fill_circle_here(3);
    turtle_restore();

    // Draw the body
    for (int i = 9; i >= 0; i-=4) {
        turtle_backup();
            main_turtle.fill_color = main_turtle.pen_color;
            turtle_fill_circle_here(i+2);

            main_turtle.fill_color = original_turtle.fill_color;
            turtle_fill_circle_here(i);
        turtle_restore();
    }

    // Restore the original turtle position:
    main_turtle = original_turtle;
}

void turtle_begin_video(int pixels_per_frame)
{
    main_field_save_frames = true;
    main_field_frame_count = 0;
    main_field_frame_interval = pixels_per_frame;
    main_field_pixel_count = 0;
}

void turtle_save_frame()
{
    char filename[32];
    sprintf(filename, "frame%05d.bmp", ++main_field_frame_count);
    turtle_save_bmp(filename);
}

void turtle_end_video()
{
    main_field_save_frames = false;
}

double turtle_get_x()
{
    return main_turtle.xpos;
}

double turtle_get_y()
{
    return main_turtle.ypos;
}

const int TURTLE_DIGITS[10][20] = {

    {0,1,1,0,       // 0
     1,0,0,1,
     1,0,0,1,
     1,0,0,1,
     0,1,1,0},

    {0,1,1,0,       // 1
     0,0,1,0,
     0,0,1,0,
     0,0,1,0,
     0,1,1,1},

    {1,1,1,0,       // 2
     0,0,0,1,
     0,1,1,0,
     1,0,0,0,
     1,1,1,1},

    {1,1,1,0,       // 3
     0,0,0,1,
     0,1,1,0,
     0,0,0,1,
     1,1,1,0},

    {0,1,0,1,       // 4
     0,1,0,1,
     0,1,1,1,
     0,0,0,1,
     0,0,0,1},

    {1,1,1,1,       // 5
     1,0,0,0,
     1,1,1,0,
     0,0,0,1,
     1,1,1,0},

    {0,1,1,0,       // 6
     1,0,0,0,
     1,1,1,0,
     1,0,0,1,
     0,1,1,0},

    {1,1,1,1,       // 7
     0,0,0,1,
     0,0,1,0,
     0,1,0,0,
     0,1,0,0},

    {0,1,1,0,       // 8
     1,0,0,1,
     0,1,1,0,
     1,0,0,1,
     0,1,1,0},

    {0,1,1,0,       // 9
     1,0,0,1,
     0,1,1,1,
     0,0,0,1,
     0,1,1,0},

};

void turtle_draw_int(int value)
{
    // calculate number of digits to draw
    int ndigits = 1;
    if (value > 9) {
        ndigits = (int)(ceil(log10(value)));
    }

    // draw each digit
    for (int i=ndigits-1; i>=0; i--) {
        int digit = value % 10;
        for (int y=0; y<5; y++) {
            for (int x=0; x<4; x++) {
                if (TURTLE_DIGITS[digit][y*4+x] == 1) {
                    turtle_draw_pixel(main_turtle.xpos + i*5 + x, main_turtle.ypos - y);
                }
            }
        }
        value = value / 10;
    }
}

void turtle_cleanup()
{
#ifdef OBSOLETE    
    // free image array if allocated
    if (main_turtle_image != NULL) {
        free(main_turtle_image);
        main_turtle_image = NULL;
    }
#endif    
}


// the rest of this file is based on GPL'ed code from:
// http://cpansearch.perl.org/src/DHUNT/PDL-Planet-0.12/libimage/bmp.c

struct BMPHeader
{
    char bfType[2];       // "BM"
    int bfSize;           // size of file in bytes
    int bfReserved;       // set to 0
    int bfOffBits;        // byte offset to actual bitmap data (= 54)
    int biSize;           // size of BITMAPINFOHEADER, in bytes (= 40)
    int biWidth;          // width of image, in pixels
    int biHeight;         // height of images, in pixels
    short biPlanes;       // number of planes in target device (set to 1)
    short biBitCount;     // bits per pixel (24 in this case)
    int biCompression;    // type of compression (0 if no compression)
    int biSizeImage;      // image size, in bytes (0 if no compression)
    int biXPelsPerMeter;  // resolution in pixels/meter of display device
    int biYPelsPerMeter;  // resolution in pixels/meter of display device
    int biClrUsed;        // number of colors in the color table (if 0, use
                          // maximum allowed by biBitCount)
    int biClrImportant;   // number of important colors.  If 0, all colors
                          // are important
};

void turtle_save_bmp(const char *filename)
{
    int i, j, ipos;
    int bytesPerLine;
    unsigned char *line;
    FILE *file;
    struct BMPHeader bmph;
    int width = main_field_width;
    int height = main_field_height;
    turtle_pixel_t pixel;
    rgbpix_t RGB;
    
    // the length of each line must be a multiple of 4 bytes
    bytesPerLine = (3 * (width + 1) / 4) * 4;

    strncpy(bmph.bfType, "BM", 2);
    bmph.bfOffBits = 54;
    bmph.bfSize = bmph.bfOffBits + bytesPerLine * height;
    bmph.bfReserved = 0;
    bmph.biSize = 40;
    bmph.biWidth = width;
    bmph.biHeight = height;
    bmph.biPlanes = 1;
    bmph.biBitCount = 24;
    bmph.biCompression = 0;
    bmph.biSizeImage = bytesPerLine * height;
    bmph.biXPelsPerMeter = 0;
    bmph.biYPelsPerMeter = 0;
    bmph.biClrUsed = 0;
    bmph.biClrImportant = 0;

    file = fopen (filename, "wb");
    if (file == NULL) {
        fprintf(stderr, "Could not write to file: %s\n", filename);
        exit(EXIT_FAILURE);
    }

    fwrite(&bmph.bfType, 2, 1, file);
    fwrite(&bmph.bfSize, 4, 1, file);
    fwrite(&bmph.bfReserved, 4, 1, file);
    fwrite(&bmph.bfOffBits, 4, 1, file);
    fwrite(&bmph.biSize, 4, 1, file);
    fwrite(&bmph.biWidth, 4, 1, file);
    fwrite(&bmph.biHeight, 4, 1, file);
    fwrite(&bmph.biPlanes, 2, 1, file);
    fwrite(&bmph.biBitCount, 2, 1, file);
    fwrite(&bmph.biCompression, 4, 1, file);
    fwrite(&bmph.biSizeImage, 4, 1, file);
    fwrite(&bmph.biXPelsPerMeter, 4, 1, file);
    fwrite(&bmph.biYPelsPerMeter, 4, 1, file);
    fwrite(&bmph.biClrUsed, 4, 1, file);
    fwrite(&bmph.biClrImportant, 4, 1, file);

    line = (unsigned char*)malloc(bytesPerLine);
    memset(line, 0, bytesPerLine);
    if (line == NULL) {
        fprintf(stderr, "Can't allocate memory for BMP file.\n");
        exit(EXIT_FAILURE);
    }

    for (i = height-1; i >= 0; i--) {
        for (j = 0; j < width; j++) {
            pixel = main_turtle_image[width * i + j];
            turtle_pixel2rgb(pixel, &RGB);

            line[3*j] = RGB.blue;
            line[3*j+1] = RGB.green;
            line[3*j+2] = RGB.red;
        }
        fwrite(line, bytesPerLine, 1, file);
    }

    free(line);
    fclose(file);
}

#ifdef TEST
turtle_pixel_t myfb[300*300];

int main() {
    turtle_init(myfb, 300, 300);

    turtle_forward(50);
    turtle_turn_left(90);
    turtle_forward(50);
    turtle_draw_turtle();

    turtle_save_bmp("output.bmp");

    return 0;
}
#endif

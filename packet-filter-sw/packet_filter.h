#ifndef _PACKET_FILTER_H
#define _PACKET_FILTER_H

#include <linux/ioctl.h>

#ifndef BALL_RADIUS
    #define BALL_RADIUS 16
#endif
#ifndef BALL_INIT_X
    #define BALL_INIT_X 200
#endif
#ifndef BALL_INIT_Y
    #define BALL_INIT_Y 400
#endif

typedef struct {
  unsigned char red, green, blue;
} vga_ball_color_t;

typedef struct {
  unsigned short x, y;
} vga_ball_coords_t;

typedef union {
  vga_ball_color_t background;
  vga_ball_coords_t coords;
} vga_ball_arg_t;

#define VGA_BALL_MAGIC 'q'

/* ioctls and their arguments */
#define VGA_BALL_WRITE_BACKGROUND _IOW(VGA_BALL_MAGIC, 1, vga_ball_arg_t)
#define VGA_BALL_READ_BACKGROUND  _IOR(VGA_BALL_MAGIC, 2, vga_ball_arg_t)
#define VGA_BALL_WRITE_COORDS     _IOW(VGA_BALL_MAGIC, 3, vga_ball_arg_t)
#define VGA_BALL_READ_COORDS      _IOR(VGA_BALL_MAGIC, 4, vga_ball_arg_t)

#endif // _PACKET_FILTER_H

/*
 * Userspace program that communicates with the vga_ball device driver
 * through ioctls
 *
 * Stephen A. Edwards
 * Columbia University
 */

#include <stdio.h>
#include "vga_ball.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

// 25MHz pixel output
// 1280 * 480 pixels = 614400
// 614400 pixels/frame / 25M pixels/s = 0.024576 s/frame

#define MAX_X 640
#define MAX_Y 480
#define DT    1
#define DTSCL 25000
#define MAX_T 100000000

int vga_ball_fd;

/* Read and print the background color */
void print_background_color() {
  vga_ball_arg_t vla;

  if (ioctl(vga_ball_fd, VGA_BALL_READ_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_READ_BACKGROUND) failed");
      return;
  }
  printf("%02x %02x %02x\n",
	 vla.background.red, vla.background.green, vla.background.blue);
}

/* Set the background color */
void set_background_color(const vga_ball_color_t *c)
{
  vga_ball_arg_t vla;
  vla.background = *c;
  if (ioctl(vga_ball_fd, VGA_BALL_WRITE_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_WRITE_BACKGROUND) failed");
      return;
  }
}

/* Read and print the coordinates */
void print_coords() {
  vga_ball_arg_t vla;

  if (ioctl(vga_ball_fd, VGA_BALL_READ_COORDS, &vla)) {
      perror("ioctl(VGA_BALL_READ_COORDS) failed");
      return;
  }
  printf("%03d %03d\n",
	 (unsigned int)vla.coords.x, (unsigned int)vla.coords.y);
}

/* Set the coordinates */
void set_coords(int x, int y)
{
  printf("set_coords %d and %d\n", x, y);
  vga_ball_arg_t vla;
  vla.coords.x = (unsigned short) (x + 64 - 10);
  vla.coords.y = (unsigned short) (y);
  if (ioctl(vga_ball_fd, VGA_BALL_WRITE_COORDS, &vla)) {
      perror("ioctl(VGA_BALL_WRITE_COORDS) failed");
      return;
  }
}

#ifndef BALL_INIT_VX
  #define BALL_INIT_VX 5
#endif
#ifndef BALL_INIT_VY
  #define BALL_INIT_VY 2
#endif
#ifndef BALL_GRAVITY
  #define BALL_GRAVITY 0
#endif

int main()
{
  vga_ball_arg_t vla;
  int i;
  int x, y, vx, vy;
  int t, last_time;
  static const char filename[] = "/dev/vga_ball";

  static const vga_ball_color_t colors[] = {
    { 0xff, 0x00, 0x00 }, /* Red */
    { 0x00, 0xff, 0x00 }, /* Green */
    { 0x00, 0x00, 0xff }, /* Blue */
    { 0xff, 0xff, 0x00 }, /* Yellow */
    { 0x00, 0xff, 0xff }, /* Cyan */
    { 0xff, 0x00, 0xff }, /* Magenta */
    { 0x80, 0x80, 0x80 }, /* Gray */
    { 0x4a, 0x99, 0x76 }, /* Smaragdine */
    { 0xbb, 0x85, 0xab }  /* Mauve */
  };

# define COLORS 9

  printf("VGA ball Userspace program started\n");

  if ( (vga_ball_fd = open(filename, O_RDWR)) == -1) {
    fprintf(stderr, "could not open %s\n", filename);
    return -1;
  }

  printf("initial state: ");
  print_background_color();
  i = 0;
  x = BALL_INIT_X;
  y = BALL_INIT_Y;
  vx = BALL_INIT_VX;
  vy = BALL_INIT_VY;
  t = 0;
  last_time = 0;

  /*for (i = 0 ; i < 24 ; i++) {
    set_background_color(&colors[i % COLORS ]);
    print_background_color();
    usleep(4000000);
  }*/

  // physics engine
  while (t < MAX_T) {
    // update position
    x = x + vx * DT;
    y = y + vy * DT;

    printf("t: %d, x: %d, y: %d, vx: %d, vy: %d\n", t, x, y, vx, vy);

    // update x-velocity
    if (x <= BALL_RADIUS + vx - 48) {
      // bounce off of left wall if moving left
      if (vx < 0) {
        vx = -vx >> 1;
      }
    }
    else if (x >= MAX_X - BALL_RADIUS - vx - 48) {
      // bounce off of right wall if moving right
      if (vx > 0) {
        vx = -vx << 1;
      }
    }
    else {
      // do nothing
      // vx = vx;
    }

    // update y-velocity
    if (y <= BALL_RADIUS + vy) {
      // bounce off of bottom wall if moving down
      if (vy < 0) {
        set_background_color(&colors[i % COLORS]);
        i++;
        print_background_color();
        vy = -vy;
      }
    }
    else if (y >= MAX_Y - BALL_RADIUS - vy) {
      // bounce off of top wall if moving up
      if (vy > 0) {
        vy = -vy;
      }
    }
    else {
      // apply gravity
      vy = vy + BALL_GRAVITY * DT;
    }

    // time step
    usleep(DT*DTSCL);

    // apply changes
    set_coords(x, y);

    t += DT;
  }

  printf("VGA BALL Userspace program terminating\n");
  return 0;
}

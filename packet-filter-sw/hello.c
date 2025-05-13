/*
 * Userspace program that communicates with the various device drivers
 * through ioctls
 *
 * Stephen A. Edwards
 * Columbia University
 */

#include <stdio.h>
#include "packet_filter.h"
//#include "packet_switch.h"
#include "frame_generator.h"
#include "frame_receptor.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

int packet_filter_fd;

/* Read and print the mask */
void print_ingress_mask() {
  packet_filter_arg_t vla;

  if (ioctl(packet_filter_fd, PACKET_FILTER_READ_INGRESS_PORT_MASK, &vla)) {
      perror("ioctl(PACKET_FILTER_READ_INGRESS_PORT_MASK) failed");
      return;
  }
  printf("%0x\n",
	 (unsigned int)vla.ingress_port_mask.mask);
}

/* Set the mask */
void set_ingress_mask(int mask)
{
  packet_filter_arg_t vla;
  vla.ingress_port_mask.mask = mask;
  if (ioctl(packet_filter_fd, PACKET_FILTER_WRITE_INGRESS_PORT_MASK, &vla)) {
      perror("ioctl(PACKET_FILTER_WRITE_INGRESS_PORT_MASK) failed");
      return;
  }
}

int main()
{
  packet_filter_arg_t packet_filter_vla;
  
  printf("Userspace program started\n");

  if ( (packet_filter_fd = open("/dev/packet_filter", O_RDWR)) == -1) {
    fprintf(stderr, "could not open /dev/packet_filter\n");
    return -1;
  }

  printf("initial state: ");
  print_ingress_mask();

  set_ingress_mask(0xf);
  print_ingress_mask();

  printf("Userspace program terminating\n");
  return 0;
}

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
#include "frame_generator_0.h"
#include "frame_receptor_0.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

int packet_filter_fd;
int frame_generator_0_fd;
int frame_receptor_0_fd;
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

void write_packet_0(frame_generator_arg_t input){
  frame_generator_arg_t vla = input;
  if(ioctl(frame_generator_0_fd, FRAME_WRITE_PACKET_0, &vla)) {
    perror("ioctl(FRAME_WRITE_PACKET_0) failed");
    return;
  }
}

void read_checksum_0(frame_generator_arg_t input) {
  frame_generator_arg_t vla = input;
  if(ioctl(frame_generator_0_fd, FRAME_READ_CHECKSUM_0, &vla)) {
    perror("ioctl(FRAME_READ_CHECKSUM_0) failed");
    return;
  }
  uint32_t checksum = (vla.readdata.checksum_3 << 24) |
                    (vla.readdata.checksum_2 << 16) |
                    (vla.readdata.checksum_1 << 8) |
                    (vla.readdata.checksum_0);
  printf("Checksum: 0x%08x\n", checksum);
}

void write_receptor_data_0(frame_receptor_arg_t receptorDST){
  frame_receptor_arg_t vla = receptorDST;
  if(ioctl(frame_receptor_0_fd, RECEPTOR_WRITE_0, &vla)) {
    perror("ioctl(RECEPTOR_WRITE_0) failed");
    return;
  }
}

void read_receptorChecksum_0(frame_receptor_arg_t input) {
  frame_receptor_arg_t vla = input;
  if(ioctl(frame_receptor_0_fd, RECEPTOR_READ_0, &vla)) {
    perror("ioctl(RECEPTOR_READ_0) failed");
    return;
  }
  uint8_t dstCheck = (vla.readdata.dstCheck);
  printf("dstCheck: 0x%08x\n", dstCheck);
  uint32_t checksum = (vla.readdata.checksum_3 << 24) |
                    (vla.readdata.checksum_2 << 16) |
                    (vla.readdata.checksum_1 << 8) |
                    (vla.readdata.checksum_0);
  printf("Checksum: 0x%08x\n", checksum);
}

int main()
{
  packet_filter_arg_t packet_filter_vla;
  frame_generator_arg_t input;
  input.writedata.dst_0 = 0;
  input.writedata.dst_1 = 0;
  input.writedata.dst_2 = 0;
  input.writedata.dst_3 = 0;
  input.writedata.dst_4 = 0;
  input.writedata.dst_5 = 0;

  input.writedata.src_0 = 0;
  input.writedata.src_1 = 0;
  input.writedata.src_2 = 0;
  input.writedata.src_3 = 0;
  input.writedata.src_4 = 0;
  input.writedata.src_5 = 0;

  input.writedata.length_0 = 2;
  input.writedata.length_1 = 0;
  input.writedata.type_0 = 0;
  input.writedata.type_1 = 0;

  input.writedata.frame_wait = 10;

  input.payload.data[0] = 10;
  input.payload.data[1] = 10;

  frame_receptor_arg_t receptorDST;
  receptorDST.writedata.dst_0 = 0;
  receptorDST.writedata.dst_1 = 0;
  receptorDST.writedata.dst_2 = 0;
  receptorDST.writedata.dst_3 = 0;
  receptorDST.writedata.dst_4 = 0;
  receptorDST.writedata.dst_5 = 0;
  receptorDST.writedata.frame_wait = 10;

  printf("Userspace program started\n");
  
  if ( (packet_filter_fd = open("/dev/packet_filter", O_RDWR)) == -1) {
    fprintf(stderr, "could not open /dev/packet_filter\n");
    return -1;
  }
  printf("1\n");
  if ( (frame_generator_0_fd = open("/dev/frame_generator_0", O_RDWR)) == -1) {
    fprintf(stderr, "could not open /dev/frame_generator_0\n");
    return -1;
  }
  printf("2\n");
  if ( (frame_receptor_0_fd = open("/dev/frame_receptor_0", O_RDWR)) == -1) {
    fprintf(stderr, "could not open /dev/frame_receptor_0\n");
    return -1;
  }

  printf("initial state: ");

  print_ingress_mask();
  set_ingress_mask(0xf);
  print_ingress_mask();
  write_receptor_data_0(receptorDST);
  write_packet_0(input);
  read_checksum_0(input);
  read_receptorChecksum_0(receptorDST);
  printf("Userspace program terminating\n");
  return 0;
}

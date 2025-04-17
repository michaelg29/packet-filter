#ifndef _PACKET_FILTER_H
#define _PACKET_FILTER_H

#include <linux/ioctl.h>

typedef struct {
  int mask;
} packet_filter_ingress_port_mask_t;

typedef union {
  packet_filter_ingress_port_mask_t ingress_port_mask;
} packet_filter_arg_t;

#define PACKET_FILTER_MAGIC 'q'

/* ioctls and their arguments */
#define PACKET_FILTER_WRITE_INGRESS_PORT_MASK _IOW(PACKET_FILTER_MAGIC, 1, packet_filter_arg_t)
#define PACKET_FILTER_READ_INGRESS_PORT_MASK _IOR(PACKET_FILTER_MAGIC, 1, packet_filter_arg_t)

#endif // _PACKET_FILTER_H

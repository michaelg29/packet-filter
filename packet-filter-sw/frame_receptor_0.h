#ifndef _FRAME_RECEPTOR_0_H
#define _FRAME_RECEPTOR_0_H

#include <linux/ioctl.h>
//#include <stdint.h>
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

typedef struct {
    uint8_t dst_0;
    uint8_t dst_1;
    uint8_t dst_2;
    uint8_t dst_3;
    uint8_t dst_4;
    uint8_t dst_5;
    uint8_t frame_wait;
} receptor_data_info_t;

typedef struct {
    uint8_t dstCheck;
    uint8_t checksum_0;
    uint8_t checksum_1;
    uint8_t checksum_2;
    uint8_t checksum_3;
} receptor_data_t;

typedef union {
    receptor_data_info_t writedata;
    receptor_data_t readdata;
} frame_receptor_arg_t;

#define FRAME_RECEPTOR_MAGIC 'x'

#define RECEPTOR_WRITE_0 _IOW(FRAME_RECEPTOR_MAGIC, 1, frame_receptor_arg_t)
#define RECEPTOR_READ_0  _IOR(FRAME_RECEPTOR_MAGIC, 2, frame_receptor_arg_t)

#endif
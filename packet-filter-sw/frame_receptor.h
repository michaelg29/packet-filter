#ifndef _FRAME_RECEPTOR_H
#define _FRAME_RECEPTOR_H

#include <linux/ioctl.h>
#include <stdint.h>

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
    receptor_data_info_t writedata;
} frame_receptor_write_t;

typedef struct {
    uint8_t dstCheck;
    uint8_t checksum_0;
    uint8_t checksum_1;
    uint8_t checksum_2;
    uint8_t checksum_3;
} receptor_data_t;

typedef struct {
    receptor_data_t readdata;
} frame_receptor_read_t;

#define FRAME_GENERATOR_MAGIC 'q'

#define PACKET_WRITE _IOW(FRAME_GENERATOR_MAGIC, 1, frame_receptor_write_t)
#define REG_READ     _IOR(FRAME_GENERATOR_MAGIC, 2, frame_receptor_read_t)
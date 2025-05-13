#ifndef _FRAME_GENERATOR_0_H
#define _FRAME_GENERATOR_0_H

#include <linux/ioctl.h>
#include <stdint.h>

typedef struct {
    uint8_t dst_0;
    uint8_t dst_1;
    uint8_t dst_2;
    uint8_t dst_3;
    uint8_t dst_4;
    uint8_t dst_5;
    uint8_t src_0;
    uint8_t src_1;
    uint8_t src_2;
    uint8_t src_3;
    uint8_t src_4;
    uint8_t src_5;
    uint8_t length_0;
    uint8_t length_1;
    uint8_t type_0;
    uint8_t type_2;
    uint8_t frame_wait;
} packet_data_info_t;

typedef struct {
    uint8_t data[100];
} packet_payload_t;

typedef union {
    packet_data_info_t writedata;
    packet_payload_t payload;
    frame_generator_read_t readdata;
} frame_generator_arg_t;

typedef struct {
    uint8_t checksum_0;
    uint8_t checksum_1;
    uint8_t checksum_2;
    uint8_t checksum_3;
} frame_generator_read_t;



#define FRAME_GENERATOR_MAGIC 'q'

#define FRAME_WRITE_PACKET_0  _IOW(FRAME_GENERATOR_MAGIC, 1, frame_generator_arg_t)
#define FRAME_READ_CHECKSUM_0 _IOR(FRAME_GENERATOR_MAGIC, 2, frame_generator_arg_t)

#ifndef _PACKET_FILTER_H
#define _PACKET_FILTER_H

#include <iostream>

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

#define HEADER_BYTES 14 // 6 + 6 + 2

// frame scanning signals
typedef struct {
  bool scan_frame;
  bool scan_dst_mac;
  bool scan_src_mac;
  bool scan_type;
  bool scan_payload;
} frame_status_t;
typedef union {
  frame_status_t s;
  bool a[5];
} frame_status_u;

// ethernet frame
typedef struct {
  // metadata
  uint16_t dst_mac[3];
  uint16_t src_mac[3];
  uint16_t ethertype;

  // sending parameters
  uint32_t preamble_bytes;
  uint32_t payload_length;
  uint32_t almost_full_wait;
  uint32_t drop_wait;
  uint32_t cursor;
  uint32_t last_cursor;
  bool done;

  // sideband signals
  bool valid;
  bool last;
  frame_status_u status;
  bool almost_full;
  bool drop;

  // statistics
  uint32_t packets_transferred;
  uint32_t frames_transferred;
} eth_frame_t;

void init_statistics_collection(eth_frame_t *frame) {
  frame->packets_transferred = 0;
  frame->frames_transferred = 0;
}

void init_frame(eth_frame_t *frame, uint32_t dest, uint32_t preamble_packets, uint32_t payload_length, bool init_almost_full, uint32_t almost_full_wait, uint32_t drop_wait) {

  frame->dst_mac[0] = 0;
  frame->dst_mac[1] = (uint16_t)(dest >> 16);
  frame->dst_mac[2] = (uint16_t)dest;
  frame->src_mac[0] = 0;
  frame->src_mac[1] = 0;
  frame->src_mac[2] = 0;
  frame->ethertype = 0;

  frame->preamble_bytes = preamble_packets << 1;
  frame->payload_length = payload_length & 0xfffffffe; // make payload_length even
  frame->almost_full_wait = almost_full_wait;
  frame->drop_wait = drop_wait;
  frame->cursor = 0;
  frame->last_cursor = (frame->preamble_bytes + 2) + 14 + frame->payload_length;
  frame->done = false;

  frame->valid = false;
  frame->last = false;
  frame->status.s.scan_frame = false;
  frame->status.s.scan_dst_mac = false;
  frame->status.s.scan_src_mac = false;
  frame->status.s.scan_type = false;
  frame->status.s.scan_payload = false;
  frame->almost_full = init_almost_full;
  frame->drop = false;
}

uint16_t get_tdata(eth_frame_t *frame) {
  uint32_t cursor = frame->cursor;
  if (cursor < frame->preamble_bytes) {
    return 0xAAAA;
  }
  else if (cursor == frame->preamble_bytes) {
    return 0xAAAB;
  }
  else {
    cursor -= frame->preamble_bytes + 2;

    if (cursor < 6) {
      return frame->dst_mac[cursor >> 1];
    }
    else if (cursor < 12) {
      return frame->src_mac[(cursor - 6) >> 1];
    }
    else if (cursor < 14) {
      return frame->ethertype;
    }
    else if (cursor < 14 + frame->payload_length) {
      return cursor - 14;
    }
    else {
      return 0xAAAA;
    }
  }
}

void update_frame(eth_frame_t *frame, bool ready) {
  uint32_t cursor = frame->cursor;

  // set status flags
  if (cursor < frame->preamble_bytes) {
    frame->status.s.scan_frame = false;
    frame->status.s.scan_dst_mac = false;
    frame->status.s.scan_src_mac = false;
    frame->status.s.scan_type = false;
    frame->status.s.scan_payload = false;
  }
  else if (cursor == frame->preamble_bytes) {
    frame->status.s.scan_frame = true;
    frame->status.s.scan_dst_mac = false;
    frame->status.s.scan_src_mac = false;
    frame->status.s.scan_type = false;
    frame->status.s.scan_payload = false;
  }
  else {
    cursor -= frame->preamble_bytes + 2;

    if (cursor < 6) {
      frame->status.s.scan_frame = true;
      frame->status.s.scan_dst_mac = true;
      frame->status.s.scan_src_mac = false;
      frame->status.s.scan_type = false;
      frame->status.s.scan_payload = false;
    }
    else if (cursor < 12) {
      frame->status.s.scan_frame = true;
      frame->status.s.scan_dst_mac = false;
      frame->status.s.scan_src_mac = true;
      frame->status.s.scan_type = false;
      frame->status.s.scan_payload = false;
    }
    else if (cursor < 14) {
      frame->status.s.scan_frame = true;
      frame->status.s.scan_dst_mac = false;
      frame->status.s.scan_src_mac = false;
      frame->status.s.scan_type = true;
      frame->status.s.scan_payload = false;
    }
    else if (cursor < 14 + frame->payload_length) {
      frame->status.s.scan_frame = true;
      frame->status.s.scan_dst_mac = false;
      frame->status.s.scan_src_mac = false;
      frame->status.s.scan_type = false;
      frame->status.s.scan_payload = true;
    }
    else {
      frame->status.s.scan_frame = false;
      frame->status.s.scan_dst_mac = false;
      frame->status.s.scan_src_mac = false;
      frame->status.s.scan_type = false;
      frame->status.s.scan_payload = false;
    }
  }

  // advance cursor
  if (frame->valid && ready) {
    frame->cursor += 2; // 16-bit=2-byte packets
    ++frame->packets_transferred;

    if (frame->last) {
      ++frame->frames_transferred;
      frame->done = true;
    }
  }

  // assert sideband flags
  if (frame->cursor < frame->last_cursor) {
    frame->valid = true;
  }
  else {
    frame->valid = false;
  }
  if (frame->cursor + 2 == frame->last_cursor) {
    frame->last = true;
  }
  else {
    frame->last = false;
  }

  // assert drop and almost full flags
  frame->drop = frame->drop_wait > 0 && cursor == frame->drop_wait;
  frame->almost_full = frame->almost_full || (frame->almost_full_wait > 0 && cursor >= frame->almost_full_wait);
}

void report(eth_frame_t *frame, uint32_t cycles, uint32_t period_ns) {
  std::cout << "Bytes transferred: " << (frame->packets_transferred << 1) << std::endl;
  std::cout << "Packets transferred: " << frame->packets_transferred << std::endl;
  std::cout << "Frames transferred: " << frame->frames_transferred << std::endl;
  std::cout << "Total cycles: " << cycles << std::endl;
  std::cout << "Total time: " << cycles * period_ns << "ns" << std::endl;
  std::cout << "Throughput: " << (
    (float)(frame->packets_transferred << 1) // bytes
    / (float)(cycles * period_ns)            // per ns
    * 1000000000.0                           // ns per s
  ) << "B/s" << std::endl;
}

#endif // _PACKET_FILTER_H_

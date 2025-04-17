
`ifndef _PACKET_FILTER_SVH
`define _PACKET_FILTER_SVH

// Frame status broadcast in input filter
typedef struct {
    logic scan_frame;
    logic scan_dst_mac;
    logic scan_src_mac;
    logic scan_type;
    logic scan_payload;
} frame_status;

`endif // _PACKET_FILTER_SVH_

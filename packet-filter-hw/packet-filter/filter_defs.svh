
`ifndef _FILTER_DEFS_SVH
`define _FILTER_DEFS_SVH

// Frame status broadcast in input filter
typedef struct {
    logic scan_frame;
    logic scan_dst_mac;
    logic scan_src_mac;
    logic scan_type;
    logic scan_payload;
} frame_status;

// Downstream packet interface (always ready)
typedef struct {
    logic [15:0] tdata;
    logic        tvalid;
} packet_source_t;

// Dest data interface
typedef struct {
    logic [1:0] tdata;
    logic       tvalid;
    logic       tuser;
} dest_source_t;

// Drop indication interface
typedef struct {
    logic       tvalid;
    logic       tuser;
} drop_source_t;

`endif // _FILTER_DEFS_SVH

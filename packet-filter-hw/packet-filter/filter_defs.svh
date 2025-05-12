
`ifndef _FILTER_DEFS_SVH
`define _FILTER_DEFS_SVH

/* Integration testing setup. */

`ifndef INTG_TESTING_1
    `ifdef TOP_TESTING
        `define INTG_TESTING_1
    `endif
`endif

/* verilator lint_off UNPACKED */

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

/* verilator lint_on UNPACKED */

`endif // _FILTER_DEFS_SVH

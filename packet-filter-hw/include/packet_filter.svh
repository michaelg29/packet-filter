
`ifndef _PACKET_FILTER_SVH_
`define _PACKET_FILTER_SVH_

/**
 * Stubbing
 */

`define STUBBING_PASSTHROUGH 0 // only register interface
`define STUBBING_FUNCTIONAL  1 // full functionality

/**
 * AXIS interfaces
 */

`define AXIS_DWIDTH 16
`define AXIS_DEST_WIDTH 2

`define NUM_INGRESS_PORTS 4
`define NUM_EGRESS_PORTS 4

// AXIS data source
typedef struct packed{
    logic [`AXIS_DWIDTH-1:0] tdata;
    logic                    tvalid;
    logic                    tlast;
} axis_source_t;

// AXIS data source with destination field
typedef struct packed{
    logic [`AXIS_DWIDTH-1:0]     tdata;
    logic                        tvalid;
    logic                        tlast;
    logic [`AXIS_DEST_WIDTH-1:0] tdest;
} axis_d_source_t;

// AXIS data sink
typedef struct packed{
    logic tready;
} axis_sink_t;
typedef axis_sink_t axis_d_sink_t;

`endif // _PACKET_FILTER_SVH_

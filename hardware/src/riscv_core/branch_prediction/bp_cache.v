/*
A cache module for storing branch prediction data.

Inputs: 2 asynchronous read ports and 1 synchronous write port.
Outputs: data and cache hit (for each read port)
*/

module bp_cache #(
    parameter AWIDTH=32,  // Address bit width
    parameter DWIDTH=32,  // Data bit width
    parameter LINES=128   // Number of cache lines
) (
    input clk,
    input reset,

    // IO for 1st read port
    input [AWIDTH-1:0] ra0,
    output [DWIDTH-1:0] dout0,
    output hit0,

    // IO for 2nd read port
    input [AWIDTH-1:0] ra1,
    output [DWIDTH-1:0] dout1,
    output hit1,

    // IO for write port
    input [AWIDTH-1:0] wa,
    input [DWIDTH-1:0] din,
    input we

);
    reg[DWIDTH-1:0] dout0_reg, dout1_reg;
    reg hit0_reg, hit1_reg;

    assign dout0 = dout0_reg;
    assign dout1 = dout1_reg;
    assign hit0 = hit0_reg;
    assign hit1 = hit1_reg;

    //Given N lines, we need log2(N) bits to address each line
    // Not bit addressable so Tag/Index/Offset from 61C --> Tag/Index
    localparam INDEX_WIDTH = $clog2(LINES);
    localparam TAG_WIDTH = AWIDTH - INDEX_WIDTH;

    reg [TAG_WIDTH-1:0] tags [LINES-1:0];
    reg [DWIDTH-1:0] data [LINES-1:0];
    reg validations [LINES-1:0];

    // TODO: Double Check the calculation for indices and tags
    // 128 lines --> 7 index bits, 25 tag bits 
    // index bits to address a given line
    // tag bits to detect collisions when we have multiple lines with the same index
    // one dimensional array, so no need for offset

    wire [INDEX_WIDTH-1:0] indexr0 = ra0[INDEX_WIDTH-1:0];
    wire [INDEX_WIDTH-1:0] indexr1 = ra1[INDEX_WIDTH-1:0];
    wire [INDEX_WIDTH-1:0] indexw = wa[INDEX_WIDTH-1:0];

    wire [TAG_WIDTH-1:0] tagr0 = ra0[AWIDTH-1:INDEX_WIDTH];
    wire [TAG_WIDTH-1:0] tagr1 = ra1[AWIDTH-1:INDEX_WIDTH];
    wire [TAG_WIDTH-1:0] tagw = wa[AWIDTH-1:INDEX_WIDTH];

    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < LINES; i = i + 1) begin
                //We can flush by just invalidating all lines
                validations[i] <= 0;
            end
        end else begin
            if (we) begin
                validations[indexw] <= 1'b1;
                tags[indexw] <= tagw;
                data[indexw] <= din;
            end
        end
    end

    always @(*) begin
        // read port 0
        dout0_reg = 0;
        hit0_reg = 0;
        if (validations[indexr0] && tags[indexr0] == tagr0) begin
            dout0_reg = data[indexr0];
            hit0_reg = 1;
        end
    end

    always @(*) begin
        // read port 1
        dout1_reg = 0;
        hit1_reg = 0;
        if (validations[indexr1] && tags[indexr1] == tagr1) begin
            dout1_reg = data[indexr1];
            hit1_reg = 1;
        end
    end
endmodule

`timescale 1ns/1ps

module cache_tb();

    localparam AWIDTH = 32;
    localparam DWIDTH = 32;
    localparam LINES = 128;

    reg clk;
    reg reset;
    reg [AWIDTH-1:0] ra0, ra1, wa;
    reg [DWIDTH-1:0] din;
    reg we;
    wire [DWIDTH-1:0] dout0, dout1;
    wire hit0, hit1;

    bp_cache #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .LINES(LINES)
    ) uut (
        .clk(clk),
        .reset(reset),
        .ra0(ra0),
        .dout0(dout0),
        .hit0(hit0),
        .ra1(ra1),
        .dout1(dout1),
        .hit1(hit1),
        .wa(wa),
        .din(din),
        .we(we)
    );
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        ra0 = 0;
        ra1 = 0;
        wa = 0;
        din = 0;
        we = 0;

        // Apply reset
        #10 reset = 0;

        // Write some data to the cache
        #10 wa = 32'h00000010; din = 32'hDEADBEEF; we = 1;
        #10 wa = 32'h00000020; din = 32'hCAFEBABE; we = 1;
        #10 wa = 32'h00000030; din = 32'h12345678; we = 1;
        #10 we = 0;

        // Read data from the cache (expect hits)
        #10 ra0 = 32'h00000010; ra1 = 32'h00000020;
        #10 ra0 = 32'h00000030; ra1 = 32'h00000010;

        // Read data from the cache (expect misses)
        #10 ra0 = 32'h00000040; ra1 = 32'h00000050;

        // Successive hits
        #10 ra0 = 32'h00000010; ra1 = 32'h00000020;
        #10 ra0 = 32'h00000010; ra1 = 32'h00000020;

        // Successive misses
        #10 ra0 = 32'h00000060; ra1 = 32'h00000070;
        #10 ra0 = 32'h00000080; ra1 = 32'h00000090;

        // Finish simulation
        #10 $finish;
    end

    // Clock generation
    always #5 clk = ~clk;
endmodule
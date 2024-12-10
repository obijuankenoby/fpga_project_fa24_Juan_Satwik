module edge_detector #(
    parameter WIDTH = 1
)(
    input clk,
    input [WIDTH-1:0] signal_in,
    output [WIDTH-1:0] edge_detect_pulse
);
    // TODO: Implement a multi-bit edge detector that detects a rising edge of 'signal_in[x]'
    // and outputs a one-cycle pulse 'edge_detect_pulse[x]' starting at the next clock edge

    reg [1:0] do_stuff, edge_reg;
    always @(posedge clk) begin
        edge_reg <= signal_in & ~do_stuff;  // if do_stuff is 0, and signal_in is 1, we know that there was a rising edge
    
        do_stuff <= signal_in; 
    end

    assign edge_detect_pulse = edge_reg;
endmodule

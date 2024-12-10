module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input reset,

    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    output serial_out
);

    localparam SYMBOL_EDGE_TIME = CLOCK_FREQ / BAUD_RATE;
    localparam CLOCK_COUNTER_WIDTH = $clog2(SYMBOL_EDGE_TIME);


    reg [9:0] tx_shift;           
    reg [3:0] bit_counter;
    reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter; 
    reg tx_running;
    reg shift_ready;
    reg data_in_flag;
    reg transmission;


    wire symbol_edge = (clock_counter == (SYMBOL_EDGE_TIME - 1));

    assign tx_running = (bit_counter != 0);

    assign data_in_ready = !tx_running;

    assign shift_ready = symbol_edge && tx_running;

    assign data_in_flag = data_in_valid && data_in_ready;

    // transmission <= 0;

    //--|Counters|----------------------------------------------------------------
    // Clock counter for baud rate generation
    always @ (posedge clk) begin
        clock_counter <= (reset || symbol_edge || !tx_running) ? 0 : clock_counter + 1;
    end

    // Bit counter to track the start, data, and stop bits
    always @ (posedge clk) begin
        if (reset) begin
            bit_counter <= 0;
            tx_shift <= 10'b1111111111; //TX idles high
        end else if (data_in_flag) begin
            bit_counter <= 10;
            tx_shift <= {1'b1, data_in, 1'b0}; //sandwich data between start and stop bits
            transmission <= 1;
        end else if (shift_ready) begin
            bit_counter <= bit_counter - 1;
            tx_shift <= {1'b1, tx_shift[9:1]}; //shift bits
        end
    end


    assign serial_out = tx_running ? tx_shift[0] : 1'b1; // Default to idle state when not running

    datainlow: assert property (@(posedge clk) !tx_running |-> (serial_out && data_in_ready));
    property transmitting;
    @(posedge clk) disable iff(reset)

    $rose(transmission) |-> !data_in_ready[*SYMBOL_EDGE_TIME * 10];
    endproperty
endmodule